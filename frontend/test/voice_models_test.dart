import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/features/voice/models/voice_models.dart';

void main() {
  group('Voice Models Test', () {
    test('TranscriptionResult deserialization', () {
      final json = {
        'transcript': 'Add 2 litre cooking oil to shopping list',
        'language': 'en',
        'confidence': 0.98,
        'processingTimeMs': 320,
      };

      final result = TranscriptionResult.fromJson(json);
      expect(result.transcript, equals('Add 2 litre cooking oil to shopping list'));
      expect(result.language, equals('en'));
      expect(result.confidence, equals(0.98));
      expect(result.processingTimeMs, equals(320));
    });

    test('VoiceCommandResult with Disambiguation deserialization and serialization', () {
      final json = {
        'transcript': 'Rice stock 5 kg',
        'intent': 'UPDATE_STOCK',
        'confidence': 0.92,
        'entities': {
          'itemName': 'Rice',
          'quantity': 5,
          'unit': 'kg',
        },
        'requiresConfirmation': true,
        'message': 'Update stock for Rice to 5 kg or add it?',
        'disambiguationOptions': [
          {
            'id': 'SET',
            'label': 'Set stock to 5 kg',
            'subLabel': 'Replaces current recorded quantity',
            'action': 'SET_STOCK',
          },
          {
            'id': 'ADD',
            'label': 'Add 5 kg more',
            'subLabel': 'Increases current recorded quantity',
            'action': 'ADD_STOCK',
          }
        ]
      };

      final cmd = VoiceCommandResult.fromJson(json);
      expect(cmd.intent, equals(VoiceIntentType.updateStock));
      expect(cmd.transcript, equals('Rice stock 5 kg'));
      expect(cmd.requiresConfirmation, isTrue);
      expect(cmd.entities?.itemName, equals('Rice'));
      expect(cmd.entities?.quantity, equals(5));
      expect(cmd.entities?.unit, equals('kg'));
      expect(cmd.disambiguationOptions.length, equals(2));
      expect(cmd.disambiguationOptions[0].id, equals('SET'));
      expect(cmd.disambiguationOptions[1].action, equals('ADD_STOCK'));

      final serialized = cmd.toJson();
      expect(serialized['intent'], equals('UPDATE_STOCK'));
      expect(serialized['requiresConfirmation'], isTrue);
    });

    test('ExecuteCommandResponse deserialization', () {
      final json = {
        'success': true,
        'intent': 'ADD_SHOPPING_ITEM',
        'message': 'Added 2 L Cooking Oil to shopping list',
        'navigation': {'route': '/shopping'},
      };

      final res = ExecuteCommandResponse.fromJson(json);
      expect(res.success, isTrue);
      expect(res.intent, equals(VoiceIntentType.addShoppingItem));
      expect(res.message, equals('Added 2 L Cooking Oil to shopping list'));
      expect(res.navigation?['route'], equals('/shopping'));
    });

    test('VoiceIntentType display name and server string', () {
      expect(VoiceIntentType.addShoppingItem.displayName, equals('Add to Shopping List'));
      expect(VoiceIntentType.addShoppingItem.toServerString(), equals('ADD_SHOPPING_ITEM'));

      expect(VoiceIntentType.stockOut.displayName, equals('Use / Deduct Stock'));
      expect(VoiceIntentType.stockOut.toServerString(), equals('STOCK_OUT'));

      expect(VoiceIntentType.openShoppingList.toServerString(), equals('OPEN_SHOPPING_LIST'));
      expect(VoiceIntentType.fromString('GET_LOW_STOCK_ITEMS'), equals(VoiceIntentType.getLowStockItems));
    });
  });
}
