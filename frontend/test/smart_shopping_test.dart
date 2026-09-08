import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/features/smart_shopping/smart_shopping_models.dart';

void main() {
  group('Smart Shopping Models & Basket Optimization', () {
    test('BasketComparisonResult parses JSON correctly with options and duplicate warnings', () {
      final json = {
        'options': [
          {
            'optionType': 'OPTION_A_INDIVIDUAL_BEST',
            'title': 'Lowest Price Items (Split Basket)',
            'storeName': 'Split (2 Stores)',
            'itemsSubtotal': 320.0,
            'deliveryFeesTotal': 40.0,
            'netTotal': 360.0,
            'potentialSavings': 50.0,
            'recommendationReason': 'Saves ₹50 net by splitting items across stores.',
            'items': [
              {
                'shoppingItemId': 'item-1',
                'itemName': 'India Gate Basmati Rice',
                'quantity': 1.0,
                'unit': 'kg',
                'provider': 'Amazon',
                'providerProductId': 'B001',
                'productTitle': 'India Gate Basmati Rice 1kg',
                'price': 140.0,
                'deliveryCharge': 0.0,
                'effectivePrice': 140.0,
                'pricePerUnit': 140.0,
                'pricePerUnitLabel': '₹140/kg',
                'matchType': 'EXACT',
                'matchConfidence': 0.98,
                'freshness': 'FRESH',
              },
              {
                'shoppingItemId': 'item-2',
                'itemName': 'Fortune Sunflower Oil',
                'quantity': 1.0,
                'unit': 'L',
                'provider': 'Flipkart',
                'providerProductId': 'F001',
                'productTitle': 'Fortune Sunflower Oil 1L',
                'price': 180.0,
                'deliveryCharge': 40.0,
                'effectivePrice': 220.0,
                'matchType': 'EXACT',
                'matchConfidence': 0.95,
                'freshness': 'FRESH',
              }
            ]
          },
          {
            'optionType': 'OPTION_B_SINGLE_STORE',
            'title': 'Single Store Convenience (Amazon)',
            'storeName': 'Amazon',
            'itemsSubtotal': 370.0,
            'deliveryFeesTotal': 40.0,
            'netTotal': 410.0,
            'potentialSavings': 0.0,
            'recommendationReason': 'Amazon is ₹50 more and lets you buy everything in one delivery.',
            'items': [
              {
                'shoppingItemId': 'item-1',
                'itemName': 'India Gate Basmati Rice',
                'quantity': 1.0,
                'unit': 'kg',
                'provider': 'Amazon',
                'price': 140.0,
                'effectivePrice': 140.0,
              },
              {
                'shoppingItemId': 'item-2',
                'itemName': 'Fortune Sunflower Oil',
                'quantity': 1.0,
                'unit': 'L',
                'provider': 'Amazon',
                'price': 230.0,
                'effectivePrice': 230.0,
              }
            ]
          }
        ],
        'recommendedOption': {
          'optionType': 'OPTION_A_INDIVIDUAL_BEST',
          'title': 'Lowest Price Items (Split Basket)',
          'storeName': 'Split (2 Stores)',
          'itemsSubtotal': 320.0,
          'deliveryFeesTotal': 40.0,
          'netTotal': 360.0,
          'potentialSavings': 50.0,
          'items': []
        },
        'duplicateWarnings': [
          {
            'shoppingItemId': 'item-1',
            'itemName': 'India Gate Basmati Rice',
            'existingStockQuantity': 4.0,
            'existingStockUnit': 'kg',
            'estimatedDaysRemaining': 18.0,
            'message': 'You already have about 4kg Rice at home (enough for ~18 days).'
          }
        ],
        'calculatedAt': '2026-09-08T10:00:00Z'
      };

      final result = BasketComparisonResult.fromJson(json);

      expect(result.options.length, 2);
      expect(result.options[0].isSplit, isTrue);
      expect(result.options[0].netTotal, 360.0);
      expect(result.options[1].isSingleStore, isTrue);
      expect(result.options[1].netTotal, 410.0);

      expect(result.recommendedOption?.optionType, 'OPTION_A_INDIVIDUAL_BEST');
      expect(result.duplicateWarnings.length, 1);
      expect(result.duplicateWarnings[0].estimatedDaysRemaining, 18.0);
      expect(result.duplicateWarnings[0].message, contains('4kg Rice'));
    });

    test('ProviderCapabilityModel correctly identifies capabilities', () {
      final json = {
        'name': 'Amazon',
        'displayName': 'Amazon Fresh',
        'enabled': true,
        'capabilities': ['SEARCH', 'PRICE', 'DEEP_LINK', 'AFFILIATE_LINK']
      };

      final provider = ProviderCapabilityModel.fromJson(json);

      expect(provider.enabled, isTrue);
      expect(provider.canDeepLink, isTrue);
      expect(provider.canAffiliateLink, isTrue);
      expect(provider.canMultiItemCart, isFalse);
    });

    test('ShoppingSessionModel parses JSON correctly', () {
      final json = {
        'id': 'session-123',
        'homeId': 'home-456',
        'userId': 'user-789',
        'startedAt': '2026-09-08T10:00:00Z',
        'status': 'COMPLETED',
        'selectedProviders': 'Amazon',
        'estimatedTotal': 500.0,
        'actualTotal': 480.0,
        'potentialSavings': 20.0,
      };

      final session = ShoppingSessionModel.fromJson(json);

      expect(session.id, 'session-123');
      expect(session.status, 'COMPLETED');
      expect(session.potentialSavings, 20.0);
      expect(session.actualTotal, 480.0);
    });
  });
}
