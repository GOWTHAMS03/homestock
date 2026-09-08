import '../voice_repository.dart';
import '../../models/voice_transcript.dart';
import 'speech_engine.dart';

/// Online Speech Recognition engine powered by backend Whisper API
class OnlineSpeechEngine implements SpeechEngine {
  final VoiceRepository _voiceRepo;

  OnlineSpeechEngine({required VoiceRepository voiceRepo}) : _voiceRepo = voiceRepo;

  @override
  Future<bool> isAvailable() async {
    return true;
  }

  @override
  Future<VoiceTranscript> transcribe(
    String audioFilePath, {
    String? languageHint,
  }) async {
    final startTime = DateTime.now();
    final result = await _voiceRepo.transcribeAudio(
      audioFilePath,
      languageHint: languageHint,
    );
    final duration = DateTime.now().difference(startTime).inMilliseconds;

    return VoiceTranscript(
      rawText: result.transcript,
      cleanText: result.transcript.trim(),
      language: result.language,
      confidence: result.confidence,
      isOffline: false,
      durationMs: duration,
    );
  }
}
