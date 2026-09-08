import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:whisper_cpp_flutter_plus/whisper_cpp_flutter_plus.dart';
import '../../models/voice_transcript.dart';
import 'offline_model_manager.dart';
import 'speech_engine.dart';

/// Offline Speech Recognition engine powered by whisper.cpp running natively
/// on the Android device via FFI. No API key, no internet, no paid service.
///
/// Uses the `whisper_cpp_flutter_plus` package for native whisper.cpp bindings.
/// Requires a downloaded GGML model (multilingual, NOT .en) for Tamil + English.
class OfflineSpeechEngine implements SpeechEngine {
  final OfflineModelManager _modelManager;

  OfflineSpeechEngine({required OfflineModelManager modelManager})
      : _modelManager = modelManager;

  @override
  Future<bool> isAvailable() async {
    // Check if a model is installed
    if (_modelManager.isModelReady) return true;
    return await _modelManager.isModelInstalled();
  }

  @override
  Future<VoiceTranscript> transcribe(
    String audioFilePath, {
    String? languageHint,
  }) async {
    final startTime = DateTime.now();

    // 1. Validate audio file exists and has data
    final file = File(audioFilePath);
    if (!file.existsSync()) {
      throw Exception('Audio file does not exist: $audioFilePath');
    }

    final fileSize = file.lengthSync();
    if (fileSize < 500) {
      throw Exception('Audio recording was too short or silent.');
    }

    // 2. Ensure model is loaded
    final engine = _modelManager.engine ?? await _modelManager.loadModel();
    if (engine == null) {
      throw Exception(
        'Voice model is not installed. Please download the offline voice model in Settings.',
      );
    }

    // 3. Transcribe using whisper.cpp via the loaded engine
    try {
      final pcm16k = await WhisperAudio.readWav(file);
      final task = engine.transcribe(
        pcm16k,
        options: TranscribeOptions(
          language: languageHint ?? 'auto',
          noTimestamps: true,
          translate: false,
        ),
      );

      final result = await task.result;
      final transcriptText = result.text.trim();
      final duration = DateTime.now().difference(startTime).inMilliseconds;

      if (kDebugMode) {
        print('[OfflineSpeechEngine] whisper.cpp transcribed in ${duration}ms: "$transcriptText" (lang: ${result.language})');
      }

      // Calculate confidence based on transcript quality
      double confidence = 0.90;
      if (transcriptText.isEmpty) {
        confidence = 0.0;
      } else if (transcriptText.length < 3) {
        confidence = 0.60;
      } else if (transcriptText.contains('[') || transcriptText.contains('(')) {
        // whisper.cpp sometimes outputs [BLANK_AUDIO] or (background noise)
        confidence = 0.30;
      }

      return VoiceTranscript(
        rawText: transcriptText,
        cleanText: cleanWhisperOutput(transcriptText),
        language: result.language.isNotEmpty ? result.language : (languageHint ?? 'auto'),
        confidence: confidence,
        isOffline: true,
        durationMs: duration,
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      if (kDebugMode) {
        print('[OfflineSpeechEngine] Transcription error after ${duration}ms: $e');
      }
      throw Exception('Offline speech recognition failed: $e');
    }
  }

  /// Cleans whisper.cpp output artifacts that are not real speech
  static String cleanWhisperOutput(String text) {
    String clean = text.trim();

    // Remove whisper.cpp hallucination artifacts
    clean = clean.replaceAll(RegExp(r'\[.*?\]'), ''); // [BLANK_AUDIO], [Music], etc.
    clean = clean.replaceAll(RegExp(r'\(.*?\)'), ''); // (background noise), (laughing), etc.
    clean = clean.replaceAll(RegExp(r'♪.*?♪'), '');   // Music symbols
    clean = clean.replaceAll(RegExp(r'\.{3,}'), '');  // Excessive dots

    // Normalize whitespace
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Remove leading/trailing punctuation that whisper adds
    clean = clean.replaceAll(RegExp(r'^[.,!?;:\s]+'), '');
    clean = clean.replaceAll(RegExp(r'[.,!?;:\s]+$'), '');

    return clean;
  }
}
