import 'package:flutter/foundation.dart';
import '../../../../core/sync/connectivity_monitor.dart';
import '../../models/voice_transcript.dart';
import 'offline_speech_engine.dart';
import 'online_speech_engine.dart';
import 'speech_engine.dart';

/// Coordinates hybrid speech recognition across Online (Whisper) and Offline engines
/// based on connectivity and user mode preferences.
class HybridSpeechEngine {
  final OnlineSpeechEngine _onlineEngine;
  final OfflineSpeechEngine _offlineEngine;
  final ConnectivityMonitor? _connectivity;
  SpeechEngineMode mode;

  HybridSpeechEngine({
    required OnlineSpeechEngine onlineEngine,
    required OfflineSpeechEngine offlineEngine,
    ConnectivityMonitor? connectivity,
    this.mode = SpeechEngineMode.auto,
  })  : _onlineEngine = onlineEngine,
        _offlineEngine = offlineEngine,
        _connectivity = connectivity;

  bool get isOnline => _connectivity?.isOnline ?? true;

  /// Transcribes audio using the selected mode and automatic fallbacks
  Future<VoiceTranscript> transcribe(
    String audioFilePath, {
    String? languageHint,
  }) async {
    switch (mode) {
      case SpeechEngineMode.offlineOnly:
        return _offlineEngine.transcribe(audioFilePath, languageHint: languageHint);

      case SpeechEngineMode.onlinePreferred:
        try {
          return await _onlineEngine.transcribe(audioFilePath, languageHint: languageHint);
        } catch (e) {
          debugPrint('[HybridSpeechEngine] Online preferred failed: $e');
          rethrow;
        }

      case SpeechEngineMode.auto:
        // 1. If internet is available, prefer online ASR
        if (isOnline) {
          try {
            return await _onlineEngine.transcribe(audioFilePath, languageHint: languageHint);
          } catch (e) {
            debugPrint('[HybridSpeechEngine] Online ASR failed, falling back to offline: $e');
            // 3. If online ASR fails, automatically fallback to offline ASR
            return await _offlineEngine.transcribe(audioFilePath, languageHint: languageHint);
          }
        } else {
          // 2. If internet is unavailable, automatically use offline ASR
          debugPrint('[HybridSpeechEngine] Device is offline, using offline speech engine');
          return await _offlineEngine.transcribe(audioFilePath, languageHint: languageHint);
        }
    }
  }
}
