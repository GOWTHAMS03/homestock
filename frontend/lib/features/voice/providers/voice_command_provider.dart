import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/sync/sync_providers.dart' show connectivityMonitorProvider;
import '../../home_switcher/home_controller.dart';
import '../../inventory/inventory_controller.dart';
import '../../shopping/shopping_controller.dart';
import '../controllers/voice_controller.dart' show offlineModelManagerProvider;
import '../data/speech/offline_model_manager.dart';
import '../models/voice_models.dart';
import '../services/voice_ai_service.dart';

enum VoiceAiStatus {
  idle,
  listening,
  processing,
  confirming,
  executing,
  success,
  error,
}

class VoiceAiState {
  final VoiceAiStatus status;
  final String transcript;
  final VoiceCommandResult? commandResult;
  final ExecuteCommandResponse? executionResponse;
  final String? selectedOptionId;
  final Duration recordingDuration;
  final double amplitude;
  final String? errorMessage;
  final String detectedLanguage;
  final bool isFollowUpExpected;
  final bool isModelInstalled;
  final bool isModelDownloading;
  final double modelDownloadProgress;

  const VoiceAiState({
    this.status = VoiceAiStatus.idle,
    this.transcript = '',
    this.commandResult,
    this.executionResponse,
    this.selectedOptionId,
    this.recordingDuration = Duration.zero,
    this.amplitude = 0.0,
    this.errorMessage,
    this.detectedLanguage = 'AUTO',
    this.isFollowUpExpected = false,
    this.isModelInstalled = false,
    this.isModelDownloading = false,
    this.modelDownloadProgress = 0.0,
  });

  bool get isRecording => status == VoiceAiStatus.listening;
  bool get isProcessing => status == VoiceAiStatus.processing || status == VoiceAiStatus.executing;
  bool get hasResult => commandResult != null;

  VoiceAiState copyWith({
    VoiceAiStatus? status,
    String? transcript,
    VoiceCommandResult? commandResult,
    ExecuteCommandResponse? executionResponse,
    String? selectedOptionId,
    Duration? recordingDuration,
    double? amplitude,
    String? errorMessage,
    String? detectedLanguage,
    bool? isFollowUpExpected,
    bool? isModelInstalled,
    bool? isModelDownloading,
    double? modelDownloadProgress,
  }) {
    return VoiceAiState(
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      commandResult: commandResult ?? this.commandResult,
      executionResponse: executionResponse ?? this.executionResponse,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      amplitude: amplitude ?? this.amplitude,
      errorMessage: errorMessage ?? this.errorMessage,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      isFollowUpExpected: isFollowUpExpected ?? this.isFollowUpExpected,
      isModelInstalled: isModelInstalled ?? this.isModelInstalled,
      isModelDownloading: isModelDownloading ?? this.isModelDownloading,
      modelDownloadProgress: modelDownloadProgress ?? this.modelDownloadProgress,
    );
  }
}

final voiceAiControllerProvider =
    StateNotifierProvider<VoiceAiController, VoiceAiState>((ref) {
  final aiService = ref.watch(voiceAiServiceProvider);

  return VoiceAiController(
    ref: ref,
    aiService: aiService,
  );
});

class VoiceAiController extends StateNotifier<VoiceAiState> {
  final Ref _ref;
  final VoiceAiService _aiService;
  final AudioRecorder _audioRecorder = AudioRecorder();

  Timer? _durationTimer;
  Timer? _amplitudeTimer;
  StreamSubscription<ModelInfo>? _modelStatusSub;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;

  VoiceAiController({
    required Ref ref,
    required VoiceAiService aiService,
    String? homeId,
  })  : _ref = ref,
        _aiService = aiService,
        super(const VoiceAiState()) {
    _initModelStatus();
  }

  void _initModelStatus() {
    final modelManager = _ref.read(offlineModelManagerProvider);
    state = state.copyWith(
      isModelInstalled: modelManager.isModelReady,
      isModelDownloading: modelManager.currentModel.status == ModelStatus.downloading,
      modelDownloadProgress: modelManager.currentModel.downloadProgress,
    );
    _modelStatusSub = modelManager.statusStream.listen((info) {
      if (mounted) {
        state = state.copyWith(
          isModelInstalled: info.status == ModelStatus.installed || info.status == ModelStatus.ready,
          isModelDownloading: info.status == ModelStatus.downloading,
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

  void downloadModel([WhisperModelVariant? variant]) {
    final modelManager = _ref.read(offlineModelManagerProvider);
    state = state.copyWith(
      isModelDownloading: true,
      modelDownloadProgress: 0.01,
      status: VoiceAiStatus.idle,
      errorMessage: null,
    );
    modelManager.downloadModel(variant);
  }

  String? get _homeId {
    final homeState = _ref.read(homeControllerProvider);
    final id = homeState.activeHome?.id ?? homeState.homes.firstOrNull?.id;
    if (id != null && id.isNotEmpty && id != 'default_home') return id;
    final shoppingListHomeId = _ref.read(shoppingControllerProvider).list?.homeId;
    if (shoppingListHomeId != null && shoppingListHomeId.isNotEmpty && shoppingListHomeId != 'default_home') {
      return shoppingListHomeId;
    }
    return null;
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    _modelStatusSub?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> startListening() async {
    // 1. Immediately reset state synchronously to listening so any prior response card is cleared instantly!
    state = state.copyWith(
      status: VoiceAiStatus.listening,
      transcript: '',
      commandResult: null,
      executionResponse: null,
      recordingDuration: Duration.zero,
      amplitude: 0.0,
      errorMessage: null,
    );

    if (_homeId == null) {
      state = state.copyWith(
        status: VoiceAiStatus.error,
        errorMessage: 'Please select a home to use voice commands.',
      );
      return;
    }

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        state = state.copyWith(
          status: VoiceAiStatus.error,
          errorMessage: 'Microphone permission is required for voice commands.',
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      _currentRecordingPath =
          '${tempDir.path}/voice_ai_${DateTime.now().millisecondsSinceEpoch}.wav';
      _recordingStartTime = DateTime.now();

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          bitRate: 256000,
        ),
        path: _currentRecordingPath!,
      );

      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        state = state.copyWith(
          recordingDuration: Duration(seconds: timer.tick),
        );
        if (timer.tick >= 30) {
          stopListeningAndProcess();
        }
      });

      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
        try {
          final amp = await _audioRecorder.getAmplitude();
          final normalized = ((amp.current + 50.0) / 50.0).clamp(0.0, 1.0);
          state = state.copyWith(amplitude: normalized);
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('Failed to start audio recording: $e');
      state = state.copyWith(
        status: VoiceAiStatus.error,
        errorMessage: 'Could not access microphone: $e',
      );
    }
  }

  Future<void> stopListeningAndProcess() async {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();

    if (!state.isRecording) return;

    final durationMs = _recordingStartTime != null
        ? DateTime.now().difference(_recordingStartTime!).inMilliseconds
        : 1000;

    if (durationMs < 450) {
      debugPrint('Voice recording too short ($durationMs ms), cancelling to prevent empty audio');
      try {
        await _audioRecorder.stop();
      } catch (_) {}
      state = state.copyWith(
        status: VoiceAiStatus.idle,
        errorMessage: 'Too short. Tap the mic and speak your command naturally.',
      );
      return;
    }

    state = state.copyWith(
      status: VoiceAiStatus.processing,
      transcript: '',
      commandResult: null,
      executionResponse: null,
      amplitude: 0.0,
    );

    try {
      final path = await _audioRecorder.stop() ?? _currentRecordingPath;
      if (path == null || !File(path).existsSync()) {
        state = state.copyWith(
          status: VoiceAiStatus.error,
          errorMessage: 'Recording failed. Audio was not captured.',
        );
        return;
      }

      final homeId = _homeId;
      if (homeId == null) {
        state = state.copyWith(
          status: VoiceAiStatus.error,
          errorMessage: 'Home context missing.',
        );
        return;
      }

      VoiceCommandResult? result;

      // 1. Voice recognition is strictly online-only
      final isOnline = _ref.read(connectivityMonitorProvider).isOnline;
      if (!isOnline) {
        state = state.copyWith(
          status: VoiceAiStatus.error,
          errorMessage: 'Voice recognition is available only in online mode. Please connect to the internet to speak with Homie.',
        );
        return;
      }

      // 2. Process via Gemini Flash-Lite multimodal pipeline
      try {
        final aiRes = await _aiService.processAudioCommand(
          audioFilePath: path,
          homeId: homeId,
        );
        final t = aiRes.transcript.trim().toLowerCase();
        if (t.isNotEmpty &&
            !t.contains('add 2 litre cooking oil') &&
            aiRes.intent != VoiceIntentType.unknown) {
          result = aiRes;
        }
      } catch (e) {
        debugPrint('Gemini Voice AI endpoint error: $e');
      }

      if (result == null) {
        state = state.copyWith(
          status: VoiceAiStatus.error,
          errorMessage: 'Could not understand your voice command. Please tap mic and speak again.',
        );
        return;
      }

      _handleCommandResult(result);
    } catch (e) {
      debugPrint('Voice processing error: $e');
      state = state.copyWith(
        status: VoiceAiStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', ''),
      );
    }
  }

  /// Process text command directly
  Future<void> processText(String text) async {
    final homeId = _homeId;
    if (homeId == null) return;

    state = state.copyWith(
      status: VoiceAiStatus.processing,
      transcript: text,
      commandResult: null,
      executionResponse: null,
      errorMessage: null,
    );

    try {
      final result = await _aiService.processTextCommand(
        transcript: text,
        homeId: homeId,
      );
      _handleCommandResult(result);
    } catch (e) {
      state = state.copyWith(
        status: VoiceAiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Send follow-up answer in multi-turn conversation
  Future<void> sendFollowUp(String text) async {
    final homeId = _homeId;
    if (homeId == null) return;

    state = state.copyWith(status: VoiceAiStatus.processing);

    try {
      final result = await _aiService.processFollowUp(
        transcript: text,
        homeId: homeId,
      );
      _handleCommandResult(result);
    } catch (e) {
      state = state.copyWith(
        status: VoiceAiStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void _handleCommandResult(VoiceCommandResult result) {
    if (result.intent == VoiceIntentType.unknown) {
      state = state.copyWith(
        status: VoiceAiStatus.error,
        transcript: result.transcript,
        commandResult: result,
        detectedLanguage: result.detectedLanguage,
        errorMessage: result.message.isNotEmpty
            ? result.message
            : "I couldn't understand that. Please try saying: '2 kilo rice shopping list la add pannu'",
      );
      return;
    }

    final canAuto = _aiService.canAutoExecute(result);

    state = state.copyWith(
      transcript: result.transcript,
      commandResult: result,
      detectedLanguage: result.detectedLanguage,
      selectedOptionId: result.disambiguationOptions.isNotEmpty
          ? result.disambiguationOptions.first.id
          : null,
      isFollowUpExpected: result.needsQuantity || result.needsProduct,
    );

    if (canAuto) {
      // Auto-execute high confidence commands immediately
      executeCommand();
    } else {
      // Needs confirmation, disambiguation or quantity clarification
      state = state.copyWith(status: VoiceAiStatus.confirming);
    }
  }

  /// Execute command
  Future<void> executeCommand({String? selectedOptionId}) async {
    final homeId = _homeId;
    final cmd = state.commandResult;
    if (homeId == null || cmd == null) return;

    state = state.copyWith(
      status: VoiceAiStatus.executing,
      selectedOptionId: selectedOptionId ?? state.selectedOptionId,
    );

    // 1. Direct local-first execution for shopping operations (connect Homie directly to the shopping list!)
    if (cmd.intent == VoiceIntentType.addShoppingItem) {
      try {
        final targetName = (selectedOptionId != null && selectedOptionId.isNotEmpty)
            ? selectedOptionId
            : (cmd.entities?.itemName != null && cmd.entities!.itemName!.trim().isNotEmpty
                ? cmd.entities!.itemName!.trim()
                : (cmd.transcript.trim().isNotEmpty ? cmd.transcript.trim() : 'Shopping Item'));

        final addQty = (cmd.entities?.quantity != null && cmd.entities!.quantity! > 0)
            ? cmd.entities!.quantity!
            : 1.0;
        final unit = (cmd.entities?.unit != null && cmd.entities!.unit!.isNotEmpty)
            ? cmd.entities!.unit!
            : 'pcs';

        final success = await _ref.read(shoppingControllerProvider.notifier).addItem(
              itemName: targetName,
              quantity: addQty.toDouble(),
              unit: unit,
              inventoryItemId: cmd.entities?.matchedInventoryItemId,
              categoryName: cmd.entities?.category,
            );

        final qtyStr = '${addQty.toStringAsFixed(addQty.truncateToDouble() == addQty ? 0 : 1)} $unit';
        final successMsg = success
            ? 'Added $qtyStr $targetName to shopping list!'
            : 'Could not add $targetName to shopping list.';

        state = state.copyWith(
          status: success ? VoiceAiStatus.success : VoiceAiStatus.error,
          executionResponse: ExecuteCommandResponse(
            success: success,
            intent: VoiceIntentType.addShoppingItem,
            message: successMsg,
            navigation: const {'route': '/shopping'},
          ),
          errorMessage: success ? null : successMsg,
        );

        if (success) {
          _refreshDomains(cmd.intent);
        }
        return;
      } catch (e) {
        debugPrint('Local-first addShoppingItem error: $e');
        // fall through to server execution if local-first had an error
      }
    }

    if (cmd.intent == VoiceIntentType.removeShoppingItem) {
      try {
        final targetName = (cmd.entities?.itemName ?? cmd.transcript).toLowerCase().trim();
        final currentList = _ref.read(shoppingControllerProvider).list;
        final matchingItem = currentList?.items.cast<dynamic>().firstWhere(
          (it) => it.itemName.toString().toLowerCase().trim() == targetName ||
                  (cmd.entities?.matchedInventoryItemId != null && it.inventoryItemId == cmd.entities?.matchedInventoryItemId),
          orElse: () => null,
        );
        if (matchingItem != null) {
          await _ref.read(shoppingControllerProvider.notifier).deleteItem(matchingItem.id.toString());
          final successMsg = 'Removed ${matchingItem.itemName} from shopping list.';
          state = state.copyWith(
            status: VoiceAiStatus.success,
            executionResponse: ExecuteCommandResponse(
              success: true,
              intent: VoiceIntentType.removeShoppingItem,
              message: successMsg,
              navigation: const {'route': '/shopping'},
            ),
            errorMessage: null,
          );
          _refreshDomains(cmd.intent);
          return;
        }
      } catch (e) {
        debugPrint('Local-first removeShoppingItem error: $e');
      }
    }

    if (cmd.intent == VoiceIntentType.clearShoppingList) {
      try {
        await _ref.read(shoppingControllerProvider.notifier).clearCompleted();
        state = state.copyWith(
          status: VoiceAiStatus.success,
          executionResponse: const ExecuteCommandResponse(
            success: true,
            intent: VoiceIntentType.clearShoppingList,
            message: 'Cleared completed items from shopping list.',
            navigation: {'route': '/shopping'},
          ),
          errorMessage: null,
        );
        _refreshDomains(cmd.intent);
        return;
      } catch (e) {
        debugPrint('Local-first clearShoppingList error: $e');
      }
    }

    if (cmd.intent == VoiceIntentType.searchInventory) {
      final query = (cmd.entities?.itemName != null && cmd.entities!.itemName!.trim().isNotEmpty)
          ? cmd.entities!.itemName!.trim()
          : cmd.transcript.trim();
      try {
        _ref.read(inventoryControllerProvider.notifier).setSearchQuery(query);
      } catch (_) {}
      state = state.copyWith(
        status: VoiceAiStatus.success,
        executionResponse: ExecuteCommandResponse(
          success: true,
          intent: VoiceIntentType.searchInventory,
          message: 'Searching inventory for "$query"',
          navigation: {'route': '/inventory', 'query': query},
        ),
        errorMessage: null,
      );
      return;
    }

    if (cmd.intent == VoiceIntentType.searchProduct) {
      final query = (cmd.entities?.itemName != null && cmd.entities!.itemName!.trim().isNotEmpty)
          ? cmd.entities!.itemName!.trim()
          : cmd.transcript.trim();
      state = state.copyWith(
        status: VoiceAiStatus.success,
        executionResponse: ExecuteCommandResponse(
          success: true,
          intent: VoiceIntentType.searchProduct,
          message: 'Searching deals for "$query"',
          navigation: {'route': '/deals', 'query': query},
        ),
        errorMessage: null,
      );
      return;
    }

    // 2. Server execution fallback for all other intents
    try {
      final response = await _aiService.executeCommand(
        homeId: homeId,
        commandResult: cmd,
        confirmed: true,
        selectedOptionId: selectedOptionId ?? state.selectedOptionId,
      );

      state = state.copyWith(
        status: response.success ? VoiceAiStatus.success : VoiceAiStatus.error,
        executionResponse: response,
        errorMessage: response.success ? null : response.message,
      );

      if (response.success) {
        _refreshDomains(cmd.intent);
      }
    } catch (e) {
      state = state.copyWith(
        status: VoiceAiStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', ''),
      );
    }
  }

  void _refreshDomains(VoiceIntentType intent) {
    try {
      _ref.read(shoppingControllerProvider.notifier).loadShoppingList(forceRemote: true);
      _ref.read(inventoryControllerProvider.notifier).loadData();
    } catch (_) {}
  }

  void cancel() {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    if (state.isRecording) {
      _audioRecorder.stop();
    }
    state = const VoiceAiState();
  }

  void reset() {
    state = const VoiceAiState();
  }
}

