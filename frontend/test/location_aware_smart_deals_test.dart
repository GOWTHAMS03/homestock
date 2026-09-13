import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/features/smart_shopping/location_deals_controller.dart';
import 'package:homestock/features/smart_shopping/location_deals_models.dart';
import 'package:homestock/features/smart_shopping/location_deals_repository.dart';
import 'package:homestock/features/smart_shopping/location_service.dart';
import 'package:homestock/features/smart_shopping/widgets/shop_radar_map_view.dart';

class FakeLocationDealsRepository extends Fake implements LocationDealsRepository {
  @override
  Future<List<NearbyShop>> getNearbyShops({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    bool forceRefresh = false,
  }) async {
    return [
      const NearbyShop(
        id: 'shop-salem-1',
        name: 'Salem Super Bazaar',
        shopType: 'SUPERMARKET',
        address: 'Bazaar Street, Fairlands',
        area: 'Fairlands',
        city: 'Salem',
        postalCode: '636016',
        latitude: 11.6643,
        longitude: 78.1460,
        distanceKm: 1.2,
        distanceLabel: '1.2 km away',
        rating: 4.5,
        reviewCount: 320,
        openingHours: '8:00 AM - 10:00 PM',
        isOpen: true,
        isVerified: true,
        availableDealsCount: 45,
      ),
      const NearbyShop(
        id: 'shop-mettur-1',
        name: 'Mettur Kavery Departmental Store',
        shopType: 'SUPERMARKET',
        address: 'Main Road',
        area: 'Mettur Dam',
        city: 'Mettur',
        postalCode: '636401',
        latitude: 11.7968,
        longitude: 77.8013,
        distanceKm: 0.8,
        distanceLabel: '0.8 km away',
        rating: 4.2,
        reviewCount: 110,
        openingHours: '7:30 AM - 9:30 PM',
        isOpen: true,
        isVerified: true,
        availableDealsCount: 28,
      ),
    ];
  }

  @override
  Future<VoiceDealResult?> voiceSearch({
    required String query,
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    return const VoiceDealResult(
      transcript: 'ennaiku ennai entha kadai la kammi?',
      detectedLanguage: 'TAMIL_TANGLISH',
      intent: 'FIND_CHEAPEST_DEAL',
      parsedProduct: 'Cooking Oil',
      parsedQuantity: 1.0,
      parsedUnit: 'L',
      conversationalReply: 'Mettur Kavery Departmental Store has cooking oil at ₹135/L (1.2 km away).',
      bestNearbyDeal: ShopDeal(
        id: 'deal-oil-1',
        shopId: 'shop-mettur-1',
        shopName: 'Mettur Kavery Departmental Store',
        shopType: 'SUPERMARKET',
        distanceKm: 1.2,
        distanceLabel: '1.2 km away',
        productName: 'Fortune Sunlite Sunflower Oil',
        price: 135.0,
        effectivePrice: 135.0,
        stockStatus: 'IN_STOCK',
        source: 'CONFIRMED_CATALOG',
        confidence: 'HIGH',
        freshnessStatus: 'LIVE',
        freshnessLabel: 'Verified today',
        isAvailable: true,
      ),
      otherDeals: [],
    );
  }
}

void main() {
  group('Location Context & Smart Deals Models', () {
    test('UserLocationContext has privacy-preserving detecting/unresolved states and labels', () {
      const detecting = UserLocationContext.detecting;
      expect(detecting.isResolved, isFalse);
      expect(detecting.displayLabel, 'Detecting Location...');

      const unresolved = UserLocationContext.unresolved;
      expect(unresolved.isResolved, isFalse);
      expect(unresolved.displayLabel, 'Choose Location');

      const customGps = UserLocationContext(
        latitude: 11.6643,
        longitude: 78.1460,
        approximateArea: 'Fairlands',
        city: 'Salem',
        isManual: false,
      );
      expect(customGps.isManual, isFalse);
      expect(customGps.isResolved, isTrue);
      expect(customGps.displayLabel, 'Fairlands, Salem');
    });

    test('NearbyShop parses JSON correctly and respects verification flags', () {
      final json = {
        'id': 'shop-101',
        'name': 'Shevapet Wholesale Provisions',
        'shopType': 'WHOLESALE',
        'address': 'Main Bazaar Road',
        'area': 'Shevapet',
        'city': 'Salem',
        'postalCode': '636002',
        'latitude': 11.6521,
        'longitude': 78.1388,
        'distanceKm': 2.4,
        'distanceLabel': '2.4 km away',
        'rating': 4.6,
        'reviewCount': 540,
        'openingHours': '9:00 AM - 8:00 PM',
        'isOpen': true,
        'isVerified': true,
        'availableDealsCount': 35,
        'estimatedBasketTotal': 1120.0,
      };

      final shop = NearbyShop.fromJson(json);
      expect(shop.id, 'shop-101');
      expect(shop.name, 'Shevapet Wholesale Provisions');
      expect(shop.shopType, 'WHOLESALE');
      expect(shop.distanceKm, 2.4);
      expect(shop.isVerified, isTrue);
      expect(shop.estimatedBasketTotal, 1120.0);
    });

    test('ShopDeal parses historical bill benchmarks without fabricating prices', () {
      final json = {
        'id': 'deal-202',
        'shopId': 'shop-101',
        'shopName': 'Shevapet Wholesale Provisions',
        'shopType': 'WHOLESALE',
        'distanceKm': 2.4,
        'distanceLabel': '2.4 km',
        'productName': 'Ponni Boiled Rice 25kg',
        'brand': 'Royal Ponni',
        'packageSize': 25.0,
        'unit': 'kg',
        'price': 1350.0,
        'mrp': 1500.0,
        'effectivePrice': 1350.0,
        'pricePerUnit': 54.0,
        'pricePerUnitLabel': '₹54/kg',
        'stockStatus': 'IN_STOCK',
        'source': 'CONFIRMED_CATALOG',
        'confidence': 'HIGH',
        'freshnessStatus': 'LIVE',
        'freshnessLabel': 'Verified today',
        'isAvailable': true,
        'userPreviousPrice': 1420.0,
        'priceComparisonNote': '₹70 cheaper than your scanned bill on 12 Sep',
      };

      final deal = ShopDeal.fromJson(json);
      expect(deal.productName, 'Ponni Boiled Rice 25kg');
      expect(deal.pricePerUnit, 54.0);
      expect(deal.pricePerUnitLabel, '₹54/kg');
      expect(deal.userPreviousPrice, 1420.0);
      expect(deal.priceComparisonNote, contains('12 Sep'));
      expect(deal.isAvailable, isTrue);
    });

    test('BasketOptimizationResult parses single-store vs split savings options', () {
      final json = {
        'totalItems': 3,
        'availableItems': 3,
        'tradeOffExplanation': 'Save ₹65 by splitting items across 2 shops (1.4 km extra).',
        'geminiAiRecommendation': 'Buy staples at Salem Super Bazaar for single-trip convenience.',
        'bestSingleStoreOption': {
          'optionType': 'SINGLE_STORE',
          'title': 'Single Store Convenience',
          'subtitle': 'All 3 items available at 1 shop',
          'storeNames': ['Salem Super Bazaar'],
          'storeCount': 1,
          'basketItemsTotal': 620.0,
          'estimatedDeliveryOrTravelCost': 15.0,
          'effectiveGrandTotal': 635.0,
          'potentialSavings': 0.0,
          'totalTravelDistanceKm': 1.2,
          'assignments': [],
        },
        'maximumSavingsOption': {
          'optionType': 'MAX_SAVINGS_SPLIT',
          'title': 'Maximum Savings',
          'subtitle': 'Split across 2 nearby stores',
          'storeNames': ['Salem Super Bazaar', 'Shevapet Provisions'],
          'storeCount': 2,
          'basketItemsTotal': 555.0,
          'estimatedDeliveryOrTravelCost': 25.0,
          'effectiveGrandTotal': 580.0,
          'potentialSavings': 55.0,
          'totalTravelDistanceKm': 2.6,
          'assignments': [],
        },
        'itemComparisons': [],
      };

      final result = BasketOptimizationResult.fromJson(json);
      expect(result.totalItems, 3);
      expect(result.bestSingleStoreOption, isNotNull);
      expect(result.bestSingleStoreOption!.effectiveGrandTotal, 635.0);
      expect(result.maximumSavingsOption, isNotNull);
      expect(result.maximumSavingsOption!.effectiveGrandTotal, 580.0);
      expect(result.maximumSavingsOption!.potentialSavings, 55.0);
      expect(result.geminiAiRecommendation, contains('Salem Super Bazaar'));
    });
  });

  group('LocationDealsController State & Actions', () {
    test('Initializes with location and loads nearby shops', () async {
      final fakeRepo = FakeLocationDealsRepository();
      final controller = LocationDealsController(
        fakeRepo,
        initialLocation: const UserLocationContext(
          latitude: 11.6643,
          longitude: 78.1460,
          approximateArea: 'Fairlands',
          city: 'Salem',
          isManual: false,
        ),
      );

      expect(controller.state.location.city, 'Salem');
      expect(controller.state.radiusKm, 5.0);
      expect(controller.state.viewMode, DealsViewMode.list);

      // Wait for initial loadNearbyShops
      await pumpEventQueue();

      expect(controller.state.nearbyShops.length, 2);
      expect(controller.state.nearbyShops.first.name, 'Salem Super Bazaar');

      // Test radius change
      controller.setRadius(10.0);
      expect(controller.state.radiusKm, 10.0);

      // Test view mode toggle
      controller.setViewMode(DealsViewMode.map);
      expect(controller.state.viewMode, DealsViewMode.map);

      // Test voice search
      await controller.searchVoice('ennaiku ennai entha kadai la kammi?');
      expect(controller.state.voiceResult, isNotNull);
      expect(controller.state.voiceResult!.intent, 'FIND_CHEAPEST_DEAL');
      expect(controller.state.voiceResult!.bestNearbyDeal?.effectivePrice, 135.0);

      controller.clearVoiceResult();
      expect(controller.state.voiceResult, isNull);
    });

    test('Can update and switch to real live location (Kolathur) dynamically', () async {
      final fakeRepo = FakeLocationDealsRepository();
      final controller = LocationDealsController(fakeRepo);

      // Simulate live location resolution to Kolathur (11.8486, 77.7512, 636303)
      const liveContext = UserLocationContext(
        latitude: 11.8486,
        longitude: 77.7512,
        approximateArea: 'Kolathur',
        city: 'Kulattur',
        postalCode: '636303',
        isManual: false,
      );

      controller.setLocation(liveContext);

      expect(controller.state.location.latitude, 11.8486);
      expect(controller.state.location.longitude, 77.7512);
      expect(controller.state.location.approximateArea, 'Kolathur');
      expect(controller.state.location.city, 'Kulattur');
      expect(controller.state.location.postalCode, '636303');
      expect(controller.state.location.displayLabel, 'Kolathur, Kulattur');
    });
  });

  group('ShopRadarMapView Widget Tests', () {
    testWidgets('Renders radar rings, shop markers, and shop preview cards', (tester) async {
      final shops = [
        const NearbyShop(
          id: 'shop-1',
          name: 'Salem Super Bazaar',
          shopType: 'SUPERMARKET',
          address: 'Fairlands Main Road',
          area: 'Fairlands',
          city: 'Salem',
          postalCode: '636016',
          latitude: 11.6643,
          longitude: 78.1460,
          distanceKm: 1.2,
          distanceLabel: '1.2 km away',
          rating: 4.5,
          reviewCount: 320,
          openingHours: '8:00 AM - 10:00 PM',
          isOpen: true,
          isVerified: true,
          availableDealsCount: 45,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShopRadarMapView(
              shops: shops,
              radiusKm: 5.0,
              locationLabel: 'Fairlands, Salem',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Header Texts
      expect(find.text('1 Shops near Fairlands, Salem'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);

      // Check Shop Details Card
      expect(find.text('Salem Super Bazaar'), findsOneWidget);
      expect(find.textContaining('1.2 km away'), findsOneWidget);
      expect(find.text('Directions'), findsOneWidget);
      expect(find.text('View Deals'), findsOneWidget);
    });
  });
}
