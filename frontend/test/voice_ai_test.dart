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

      // Quantity confirmation required -> CANNOT auto execute
      final quantityConfirmCmd = VoiceCommandResult(
        transcript: 'add 200 kg rice',
        intent: VoiceIntentType.stockIn,
        intentConfidence: 0.99,
        productMatchConfidence: 0.99,
        requiresConfirmation: true,
        executionStatus: 'NEEDS_QUANTITY_CONFIRMATION',
        quantityConfirmation: const QuantityConfirmationInfo(
          action: 'ADD',
          productName: 'Rice',
          requestedQuantity: 200,
          requestedUnit: 'KG',
          currentQuantity: 9,
          currentUnit: 'KG',
          projectedQuantity: 209,
          promptTitle: 'Add 200 kg of Rice?',
          promptCurrent: 'You currently have 9 kg.',
          promptProjected: 'Your new stock will be 209 kg.',
        ),
        message: 'Add 200 kg of Rice? You currently have 9 kg. Your new stock will be 209 kg.',
      );
      expect(aiService.canAutoExecute(quantityConfirmCmd), isFalse);
    });

    test('QuantityConfirmationInfo serialization and deserialization', () {
      final json = {
        'action': 'ADD',
        'productName': 'Rice',
        'requestedQuantity': 200,
        'requestedUnit': 'KG',
        'currentQuantity': 9,
        'currentUnit': 'KG',
        'projectedQuantity': 209,
        'promptTitle': 'Add 200 kg of Rice?',
        'promptCurrent': 'You currently have 9 kg.',
        'promptProjected': 'Your new stock will be 209 kg.',
        'warningReason': 'Unusually high quantity detected for household rice (> 25 kg).',
      };

      final info = QuantityConfirmationInfo.fromJson(json);
      expect(info.action, equals('ADD'));
      expect(info.productName, equals('Rice'));
      expect(info.requestedQuantity, equals(200));
      expect(info.requestedUnit, equals('KG'));
      expect(info.currentQuantity, equals(9));
      expect(info.projectedQuantity, equals(209));
      expect(info.promptTitle, equals('Add 200 kg of Rice?'));
      expect(info.promptCurrent, equals('You currently have 9 kg.'));
      expect(info.promptProjected, equals('Your new stock will be 209 kg.'));
      expect(info.warningReason, contains('Unusually high quantity'));

      final serialized = info.toJson();
      expect(serialized['action'], equals('ADD'));
      expect(serialized['projectedQuantity'], equals(209));
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

    testWidgets('VoiceFeedbackWidget renders quantity confirmation card with Confirm, Edit quantity, and Cancel buttons',
        (WidgetTester tester) async {
      bool confirmed = false;
      bool cancelled = false;
      num? editedQuantity;

      final result = VoiceCommandResult(
        transcript: 'add 200 kg rice',
        intent: VoiceIntentType.stockIn,
        confidence: 0.98,
        detectedLanguage: 'EN',
        message: 'Add 200 kg of Rice? You currently have 9 kg. Your new stock will be 209 kg.',
        requiresConfirmation: true,
        executionStatus: 'NEEDS_QUANTITY_CONFIRMATION',
        entities: const VoiceEntities(
          action: 'ADD',
          itemName: 'Rice',
          quantity: 200,
          unit: 'KG',
        ),
        quantityConfirmation: const QuantityConfirmationInfo(
          action: 'ADD',
          productName: 'Rice',
          requestedQuantity: 200,
          requestedUnit: 'KG',
          currentQuantity: 9,
          currentUnit: 'KG',
          projectedQuantity: 209,
          promptTitle: 'Add 200 kg of Rice?',
          promptCurrent: 'You currently have 9 kg.',
          promptProjected: 'Your new stock will be 209 kg.',
          warningReason: 'Unusually high quantity detected for household rice (> 25 kg).',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: VoiceFeedbackWidget(
                result: result,
                onConfirm: () => confirmed = true,
                onCancel: () => cancelled = true,
                onQuantityChanged: (q) => editedQuantity = q,
              ),
            ),
          ),
        ),
      );

      // Verify prompt title, current stock, and projected stock
      expect(find.text('Add 200 kg of Rice?'), findsOneWidget);
      expect(find.text('You currently have 9 kg.'), findsOneWidget);
      expect(find.text('Your new stock will be 209 kg.'), findsOneWidget);

      // Verify the 3 actions: Confirm, Edit quantity, Cancel
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Edit quantity'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Confirm
      await tester.tap(find.text('Confirm'));
      expect(confirmed, isTrue);

      // Tap Edit quantity -> dialog opens
      await tester.tap(find.text('Edit quantity'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Quantity'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Enter new quantity 20
      await tester.enterText(find.byType(TextField), '20');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(editedQuantity, equals(20.0));
    });
  });
}

