import '../../models/voice_transcript.dart';

/// Operating modes for the speech-to-text recognition pipeline
enum SpeechEngineMode {
  auto,
  offlineOnly,
  onlinePreferred;

  static SpeechEngineMode fromString(String? val) {
    if (val == null) return SpeechEngineMode.auto;
    switch (val.toLowerCase()) {
      case 'offline_only':
      case 'offlineonly':
        return SpeechEngineMode.offlineOnly;
      case 'online_preferred':
      case 'onlinepreferred':
        return SpeechEngineMode.onlinePreferred;
      default:
        return SpeechEngineMode.auto;
    }
  }

  String get displayName {
    switch (this) {
      case SpeechEngineMode.auto:
        return 'Auto (Recommended)';
      case SpeechEngineMode.offlineOnly:
        return 'Offline Only';
      case SpeechEngineMode.onlinePreferred:
        return 'Online Preferred';
    }
  }
}

/// Abstract interface for speech recognition engines
abstract class SpeechEngine {
  Future<VoiceTranscript> transcribe(
    String audioFilePath, {
    String? languageHint,
  });

  /// Whether this engine is operational on the current platform / connection
  Future<bool> isAvailable();
}
