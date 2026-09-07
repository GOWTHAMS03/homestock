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
import '../data/voice_repository.dart';
import '../models/voice_models.dart';

final voiceRepositoryProvider = Provider<VoiceRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return VoiceRepository(apiClient: client);
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
  final VoiceCommandResult? commandResult;
  final ExecuteCommandResponse? executionResponse;
  final String? selectedOptionId;
  final Duration recordingDuration;
  final double amplitude; // current decibel / normalized amplitude
  final String? errorMessage;
  final String languageHint; // 'auto', 'ta', 'en'

  const VoiceState({
    this.status = VoiceStatus.idle,
    this.transcript = '',
    this.commandResult,
    this.executionResponse,
    this.selectedOptionId,
    this.recordingDuration = Duration.zero,
    this.amplitude = 0.0,
    this.errorMessage,
    this.languageHint = 'auto',
  });

  bool get isRecording => status == VoiceStatus.listening;
  bool get isBusy => status == VoiceStatus.processing || status == VoiceStatus.executing;
  bool get hasParsedCommand => status == VoiceStatus.parsed && commandResult != null;

  VoiceState copyWith({
    VoiceStatus? status,
    String? transcript,
    VoiceCommandResult? commandResult,
    ExecuteCommandResponse? executionResponse,
    String? selectedOptionId,
    Duration? recordingDuration,
    double? amplitude,
    String? errorMessage,
    String? languageHint,
    bool clearError = false,
  }) {
    return VoiceState(
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      commandResult: commandResult ?? this.commandResult,
      executionResponse: executionResponse ?? this.executionResponse,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      amplitude: amplitude ?? this.amplitude,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      languageHint: languageHint ?? this.languageHint,
    );
  }
}

final voiceControllerProvider = StateNotifierProvider<VoiceController, VoiceState>((ref) {
  final repo = ref.watch(voiceRepositoryProvider);
  final homeState = ref.watch(homeControllerProvider);
  return VoiceController(ref, repo, homeState.activeHome?.id);
});

class VoiceController extends StateNotifier<VoiceState> {
  final Ref _ref;
  final VoiceRepository _voiceRepo;
  final String? _homeId;

  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _durationTimer;
  Timer? _amplitudeTimer;
  String? _currentRecordingPath;

  VoiceController(this._ref, this._voiceRepo, this._homeId)
      : super(const VoiceState());

  void setLanguageHint(String hint) {
    state = state.copyWith(languageHint: hint);
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

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/homestock_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = filePath;

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          bitRate: 64000,
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

          // Auto-stop after 60 seconds limit
          if (nextSec >= 60) {
            stopRecordingAndProcess();
          }
        } else {
          timer.cancel();
        }
      });

      // Amplitude polling for pulse / wave visualizer
      _amplitudeTimer?.cancel();
      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
        if (state.isRecording) {
          try {
            final amp = await _audioRecorder.getAmplitude();
            // amp.current is in dBFS (-160 to 0). Normalize to 0.0 - 1.0
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

  /// Stops the recording, uploads to backend for Whisper STT and semantic parsing.
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

      // Call end-to-end processAudio on backend
      final langHint = state.languageHint == 'auto' ? null : state.languageHint;
      final result = await _voiceRepo.processAudio(path, homeId, languageHint: langHint);

      // Clean up local temp file immediately for privacy
      _cleanUpAudioFile(path);

      state = state.copyWith(
        status: VoiceStatus.parsed,
        transcript: result.transcript,
        commandResult: result,
        selectedOptionId: result.disambiguationOptions.isNotEmpty
            ? result.disambiguationOptions.first.id
            : null,
      );

      // If command requires no confirmation and confidence is high, auto-execute could happen,
      // or user can tap confirm.
    } catch (e) {
      debugPrint('Voice processing error: $e');
      state = state.copyWith(
        status: VoiceStatus.error,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
    }
  }

  /// Cancels recording and resets state.
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

  /// Parse text directly (e.g. user typed or edited transcript).
  Future<void> parseTextCommand(String text) async {
    if (text.trim().isEmpty) return;

    final homeId = _homeId;
    if (homeId == null) {
      state = state.copyWith(
        status: VoiceStatus.error,
        errorMessage: 'Please select a home to use voice commands.',
      );
      return;
    }

    state = state.copyWith(status: VoiceStatus.processing, transcript: text.trim());

    try {
      final result = await _voiceRepo.parseCommand(text.trim(), homeId);
      state = state.copyWith(
        status: VoiceStatus.parsed,
        commandResult: result,
        selectedOptionId: result.disambiguationOptions.isNotEmpty
            ? result.disambiguationOptions.first.id
            : null,
      );
    } catch (e) {
      state = state.copyWith(
        status: VoiceStatus.error,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
    }
  }

  void selectOption(String optionId) {
    state = state.copyWith(selectedOptionId: optionId);
  }

  /// Executes the parsed voice command.
  Future<bool> confirmAndExecute() async {
    final cmd = state.commandResult;
    final homeId = _homeId;
    if (cmd == null || homeId == null) return false;

    state = state.copyWith(status: VoiceStatus.executing);

    try {
      final request = ExecuteCommandRequest(
        homeId: homeId,
        commandResult: cmd,
        confirmed: true,
        selectedOptionId: state.selectedOptionId,
      );

      final response = await _voiceRepo.executeCommand(request);

      state = state.copyWith(
        status: response.success ? VoiceStatus.success : VoiceStatus.error,
        executionResponse: response,
        errorMessage: response.success ? null : response.message,
      );

      if (response.success) {
        // Refresh relevant app state based on intent
        _refreshDomains(cmd.intent);
      }

      return response.success;
    } catch (e) {
      state = state.copyWith(
        status: VoiceStatus.error,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  void _refreshDomains(VoiceIntentType intent) {
    switch (intent) {
      case VoiceIntentType.addShoppingItem:
      case VoiceIntentType.removeShoppingItem:
      case VoiceIntentType.completeShoppingItem:
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

  void reset() {
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    state = const VoiceState();
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
    _durationTimer?.cancel();
    _amplitudeTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }
}
