import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/voice/number_parser/number_words.dart';
import 'package:homestock/core/voice/unit_normalizer/unit_dictionary.dart';
import 'package:homestock/core/voice/vocabulary/grocery_vocabulary.dart';
import 'package:homestock/features/voice/data/parser/command_parser.dart';
import 'package:homestock/features/voice/data/parser/product_resolver.dart';
import 'package:homestock/features/voice/data/parser/quantity_parser.dart';
import 'package:homestock/features/voice/domain/command_validator.dart';
import 'package:homestock/features/voice/models/voice_models.dart';

void main() {
  setUp(() {
    GroceryVocabulary.ensureInitialized();
  });

  group('Voice Command Dataset - 50+ Real-World Commands', () {
    final inventoryContext = [
      const ProductCandidate(id: 'inv-1', name: 'Basmati Rice', category: 'Grains', unit: 'kg', source: 'INVENTORY'),
      const ProductCandidate(id: 'inv-2', name: 'Brown Rice', category: 'Grains', unit: 'kg', source: 'INVENTORY'),
      const ProductCandidate(id: 'inv-3', name: 'Sunflower Cooking Oil', category: 'Oils & Ghee', unit: 'L', source: 'INVENTORY'),
      const ProductCandidate(id: 'inv-4', name: 'Aavin Milk', category: 'Dairy', unit: 'packet', source: 'INVENTORY'),
      const ProductCandidate(id: 'inv-5', name: 'Tata Salt', category: 'Spices & Seasonings', unit: 'kg', source: 'INVENTORY'),
    ];

    final singleRiceInventory = [
      const ProductCandidate(id: 'inv-1', name: 'Rice', category: 'Grains', unit: 'kg', source: 'INVENTORY'),
      const ProductCandidate(id: 'inv-3', name: 'Cooking Oil', category: 'Oils & Ghee', unit: 'L', source: 'INVENTORY'),
    ];

    // Helper to parse and assert
    void testCommand({
      required int testNumber,
      required String transcript,
      required VoiceIntentType expectedIntent,
      String? expectedProduct,
      double? expectedQuantity,
      String? expectedUnit,
      List<ProductCandidate>? context,
      bool? expectConfirmation,
      bool? expectAmbiguous,
    }) {
      test('#$testNumber: "$transcript"', () {
        final cmd = CommandParser.parse(
          transcript,
          userInventory: context ?? singleRiceInventory,
        );

        expect(cmd.intent, equals(expectedIntent), reason: 'Failed intent for: "$transcript"');
        if (expectedProduct != null) {
          expect(cmd.productName?.toLowerCase(), contains(expectedProduct.toLowerCase()),
              reason: 'Failed product for: "$transcript" (got: ${cmd.productName})');
        }
        if (expectedQuantity != null) {
          expect(cmd.quantity, equals(expectedQuantity),
              reason: 'Failed quantity for: "$transcript" (got: ${cmd.quantity})');
        }
        if (expectedUnit != null) {
          expect(cmd.unit?.toLowerCase(), equals(expectedUnit.toLowerCase()),
              reason: 'Failed unit for: "$transcript" (got: ${cmd.unit})');
        }
        if (expectConfirmation != null) {
          expect(cmd.requiresConfirmation, equals(expectConfirmation),
              reason: 'Failed confirmation for: "$transcript"');
        }
        if (expectAmbiguous != null) {
          expect(cmd.disambiguationOptions.isNotEmpty, equals(expectAmbiguous),
              reason: 'Failed ambiguous check for: "$transcript"');
        }
      });
    }

    // ─────────────────────────────────────────────────────────────
    // 1–10: Core Shopping List Additions (English, Tamil, Tanglish)
    // ─────────────────────────────────────────────────────────────
    testCommand(
      testNumber: 1,
      transcript: '2 kilo rice add pannu',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Rice',
      expectedQuantity: 2.0,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 2,
      transcript: 'rendu kilo rice add pannu',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Rice',
      expectedQuantity: 2.0,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 3,
      transcript: 'rendu kilo arisi add pannu',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Rice',
      expectedQuantity: 2.0,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 4,
      transcript: '2 kg rice shopping list la podu',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Rice',
      expectedQuantity: 2.0,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 5,
      transcript: 'Add 2 kg rice to my shopping list',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Rice',
      expectedQuantity: 2.0,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 6,
      transcript: 'Rice rendu kilo venum',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Rice',
      expectedQuantity: 2.0,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 7,
      transcript: 'Rice two kilos add pannunga',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Rice',
      expectedQuantity: 2.0,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 8,
      transcript: 'shopping list ku rice rendu kilo podu',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Rice',
      expectedQuantity: 2.0,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 9,
      transcript: 'ரெண்டு கிலோ அரிசி shopping list-ல add பண்ணு',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Rice',
      expectedQuantity: 2.0,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 10,
      transcript: 'இரண்டு கிலோ அரிசி சேர்க்கவும்',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Rice',
      expectedQuantity: 2.0,
      expectedUnit: 'kg',
    );

    // ─────────────────────────────────────────────────────────────
    // 11–20: Liquids, Fractions & Packaging Units
    // ─────────────────────────────────────────────────────────────
    testCommand(
      testNumber: 11,
      transcript: 'one litre oil add pannu',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Cooking Oil',
      expectedQuantity: 1.0,
      expectedUnit: 'L',
    );

    testCommand(
      testNumber: 12,
      transcript: 'oru litre oil add pannu',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Cooking Oil',
      expectedQuantity: 1.0,
      expectedUnit: 'L',
    );

    testCommand(
      testNumber: 13,
      transcript: 'எண்ணெய் ஒரு லிட்டர் சேர்க்கவும்',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Cooking Oil',
      expectedQuantity: 1.0,
      expectedUnit: 'L',
    );

    testCommand(
      testNumber: 14,
      transcript: 'arai kilo sugar add pannu',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Sugar',
      expectedQuantity: 0.5,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 15,
      transcript: 'half kilo sugar add pannu',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Sugar',
      expectedQuantity: 0.5,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 16,
      transcript: 'one and half kilo atta add pannu',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Atta',
      expectedQuantity: 1.5,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 17,
      transcript: 'onnara kilo atta shopping list la podu',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Atta',
      expectedQuantity: 1.5,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 18,
      transcript: 'rendara kilo toor dal add pannu',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Toor Dal',
      expectedQuantity: 2.5,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 19,
      transcript: 'milk rendu packet venum',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Milk',
      expectedQuantity: 2.0,
      expectedUnit: 'packet',
    );

    testCommand(
      testNumber: 20,
      transcript: 'egg 1 dozen add pannu',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Egg',
      expectedQuantity: 1.0,
      expectedUnit: 'dozen',
    );

    // ─────────────────────────────────────────────────────────────
    // 21–28: Different Word Orders & Natural Phrasing
    // ─────────────────────────────────────────────────────────────
    testCommand(
      testNumber: 21,
      transcript: 'rice 2 kilo add pannu',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Rice',
      expectedQuantity: 2.0,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 22,
      transcript: 'add 2 kilo rice',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Rice',
      expectedQuantity: 2.0,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 23,
      transcript: 'rice add pannu 2 kilo',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Rice',
      expectedQuantity: 2.0,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 24,
      transcript: 'shopping list la sugar add pannu',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Sugar',
      expectedQuantity: 1.0,
    );

    testCommand(
      testNumber: 25,
      transcript: 'curd 2 packet add pannunga',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Curd',
      expectedQuantity: 2.0,
      expectedUnit: 'packet',
    );

    testCommand(
      testNumber: 26,
      transcript: 'tea powder 250 g add pannu',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Tea',
      expectedQuantity: 250.0,
      expectedUnit: 'g',
    );

    testCommand(
      testNumber: 27,
      transcript: 'coffee powder 1 packet venum',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Coffee',
      expectedQuantity: 1.0,
      expectedUnit: 'packet',
    );

    testCommand(
      testNumber: 28,
      transcript: 'bread 1 packet vaanganum',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Bread',
      expectedQuantity: 1.0,
      expectedUnit: 'packet',
    );

    // ─────────────────────────────────────────────────────────────
    // 29–35: Shopping List Item Removal & Status Marking
    // ─────────────────────────────────────────────────────────────
    testCommand(
      testNumber: 29,
      transcript: 'rice remove pannu',
      expectedIntent: VoiceIntentType.removeShoppingItem,
      expectedProduct: 'Rice',
    );

    testCommand(
      testNumber: 30,
      transcript: '2 kilo rice remove pannu',
      expectedIntent: VoiceIntentType.removeShoppingItem,
      expectedProduct: 'Rice',
    );

    testCommand(
      testNumber: 31,
      transcript: 'remove sugar from shopping list',
      expectedIntent: VoiceIntentType.removeShoppingItem,
      expectedProduct: 'Sugar',
    );

    testCommand(
      testNumber: 32,
      transcript: 'sugar thooku',
      expectedIntent: VoiceIntentType.removeShoppingItem,
      expectedProduct: 'Sugar',
    );

    testCommand(
      testNumber: 33,
      transcript: 'rice bought',
      expectedIntent: VoiceIntentType.completeShoppingItem,
      expectedProduct: 'Rice',
    );

    testCommand(
      testNumber: 34,
      transcript: 'milk vaangiyachu',
      expectedIntent: VoiceIntentType.completeShoppingItem,
      expectedProduct: 'Milk',
    );

    testCommand(
      testNumber: 35,
      transcript: 'mark rice as bought',
      expectedIntent: VoiceIntentType.completeShoppingItem,
      expectedProduct: 'Rice',
    );

    // ─────────────────────────────────────────────────────────────
    // 36–42: Stock Operations (Stock In, Stock Out, Status Check)
    // ─────────────────────────────────────────────────────────────
    testCommand(
      testNumber: 36,
      transcript: 'rice stock la 2 kilo add pannu',
      expectedIntent: VoiceIntentType.stockIn,
      expectedProduct: 'Rice',
      expectedQuantity: 2.0,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 37,
      transcript: 'oil stock la 2 litre add pannu',
      expectedIntent: VoiceIntentType.stockIn,
      expectedProduct: 'Cooking Oil',
      expectedQuantity: 2.0,
      expectedUnit: 'L',
    );

    testCommand(
      testNumber: 38,
      transcript: '2 kilo rice stock la irundhu remove pannu',
      expectedIntent: VoiceIntentType.stockOut,
      expectedProduct: 'Rice',
      expectedQuantity: 2.0,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 39,
      transcript: 'used 500 ml oil',
      expectedIntent: VoiceIntentType.stockOut,
      expectedProduct: 'Cooking Oil',
      expectedQuantity: 500.0,
      expectedUnit: 'ml',
    );

    testCommand(
      testNumber: 40,
      transcript: 'oil 500 ml use panniten',
      expectedIntent: VoiceIntentType.stockOut,
      expectedProduct: 'Cooking Oil',
      expectedQuantity: 500.0,
      expectedUnit: 'ml',
    );

    testCommand(
      testNumber: 41,
      transcript: 'veetla rice evlo irukku?',
      expectedIntent: VoiceIntentType.getItemStatus,
      expectedProduct: 'Rice',
    );

    testCommand(
      testNumber: 42,
      transcript: 'வீட்டில் அரிசி எவ்வளவு இருக்கிறது?',
      expectedIntent: VoiceIntentType.getItemStatus,
      expectedProduct: 'Rice',
    );

    // ─────────────────────────────────────────────────────────────
    // 43–48: Smart Household Queries & Mode Transitions
    // ─────────────────────────────────────────────────────────────
    testCommand(
      testNumber: 43,
      transcript: 'shopping list kaatu',
      expectedIntent: VoiceIntentType.openShoppingList,
    );

    testCommand(
      testNumber: 44,
      transcript: 'enna items low stock la irukku?',
      expectedIntent: VoiceIntentType.getLowStockItems,
    );

    testCommand(
      testNumber: 45,
      transcript: 'enna items kammiya irukku?',
      expectedIntent: VoiceIntentType.getLowStockItems,
    );

    testCommand(
      testNumber: 46,
      transcript: 'enna vanganu?',
      expectedIntent: VoiceIntentType.whatDoINeed,
    );

    testCommand(
      testNumber: 47,
      transcript: 'rice cheapest enga?',
      expectedIntent: VoiceIntentType.smartPriceCheck,
      expectedProduct: 'Rice',
    );

    testCommand(
      testNumber: 48,
      transcript: 'shopping mode start pannu',
      expectedIntent: VoiceIntentType.startShoppingMode,
    );

    // ─────────────────────────────────────────────────────────────
    // 49–54: Edge Cases, Ambiguity, ASR Typos & Destructive Safeties
    // ─────────────────────────────────────────────────────────────
    testCommand(
      testNumber: 49,
      transcript: 'rice add pannu',
      context: inventoryContext, // Has Basmati Rice and Brown Rice!
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectAmbiguous: true,
      expectConfirmation: true,
    );

    testCommand(
      testNumber: 50,
      transcript: 'delete all shopping items',
      expectedIntent: VoiceIntentType.clearShoppingList,
      expectConfirmation: true, // Safety gate
    );

    testCommand(
      testNumber: 51,
      transcript: '50 kilo rice add pannu',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Rice',
      expectedQuantity: 50.0,
      expectConfirmation: true, // Large quantity gate
    );

    testCommand(
      testNumber: 52,
      transcript: '2 bottles rice add pannu',
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Rice',
      expectedQuantity: 2.0,
      expectConfirmation: true, // Incompatible unit gate
    );

    testCommand(
      testNumber: 53,
      transcript: 'rendu kilo arisii ad pannu', // ASR typo: arisii, ad
      expectedIntent: VoiceIntentType.addShoppingItem,
      expectedProduct: 'Rice',
      expectedQuantity: 2.0,
      expectedUnit: 'kg',
    );

    testCommand(
      testNumber: 54,
      transcript: 'milk stock out',
      expectedIntent: VoiceIntentType.getOutOfStockItems,
    );
  });

  group('Normalization & Parser Unit Subcomponents', () {
    test('NumberWords parses Tamil, Tanglish, and English spoken numerals', () {
      expect(NumberWords.lookup('rendu'), equals(2.0));
      expect(NumberWords.lookup('ஒன்று'), equals(1.0));
      expect(NumberWords.lookup('அரை'), equals(0.5));
      expect(NumberWords.lookup('half'), equals(0.5));
      expect(NumberWords.lookup('one and half'), equals(1.5));
      expect(NumberWords.lookup('rendara'), equals(2.5));
      expect(NumberWords.lookup('moonara'), equals(3.5));
      expect(NumberWords.lookup('pathu'), equals(10.0));
    });

    test('UnitDictionary normalizes variations to canonical units', () {
      expect(UnitDictionary.normalize('kilos'), equals('kg'));
      expect(UnitDictionary.normalize('கிலோ'), equals('kg'));
      expect(UnitDictionary.normalize('litru'), equals('L'));
      expect(UnitDictionary.normalize('லிட்டர்'), equals('L'));
      expect(UnitDictionary.normalize('pkts'), equals('packet'));
      expect(UnitDictionary.normalize('பாக்கெட்'), equals('packet'));
    });

    test('UnitDictionary rejects incompatible category units', () {
      expect(UnitDictionary.isCompatible('kg', 'Grains'), isTrue);
      expect(UnitDictionary.isCompatible('bottle', 'Grains'), isFalse);
      expect(UnitDictionary.isCompatible('L', 'Oils & Ghee'), isTrue);
      expect(UnitDictionary.isCompatible('bottle', 'Oils & Ghee'), isTrue);
    });

    test('QuantityParser parses compound fractions and decimals', () {
      final res1 = QuantityParser.parse('buy one and a half kilo sugar');
      expect(res1.quantity, equals(1.5));

      final res2 = QuantityParser.parse('rendara kilo dal');
      expect(res2.quantity, equals(2.5));

      final res3 = QuantityParser.parse('0.5 litre oil');
      expect(res3.quantity, equals(0.5));
    });

    test('CommandValidator auto-executes high confidence safe commands', () {
      final safeCmd = CommandParser.parse('2 kilo rice add pannu');
      final val = CommandValidator.validate(safeCmd);
      expect(val.isValid, isTrue);
      expect(val.canAutoExecute, isTrue);

      final dangerousCmd = CommandParser.parse('delete all shopping items');
      final dangerVal = CommandValidator.validate(dangerousCmd);
      expect(dangerVal.canAutoExecute, isFalse);
      expect(dangerVal.promptMessage, contains('Clear all items'));
    });
  });
}
