import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../auth/auth_controller.dart';
import '../../home_switcher/home_controller.dart';
import '../../inventory/inventory_controller.dart';
import '../../shopping/shopping_controller.dart';
import '../../../core/sync/sync_providers.dart' show connectivityMonitorProvider;
import '../data/speech/hybrid_speech_engine.dart';
import '../data/speech/offline_model_manager.dart';
import '../data/speech/offline_speech_engine.dart';
import '../data/speech/online_speech_engine.dart';
import '../data/speech/speech_engine.dart';
import '../data/voice_repository.dart';
import '../domain/command_executor.dart';
import '../domain/voice_command_service.dart';
import '../models/voice_models.dart';

final voiceRepositoryProvider = Provider<VoiceRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return VoiceRepository(apiClient: client);
});

final onlineSpeechEngineProvider = Provider<OnlineSpeechEngine>((ref) {
  final repo = ref.watch(voiceRepositoryProvider);
  return OnlineSpeechEngine(voiceRepo: repo);
});

final offlineModelManagerProvider = Provider<OfflineModelManager>((ref) {
  final manager = OfflineModelManager();
  // Check model status on creation
  manager.isModelInstalled();
  ref.onDispose(() => manager.dispose());
  return manager;
});

final modelInfoProvider = StreamProvider<ModelInfo>((ref) async* {
  final manager = ref.watch(offlineModelManagerProvider);
  yield manager.currentModel;
  yield* manager.statusStream;
});

final offlineSpeechEngineProvider = Provider<OfflineSpeechEngine>((ref) {
  final modelManager = ref.watch(offlineModelManagerProvider);
  return OfflineSpeechEngine(modelManager: modelManager);
});

final hybridSpeechEngineProvider = Provider<HybridSpeechEngine>((ref) {
  final online = ref.watch(onlineSpeechEngineProvider);
  final offline = ref.watch(offlineSpeechEngineProvider);
  final connectivity = ref.watch(connectivityMonitorProvider);
  return HybridSpeechEngine(
    onlineEngine: online,
    offlineEngine: offline,
    connectivity: connectivity,
  );
});

final commandExecutorProvider = Provider<CommandExecutor>((ref) {
  final shoppingRepo = ref.watch(shoppingRepositoryProvider);
  final inventoryRepo = ref.watch(inventoryRepositoryProvider);
  return CommandExecutor(
    shoppingRepo: shoppingRepo,
    inventoryRepo: inventoryRepo,
  );
});

final voiceCommandServiceProvider = Provider<VoiceCommandService>((ref) {
  final speech = ref.watch(hybridSpeechEngineProvider);
  final executor = ref.watch(commandExecutorProvider);
  final invRepo = ref.watch(inventoryRepositoryProvider);
  final shopRepo = ref.watch(shoppingRepositoryProvider);
  return VoiceCommandService(
    speechEngine: speech,
    executor: executor,
    inventoryRepo: invRepo,
    shoppingRepo: shopRepo,
  );
});

enum VoiceStatus {
  idle,
  listening,
  processing,
  parsed,
  executing,
  success,
  error,
}

class VoiceState {
  final VoiceStatus status;
  final String transcript;
  final NormalizedVoiceCommand? normalizedCommand;
  final VoiceCommandResult? commandResult;
  final CommandExecutionResult? executionResult;
  final ExecuteCommandResponse? executionResponse;
  final String? selectedOptionId;
  final Duration recordingDuration;
  final double amplitude;
  final String? errorMessage;
  final String languageHint; // 'auto', 'ta', 'en'
  final SpeechEngineMode engineMode;
  final bool isOffline;
  final bool isModelInstalled;
  final double modelDownloadProgress;

  const VoiceState({
    this.status = VoiceStatus.idle,
    this.transcript = '',
    this.normalizedCommand,
    this.commandResult,
    this.executionResult,
    this.executionResponse,
    this.selectedOptionId,
    this.recordingDuration = Duration.zero,
    this.amplitude = 0.0,
    this.errorMessage,
    this.languageHint = 'auto',
    this.engineMode = SpeechEngineMode.auto,
    this.isOffline = false,
    this.isModelInstalled = false,
    this.modelDownloadProgress = 0.0,
  });

  bool get isRecording => status == VoiceStatus.listening;
  bool get isBusy => status == VoiceStatus.processing || status == VoiceStatus.executing;
  bool get hasParsedCommand => status == VoiceStatus.parsed && commandResult != null;

  VoiceState copyWith({
    VoiceStatus? status,
    String? transcript,
    NormalizedVoiceCommand? normalizedCommand,
    VoiceCommandResult? commandResult,
    CommandExecutionResult? executionResult,
    ExecuteCommandResponse? executionResponse,
    String? selectedOptionId,
    Duration? recordingDuration,
    double? amplitude,
    String? errorMessage,
    String? languageHint,
    SpeechEngineMode? engineMode,
    bool? isOffline,
    bool? isModelInstalled,
    double? modelDownloadProgress,
    bool clearError = false,
  }) {
    return VoiceState(
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      normalizedCommand: normalizedCommand ?? this.normalizedCommand,
      commandResult: commandResult ?? this.commandResult,
      executionResult: executionResult ?? this.executionResult,
      executionResponse: executionResponse ?? this.executionResponse,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      amplitude: amplitude ?? this.amplitude,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      languageHint: languageHint ?? this.languageHint,
      engineMode: engineMode ?? this.engineMode,
      isOffline: isOffline ?? this.isOffline,
      isModelInstalled: isModelInstalled ?? this.isModelInstalled,
      modelDownloadProgress: modelDownloadProgress ?? this.modelDownloadProgress,
    );
  }
}

final voiceControllerProvider = StateNotifierProvider<VoiceController, VoiceState>((ref) {
  final service = ref.watch(voiceCommandServiceProvider);
  final homeState = ref.watch(homeControllerProvider);
  final hybridEngine = ref.watch(hybridSpeechEngineProvider);
  return VoiceController(ref, service, hybridEngine, homeState.activeHome?.id);
});

class VoiceController extends StateNotifier<VoiceState> {
  final Ref _ref;
  final VoiceCommandService _voiceService;
  final HybridSpeechEngine _hybridSpeechEngine;
  final String? _homeId;

  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _durationTimer;
  Timer? _amplitudeTimer;
  StreamSubscription<ModelInfo>? _modelStatusSub;
  String? _currentRecordingPath;

  VoiceController(
    this._ref,
    this._voiceService,
    this._hybridSpeechEngine,
    this._homeId,
  ) : super(const VoiceState()) {
    _initModelStatus();
  }

  void _initModelStatus() {
    final modelManager = _ref.read(offlineModelManagerProvider);
    state = state.copyWith(
      isModelInstalled: modelManager.isModelReady,
    );
    _modelStatusSub = modelManager.statusStream.listen((info) {
      if (mounted) {
        state = state.copyWith(
          isModelInstalled: info.status == ModelStatus.installed || info.status == ModelStatus.ready,
          modelDownloadProgress: info.downloadProgress,
        );
      }
    });
    modelManager.isModelInstalled().then((installed) {
      if (mounted) {
        state = state.copyWith(isModelInstalled: installed);
      }
    });
  }

  void setLanguageHint(String hint) {
    state = state.copyWith(languageHint: hint);
  }

  void setEngineMode(SpeechEngineMode mode) {
    _hybridSpeechEngine.mode = mode;
    state = state.copyWith(engineMode: mode);
  }

  /// Start voice recording using device microphone.
  Future<bool> startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        state = state.copyWith(
          status: VoiceStatus.error,
          errorMessage: 'Microphone permission is required for voice commands.',
        );
        return false;
      }

      // Pre-flight check: If offlineOnly and model is not installed
      final modelManager = _ref.read(offlineModelManagerProvider);
      final isInstalled = await modelManager.isModelInstalled();
      state = state.copyWith(isModelInstalled: isInstalled);

      if (!isInstalled && state.engineMode == SpeechEngineMode.offlineOnly) {
        state = state.copyWith(
          status: VoiceStatus.error,
          errorMessage: 'Offline voice model is not installed. Please download it in Voice Settings.',
        );
        return false;
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/homestock_voice_${DateTime.now().millisecondsSinceEpoch}.wav';
      _currentRecordingPath = filePath;

      // Record as WAV (16kHz mono PCM) — required format for whisper.cpp
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 256000,
        ),
        path: filePath,
      );

      state = state.copyWith(
        status: VoiceStatus.listening,
        recordingDuration: Duration.zero,
        amplitude: 0.0,
        clearError: true,
      );

      // Start duration ticker
      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.isRecording) {
          final nextSec = state.recordingDuration.inSeconds + 1;
          state = state.copyWith(recordingDuration: Duration(seconds: nextSec));
          if (nextSec >= 60) {
            stopRecordingAndProcess();
          }
        } else {
          timer.cancel();
        }
      });

      // Amplitude polling for pulse visualizer
      _amplitudeTimer?.cancel();
      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
        if (state.isRecording) {
          try {
            final amp = await _audioRecorder.getAmplitude();
            final currentDb = amp.current.clamp(-50.0, 0.0);
            final normalized = (currentDb + 50.0) / 50.0;
            state = state.copyWith(amplitude: normalized);
          } catch (_) {}
        }
      });

      return true;
    } catch (e) {
      debugPrint('Voice recording start error: $e');
      state = state.copyWith(
        status: VoiceStatus.error,
        errorMessage: 'Unable to start microphone recording: $e',
      );
      return false;
    }
  }

  /// Stops recording, transcribes via Hybrid ASR, parses deterministically,
  /// and auto-executes high-confidence actions without blocking the user!
  Future<void> stopRecordingAndProcess() async {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();

    if (!state.isRecording) return;

    state = state.copyWith(status: VoiceStatus.processing, amplitude: 0.0);

    try {
      final path = await _audioRecorder.stop() ?? _currentRecordingPath;
      if (path == null || !File(path).existsSync()) {
        state = state.copyWith(
          status: VoiceStatus.error,
          errorMessage: 'Recording failed. Audio file was not created.',
        );
        return;
      }

      final homeId = _homeId;
      if (homeId == null) {
        state = state.copyWith(
          status: VoiceStatus.error,
          errorMessage: 'Please select a home to use voice commands.',
        );
        _cleanUpAudioFile(path);
        return;
      }

      final langHint = state.languageHint == 'auto' ? null : state.languageHint;

      // 1. Transcribe via Hybrid ASR (with privacy deletion)
      final transcript = await _voiceService.transcribeAudio(
        path,
        languageHint: langHint,
      );

      final transcriptText = transcript.cleanText.isNotEmpty ? transcript.cleanText : transcript.rawText;
      if (transcriptText.trim().isEmpty) {
        state = state.copyWith(
          status: VoiceStatus.error,
          errorMessage: "Sorry, I couldn't hear that. Please speak again.",
        );
        return;
      }

      // 2. Process command
      await processVoiceCommand(transcriptText, isOffline: transcript.isOffline);
    } catch (e) {
      debugPrint('Voice processing error: $e');
      state = state.copyWith(
        status: VoiceStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', ''),
      );
    }
  }

  /// Central entry point for processing a text voice transcript
  Future<void> processVoiceCommand(String text, {bool isOffline = false}) async {
    final homeId = _homeId;
    if (homeId == null) {
      state = state.copyWith(
        status: VoiceStatus.error,
        errorMessage: 'Please select a home to use voice commands.',
      );
      return;
    }

    state = state.copyWith(
      status: VoiceStatus.processing,
      transcript: text.trim(),
      isOffline: isOffline,
    );

    try {
      // 1. Parse via deterministic NLP with household context
      final command = await _voiceService.parseTranscript(
        rawText: text.trim(),
        homeId: homeId,
        isOffline: isOffline,
      );

      // 2. Bridge to legacy VoiceCommandResult for UI widgets compatibility
      final legacyResult = VoiceCommandResult(
        transcript: text.trim(),
        intent: command.intent,
        confidence: command.confidence,
        entities: VoiceEntities(
          itemName: command.productName,
          quantity: command.quantity,
          unit: command.unit,
          brand: command.brand,
          price: command.price,
          category: command.category,
        ),
        requiresConfirmation: command.requiresConfirmation,
        message: command.confirmationMessage ?? 'Add ${command.quantity ?? 1} ${command.unit ?? ''} ${command.productName}?',
        disambiguationOptions: command.disambiguationOptions,
      );

      state = state.copyWith(
        transcript: text.trim(),
        normalizedCommand: command,
        commandResult: legacyResult,
        selectedOptionId: command.disambiguationOptions.isNotEmpty
            ? command.disambiguationOptions.first.id
            : null,
      );

      // 3. Validation and Auto-Execution Decision
      final validation = _voiceService.validateCommand(command);

      if (!validation.isValid) {
        state = state.copyWith(
          status: VoiceStatus.error,
          errorMessage: validation.promptMessage,
        );
        return;
      }

      if (validation.canAutoExecute) {
        // High confidence: Execute immediately! No extra taps or chat screens!
        await confirmAndExecute();
      } else {
        // Needs confirmation or disambiguation choice from user
        state = state.copyWith(status: VoiceStatus.parsed);
      }
    } catch (e) {
      debugPrint('Voice parsing/execution error: $e');
      state = state.copyWith(
        status: VoiceStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', ''),
      );
    }
  }

  /// Executes the parsed voice command locally via Drift DB and sync queue
  Future<bool> confirmAndExecute() async {
    final cmd = state.normalizedCommand;
    final homeId = _homeId;
    if (cmd == null || homeId == null) return false;

    state = state.copyWith(status: VoiceStatus.executing);

    try {
      final execResult = await _voiceService.executeCommand(
        command: cmd,
        homeId: homeId,
        selectedOptionId: state.selectedOptionId,
      );

      final legacyResponse = ExecuteCommandResponse(
        success: execResult.success,
        intent: execResult.intent,
        message: execResult.message,
        navigation: execResult.navigationRoute != null
            ? {'route': execResult.navigationRoute}
            : null,
      );

      state = state.copyWith(
        status: execResult.success ? VoiceStatus.success : VoiceStatus.error,
        executionResult: execResult,
        executionResponse: legacyResponse,
        errorMessage: execResult.success ? null : execResult.message,
      );

      if (execResult.success) {
        _refreshDomains(cmd.intent);
      }

      return execResult.success;
    } catch (e) {
      state = state.copyWith(
        status: VoiceStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void selectOption(String optionId) {
    state = state.copyWith(selectedOptionId: optionId);
  }

  void parseTextCommand(String text) {
    processVoiceCommand(text);
  }

  void _refreshDomains(VoiceIntentType intent) {
    switch (intent) {
      case VoiceIntentType.addShoppingItem:
      case VoiceIntentType.removeShoppingItem:
      case VoiceIntentType.completeShoppingItem:
      case VoiceIntentType.updateShoppingQuantity:
      case VoiceIntentType.clearShoppingList:
        _ref.read(shoppingControllerProvider.notifier).loadShoppingList();
        break;
      case VoiceIntentType.stockIn:
      case VoiceIntentType.stockOut:
      case VoiceIntentType.updateStock:
      case VoiceIntentType.addInventoryItem:
      case VoiceIntentType.updateInventoryItem:
        _ref.read(inventoryControllerProvider.notifier).loadData();
        _ref.read(shoppingControllerProvider.notifier).loadShoppingList();
        break;
      default:
        break;
    }
  }

  Future<void> cancelRecording() async {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();

    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }
    } catch (_) {}

    if (_currentRecordingPath != null) {
      _cleanUpAudioFile(_currentRecordingPath!);
      _currentRecordingPath = null;
    }

    reset();
  }

  void reset() {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    state = VoiceState(
      engineMode: state.engineMode,
      languageHint: state.languageHint,
      isModelInstalled: state.isModelInstalled,
    );
  }

  void _cleanUpAudioFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _modelStatusSub?.cancel();
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }
}
