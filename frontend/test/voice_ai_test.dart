import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homestock/features/voice/models/voice_models.dart';
import 'package:homestock/features/voice/services/voice_ai_service.dart';
import 'package:homestock/features/voice/widgets/voice_feedback_widget.dart';

void main() {
  group('Gemini Voice AI Models & Logic Tests', () {
    test('VoiceCommandResult deserialization with AI fields', () {
      final json = {
        'transcript': '2 kilo arisi shopping list la add pannu',
        'intent': 'ADD_SHOPPING_ITEM',
        'confidence': 0.98,
        'intentConfidence': 0.99,
        'productMatchConfidence': 0.98,
        'detectedLanguage': 'TANGLISH',
        'voiceCommandId': 'c1234567-89ab-cdef-0123-456789abcdef',
        'idempotencyKey': 'voice-1710000000-123456',
        'commandMode': 'COMMAND',
        'executionStatus': 'READY_TO_EXECUTE',
        'needsQuantity': false,
        'needsProduct': false,
        'entities': {
          'itemName': 'Ponni Raw Rice',
          'quantity': 2,
          'unit': 'KG',
          'target': 'SHOPPING_LIST',
        },
        'requiresConfirmation': false,
        'message': '2 kilo Rice shopping list-la add panniten.',
        'disambiguationOptions': [],
      };

      final result = VoiceCommandResult.fromJson(json);

      expect(result.intent, equals(VoiceIntentType.addShoppingItem));
      expect(result.detectedLanguage, equals('TANGLISH'));
      expect(result.intentConfidence, equals(0.99));
      expect(result.productMatchConfidence, equals(0.98));
      expect(result.voiceCommandId, equals('c1234567-89ab-cdef-0123-456789abcdef'));
      expect(result.entities?.itemName, equals('Ponni Raw Rice'));
      expect(result.entities?.quantity, equals(2));
      expect(result.entities?.unit, equals('KG'));
      expect(result.needsQuantity, isFalse);
    });

    test('canAutoExecute verifies dual confidence and missing fields', () {
      final aiService = VoiceAiService(
        voiceRepository: null as dynamic,
        localExecutor: null as dynamic,
        isOnline: true,
      );

      // High confidence -> can auto execute
      final highConfidenceCmd = VoiceCommandResult(
        transcript: 'Add 2 kg rice',
        intent: VoiceIntentType.addShoppingItem,
        intentConfidence: 0.95,
        productMatchConfidence: 0.98,
        message: 'Added 2 kg Rice',
        requiresConfirmation: false,
      );
      expect(aiService.canAutoExecute(highConfidenceCmd), isTrue);

      // Low product confidence (0.70 < 0.80 threshold) on inventory action -> cannot auto execute
      final mediumProductCmd = VoiceCommandResult(
        transcript: 'Remove oil',
        intent: VoiceIntentType.stockOut,
        intentConfidence: 0.95,
        productMatchConfidence: 0.70,
        message: 'Which oil?',
        requiresConfirmation: false,
      );
      expect(aiService.canAutoExecute(mediumProductCmd), isFalse);

      // Missing quantity -> cannot auto execute
      final missingQuantityCmd = VoiceCommandResult(
        transcript: 'Add sugar',
        intent: VoiceIntentType.addShoppingItem,
        intentConfidence: 0.95,
        productMatchConfidence: 0.98,
        message: 'How much sugar?',
        needsQuantity: true,
      );
      expect(aiService.canAutoExecute(missingQuantityCmd), isFalse);

      // Dangerous action (Clear Shopping List) -> cannot auto execute
      final clearListCmd = VoiceCommandResult(
        transcript: 'Clear shopping list',
        intent: VoiceIntentType.clearShoppingList,
        intentConfidence: 0.99,
        productMatchConfidence: 1.0,
        message: 'Are you sure?',
      );
      expect(aiService.canAutoExecute(clearListCmd), isFalse);
    });

    testWidgets('VoiceFeedbackWidget renders action, language and entities',
        (WidgetTester tester) async {
      final result = VoiceCommandResult(
        transcript: '2 packet biscuit add pannu',
        intent: VoiceIntentType.addShoppingItem,
        confidence: 0.96,
        detectedLanguage: 'TANGLISH',
        message: '2 packet Biscuits shopping list-la add panniten.',
        entities: const VoiceEntities(
          itemName: 'Biscuits',
          quantity: 2,
          unit: 'PACKET',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: VoiceFeedbackWidget(result: result),
            ),
          ),
        ),
      );

      expect(find.text('TANGLISH'), findsOneWidget);
      expect(find.text('Add to Shopping List'), findsOneWidget);
      expect(find.text('2 packet Biscuits shopping list-la add panniten.'), findsOneWidget);
      expect(find.textContaining('Biscuits'), findsWidgets);
      expect(find.text('96% confidence'), findsOneWidget);
    });
  });
}

