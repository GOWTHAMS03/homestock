import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/features/voice/widgets/voice_input_button.dart';

void main() {
  group('VoiceInputButton Widget Test', () {
    testWidgets('Renders iconOnly variant properly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: VoiceInputButton(
                  tooltip: 'Voice command',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('Renders floating variant properly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              floatingActionButton: VoiceInputButton.floating(
                tooltip: 'Floating voice command',
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('Renders compactChip variant properly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: VoiceInputButton.compactChip(),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.text('Voice'), findsOneWidget);
    });
  });
}
