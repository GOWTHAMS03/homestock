import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/sync/connectivity_monitor.dart';
import 'package:homestock/core/sync/sync_providers.dart';
import 'package:homestock/core/sync/sync_status.dart';
import 'package:homestock/features/voice/models/ai_voice_settings.dart';
import 'package:homestock/features/voice/services/ai_voice_service.dart';
import 'package:homestock/features/voice/widgets/ai_voice_response_card.dart';

class FakeConnectivityMonitor extends ConnectivityMonitor {
  final bool _online;
  FakeConnectivityMonitor({bool online = true}) : _online = online;

  @override
  bool get isOnline => _online;

  @override
  NetworkStatus get currentStatus =>
      _online ? NetworkStatus.online : NetworkStatus.offline;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiVoiceSettings Model & Notifier Tests', () {
    test('Default settings are properly initialized', () {
      const settings = AiVoiceSettings();
      expect(settings.voiceResponsesEnabled, isTrue);
      expect(settings.autoPlayEnabled, isTrue);
      expect(settings.voiceGender, 'Female');
      expect(settings.speakingSpeed, 1.0);
      expect(settings.isMuted, isFalse);
    });

    test('copyWith properly updates properties', () {
      const settings = AiVoiceSettings();
      final updated = settings.copyWith(
        speakingSpeed: 1.2,
        isMuted: true,
        autoPlayEnabled: false,
      );
      expect(updated.speakingSpeed, 1.2);
      expect(updated.isMuted, isTrue);
      expect(updated.autoPlayEnabled, isFalse);
      expect(updated.voiceGender, 'Female');
    });

    test('Json serialization and deserialization work', () {
      const settings = AiVoiceSettings(
        voiceResponsesEnabled: true,
        autoPlayEnabled: false,
        speakingSpeed: 0.8,
        isMuted: true,
      );
      final json = settings.toJson();
      final restored = AiVoiceSettings.fromJson(json);

      expect(restored.voiceResponsesEnabled, isTrue);
      expect(restored.autoPlayEnabled, isFalse);
      expect(restored.speakingSpeed, 0.8);
      expect(restored.isMuted, isTrue);
    });

    test('Notifier toggles mute and updates speed correctly', () {
      final notifier = AiVoiceSettingsNotifier();
      expect(notifier.state.isMuted, isFalse);

      notifier.toggleMute();
      expect(notifier.state.isMuted, isTrue);

      notifier.setSpeakingSpeed(1.2);
      expect(notifier.state.speakingSpeed, 1.2);

      notifier.setAutoPlayEnabled(false);
      expect(notifier.state.autoPlayEnabled, isFalse);
    });
  });

  group('AiVoiceService Summary & URL Tests', () {
    test('Short text remains unchanged in voice summary', () {
      const text = 'உங்களிடம் 4.2 கிலோ அரிசி இருக்கு.';
      final summary = AiVoiceService.getVoiceSummary(text);
      expect(summary, equals(text));
    });

    test('Long multi-sentence text is concisely summarized to 1-2 sentences', () {
      const longText =
          'You currently have approximately 4.2 kilograms of Ponni Raw Rice remaining in your Pantry Shelf inventory, based on the latest synchronized inventory information. Would you like me to add more rice to your shopping list? You can also check nearby deals for rice at fresh stores.';
      final summary = AiVoiceService.getVoiceSummary(longText);

      expect(summary.length, lessThanOrEqualTo(200));
      expect(summary.contains('4.2 kilograms of Ponni Raw Rice'), isTrue);
    });
  });

  group('AiVoiceResponseCard Widget Tests', () {
    testWidgets('Renders HomeStock AI header, language tag, and text content when online',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityMonitorProvider.overrideWithValue(FakeConnectivityMonitor(online: true)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AiVoiceResponseCard(
                text: 'உங்களிடம் 4.2 கிலோ அரிசி இருக்கு.',
                language: 'TA',
                isVoiceInteraction: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('HomeStock AI'), findsOneWidget);
      expect(find.text('TA'), findsOneWidget);
      expect(find.text('உங்களிடம் 4.2 கிலோ அரிசி இருக்கு.'), findsOneWidget);
      expect(find.text('Female Voice'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('Replay'), findsOneWidget);
    });

    testWidgets('Long text displays "Read more" toggle button',
        (WidgetTester tester) async {
      const longReport =
          'You currently have approximately 4.2 kilograms of Ponni Raw Rice remaining in your Pantry Shelf inventory, based on the latest synchronized inventory information. Would you like me to add more rice to your shopping list? You can also check nearby deals for rice at fresh stores.';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityMonitorProvider.overrideWithValue(FakeConnectivityMonitor(online: true)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AiVoiceResponseCard(
                text: longReport,
                language: 'EN',
                isVoiceInteraction: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Read more'), findsOneWidget);

      await tester.tap(find.text('Read more'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Read less'), findsOneWidget);
    });

    testWidgets('Mute button toggles mute state in settings',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityMonitorProvider.overrideWithValue(FakeConnectivityMonitor(online: true)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AiVoiceResponseCard(
                text: 'Added 2 kg Rice to shopping list.',
                language: 'EN',
                isVoiceInteraction: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Find mute button (IconButton with tooltip Mute)
      final muteBtn = find.byTooltip('Mute');
      expect(muteBtn, findsOneWidget);

      await tester.tap(muteBtn);
      await tester.pump(const Duration(milliseconds: 100));

      // Should show Unmute tooltip now
      expect(find.byTooltip('Unmute'), findsOneWidget);
      expect(find.text('Muted'), findsOneWidget);
    });

    testWidgets('Offline behavior: hides voice controls and shows offline indicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityMonitorProvider.overrideWithValue(FakeConnectivityMonitor(online: false)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AiVoiceResponseCard(
                text: 'Offline shopping response',
                language: 'EN',
                isVoiceInteraction: false,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('HomeStock AI'), findsOneWidget);
      expect(find.text('Offline shopping response'), findsOneWidget);
      expect(find.text('Offline — voice response available online'), findsOneWidget);
      // Play and Replay controls must NOT be present when offline
      expect(find.text('Play'), findsNothing);
      expect(find.text('Replay'), findsNothing);
    });

    testWidgets('Displays screen time / timestamp chip on card',
        (WidgetTester tester) async {
      final testTime = DateTime(2026, 9, 14, 8, 30);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            connectivityMonitorProvider.overrideWithValue(FakeConnectivityMonitor(online: true)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AiVoiceResponseCard(
                text: '2 items added to your shopping list.',
                language: 'EN',
                timestamp: testTime,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('08:30 AM'), findsOneWidget);
    });
  });
}
