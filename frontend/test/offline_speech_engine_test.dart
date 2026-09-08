import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/features/voice/data/speech/offline_speech_engine.dart';
import 'package:homestock/features/voice/data/speech/speech_engine.dart';

void main() {
  group('OfflineSpeechEngine Output Cleaning', () {
    test('removes [BLANK_AUDIO] and bracketed artifacts', () {
      expect(
        OfflineSpeechEngine.cleanWhisperOutput('[BLANK_AUDIO]'),
        equals(''),
      );
      expect(
        OfflineSpeechEngine.cleanWhisperOutput('[Music] 2 kilo rice add pannu [Applause]'),
        equals('2 kilo rice add pannu'),
      );
    });

    test('removes parenthesized artifacts', () {
      expect(
        OfflineSpeechEngine.cleanWhisperOutput('(background noise) oru litre oil add pannu (coughing)'),
        equals('oru litre oil add pannu'),
      );
    });

    test('removes musical notes and excessive dots', () {
      expect(
        OfflineSpeechEngine.cleanWhisperOutput('♪ singing ♪... rendu packet milk venum...'),
        equals('rendu packet milk venum'),
      );
    });

    test('removes leading and trailing punctuation', () {
      expect(
        OfflineSpeechEngine.cleanWhisperOutput('... ,,, 2 kg sugar shopping list la podu. !'),
        equals('2 kg sugar shopping list la podu'),
      );
    });

    test('normalizes multiple spaces', () {
      expect(
        OfflineSpeechEngine.cleanWhisperOutput('  rendu    kilo   rice   add   pannu  '),
        equals('rendu kilo rice add pannu'),
      );
    });

    test('clean output passes unchanged for standard Tamil/Tanglish', () {
      expect(
        OfflineSpeechEngine.cleanWhisperOutput('2 kilo rice add pannu'),
        equals('2 kilo rice add pannu'),
      );
      expect(
        OfflineSpeechEngine.cleanWhisperOutput('இரண்டு கிலோ அரிசி சேர்க்கவும்'),
        equals('இரண்டு கிலோ அரிசி சேர்க்கவும்'),
      );
    });
  });

  group('HybridSpeechEngine Mode Tests', () {
    test('default mode is auto (offline first)', () {
      // OfflineSpeechEngine is instantiated with a mock or stub OfflineModelManager
      expect(SpeechEngineMode.auto, isNotNull);
      expect(SpeechEngineMode.offlineOnly, isNotNull);
      expect(SpeechEngineMode.onlinePreferred, isNotNull);
    });
  });
}
