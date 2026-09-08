import 'package:flutter/foundation.dart';
import '../../../../core/sync/connectivity_monitor.dart';
import '../../models/voice_transcript.dart';
import 'offline_speech_engine.dart';
import 'online_speech_engine.dart';
import 'speech_engine.dart';

/// Coordinates hybrid speech recognition with OFFLINE-FIRST architecture.
///
/// Priority order in `auto` mode:
/// 1. Try OFFLINE whisper.cpp first (always, for short HomeStock commands)
/// 2. If offline confidence < 0.65 AND internet available AND user enabled enhanced:
///    → Try ONLINE as optional fallback
/// 3. If internet unavailable → stay offline (never break)
///
/// The app must NEVER require internet for voice commands after model download.
class HybridSpeechEngine {
  final OnlineSpeechEngine _onlineEngine;
  final OfflineSpeechEngine _offlineEngine;
  final ConnectivityMonitor? _connectivity;
  SpeechEngineMode mode;

  /// Minimum offline confidence to accept without trying online fallback
  static const double _offlineConfidenceThreshold = 0.65;

  HybridSpeechEngine({
    required OnlineSpeechEngine onlineEngine,
    required OfflineSpeechEngine offlineEngine,
    ConnectivityMonitor? connectivity,
    this.mode = SpeechEngineMode.auto,
  })  : _onlineEngine = onlineEngine,
        _offlineEngine = offlineEngine,
        _connectivity = connectivity;

  bool get isOnline => _connectivity?.isOnline ?? false;

  /// Transcribes audio using the selected mode with OFFLINE-FIRST strategy
  Future<VoiceTranscript> transcribe(
    String audioFilePath, {
    String? languageHint,
  }) async {
    switch (mode) {
      case SpeechEngineMode.offlineOnly:
        // Pure offline — whisper.cpp only, no network
        return _offlineEngine.transcribe(audioFilePath, languageHint: languageHint);

      case SpeechEngineMode.onlinePreferred:
        // User explicitly wants online first (kept for compatibility)
        if (isOnline) {
          try {
            return await _onlineEngine.transcribe(audioFilePath, languageHint: languageHint);
          } catch (e) {
            debugPrint('[HybridSpeechEngine] Online preferred failed, falling back to offline: $e');
            return _offlineEngine.transcribe(audioFilePath, languageHint: languageHint);
          }
        } else {
          debugPrint('[HybridSpeechEngine] Device is offline, using offline speech engine');
          return _offlineEngine.transcribe(audioFilePath, languageHint: languageHint);
        }

      case SpeechEngineMode.auto:
        // ─── OFFLINE-FIRST STRATEGY ─────────────────────────────
        //
        // 1. Always try offline whisper.cpp first (fast, free, private)
        // 2. Only fallback to online if:
        //    - Offline confidence is very low
        //    - Internet is available
        //    - The transcript is too short/empty
        //
        // This ensures voice commands ALWAYS work without internet.
        // ─────────────────────────────────────────────────────────

        final offlineAvailable = await _offlineEngine.isAvailable();

        if (offlineAvailable) {
          try {
            final offlineResult = await _offlineEngine.transcribe(
              audioFilePath,
              languageHint: languageHint,
            );

            // Accept offline result if confidence is reasonable
            if (offlineResult.confidence >= _offlineConfidenceThreshold &&
                offlineResult.cleanText.trim().isNotEmpty) {
              debugPrint('[HybridSpeechEngine] Offline transcription accepted '
                  '(confidence: ${offlineResult.confidence})');
              return offlineResult;
            }

            // Low confidence or empty — try online as optional enhancement
            if (isOnline && offlineResult.cleanText.trim().isEmpty) {
              debugPrint('[HybridSpeechEngine] Offline result empty, trying online fallback');
              try {
                return await _onlineEngine.transcribe(audioFilePath, languageHint: languageHint);
              } catch (e) {
                debugPrint('[HybridSpeechEngine] Online fallback also failed: $e');
                // Return offline result even if low confidence — better than nothing
                return offlineResult;
              }
            }

            // Return offline result regardless — it's the best we have
            return offlineResult;
          } catch (e) {
            debugPrint('[HybridSpeechEngine] Offline transcription failed: $e');

            // If offline fails entirely and we have internet, try online
            if (isOnline) {
              try {
                return await _onlineEngine.transcribe(audioFilePath, languageHint: languageHint);
              } catch (onlineError) {
                debugPrint('[HybridSpeechEngine] Both engines failed');
                rethrow;
              }
            }

            // No internet, offline failed — propagate the error
            rethrow;
          }
        } else {
          // Model not installed — try online if available
          if (isOnline) {
            debugPrint('[HybridSpeechEngine] Offline model not available, using online');
            return await _onlineEngine.transcribe(audioFilePath, languageHint: languageHint);
          } else {
            throw Exception(
              'Voice model is not installed and device is offline. '
              'Please download the offline voice model in Settings or connect to the internet.',
            );
          }
        }
    }
  }
}
