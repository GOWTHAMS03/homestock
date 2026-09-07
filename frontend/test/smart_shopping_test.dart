import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/features/smart_shopping/smart_shopping_models.dart';

void main() {
  group('SmartShopping Models Test', () {
    test('ProductOfferModel deserialization and computed properties', () {
      final json = {
        'provider': 'AMAZON',
        'providerProductId': 'B07X',
        'productName': 'Tata Salt, 1kg',
        'brand': 'Tata',
        'price': 25.0,
        'currency': 'INR',
        'deliveryCharge': 0.0,
        'effectivePrice': 25.0,
        'availability': 'IN_STOCK',
        'estimatedDelivery': 'Tomorrow, 2 PM',
        'rating': 4.5,
        'reviewCount': 1200,
        'matchConfidence': 0.95,
        'matchType': 'EXACT',
        'packageSize': '1',
        'unit': 'kg',
        'pricePerUnit': 25.0,
        'pricePerUnitLabel': '₹25.00/kg',
      };

      final offer = ProductOfferModel.fromJson(json);

      expect(offer.provider, equals('AMAZON'));
      expect(offer.productName, equals('Tata Salt, 1kg'));
      expect(offer.effectivePrice, equals(25.0));
      expect(offer.isFreeDelivery, isTrue);
      expect(offer.deliveryText, equals('Free delivery'));
      expect(offer.pricePerUnitLabel, equals('₹25.00/kg'));
    });

    test('PriceComparisonResult calculates bestOffer and savings correctly', () {
      final json = {
        'shoppingItem': {
          'id': 'item-1',
          'name': 'Tata Salt',
          'quantity': 1.0,
          'unit': 'kg',
        },
        'offers': [
          {
            'provider': 'FLIPKART',
            'providerProductId': 'FK-1',
            'productName': 'Tata Salt 1kg',
            'price': 22.0,
            'effectivePrice': 22.0,
          },
          {
            'provider': 'AMAZON',
            'providerProductId': 'AM-1',
            'productName': 'Tata Salt 1kg',
            'price': 28.0,
            'effectivePrice': 28.0,
          },
        ],
        'providerStatuses': {
          'FLIPKART': {'provider': 'FLIPKART', 'status': 'SUCCESS'},
          'AMAZON': {'provider': 'AMAZON', 'status': 'SUCCESS'},
        },
        'lastUpdated': '2026-09-07T12:00:00Z',
      };

      final result = PriceComparisonResult.fromJson(json);

      expect(result.offers.length, equals(2));
      expect(result.bestOffer, isNull);
      expect(result.offers.isNotEmpty, isTrue);
      expect(result.savingsLabel, equals('₹6 cheaper than the next option'));
      expect(result.successfulProviderCount, equals(2));
      expect(result.failedProviderCount, equals(0));
    });
  });
}
