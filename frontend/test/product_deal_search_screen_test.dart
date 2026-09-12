import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/network/api_client.dart';
import 'package:homestock/core/storage/secure_storage_service.dart';
import 'package:homestock/core/theme/app_theme.dart';
import 'package:homestock/features/home_switcher/home_controller.dart';
import 'package:homestock/features/home_switcher/home_model.dart';
import 'package:homestock/features/home_switcher/home_repository.dart';
import 'package:homestock/features/smart_shopping/deal_search_models.dart';
import 'package:homestock/features/smart_shopping/product_deal_controller.dart';
import 'package:homestock/features/smart_shopping/product_deal_repository.dart';
import 'package:homestock/features/smart_shopping/product_deal_search_screen.dart';

class MockHomeRepo extends HomeRepository {
  MockHomeRepo()
      : super(
          apiClient: ApiClient(secureStorage: SecureStorageService()),
          storage: SecureStorageService(),
        );
}

class MockHomeController extends HomeController {
  MockHomeController(HomeState initial)
      : super(MockHomeRepo(), SecureStorageService()) {
    state = initial;
  }
}

class FakeProductDealRepository implements ProductDealRepository {
  @override
  Future<ProductDealSearchResponse> searchDeals({
    required String homeId,
    String? query,
    String? barcode,
    String? brand,
    String? unit,
    String? subtype,
    String? filterBrand,
    String? filterPackSize,
    String sortBy = 'default',
  }) async {
    return _buildMockResponse(query ?? 'Oil');
  }

  @override
  Future<ProductDealSearchResponse> getItemDeals({
    required String homeId,
    required String itemId,
    String sortBy = 'default',
  }) async {
    return _buildMockResponse('Oil');
  }

  @override
  Future<bool> validateDeal(String dealId) async => true;

  ProductDealSearchResponse _buildMockResponse(String q) {
    const p1 = ProductDeal(
      id: 'DEAL-1',
      productName: 'Fortune Sunlite Refined Sunflower Oil',
      brand: 'Fortune',
      variantType: 'Sunflower',
      category: 'Cooking Oil',
      packageSize: '1 L',
      unit: 'L',
      bestPrice: 142.0,
      mrp: 155.0,
      discountPercent: 8.4,
      bestProvider: 'JioMart',
      unitPrice: 142.0,
      unitPriceLabel: '₹142.00/L',
      savingsVsHighest: 13.0,
      comparisonStore: 'Amazon',
      rating: 4.4,
      reviewCount: 18450,
      isLowestPrice: false,
      isBestValue: false,
      isPopular: true,
      storeOffers: [
        StoreOffer(
          storeName: 'JioMart',
          price: 142.0,
          estimatedDelivery: 'Tomorrow',
          availability: 'IN_STOCK',
        ),
        StoreOffer(
          storeName: 'BigBasket',
          price: 145.0,
          estimatedDelivery: 'Today evening',
          availability: 'IN_STOCK',
        ),
        StoreOffer(
          storeName: 'Blinkit',
          price: 149.0,
          deliveryFee: 15.0,
          estimatedDelivery: '12 mins',
          availability: 'IN_STOCK',
        ),
        StoreOffer(
          storeName: 'Amazon',
          price: 155.0,
          estimatedDelivery: 'Tomorrow',
          availability: 'IN_STOCK',
        ),
      ],
    );

    const p2 = ProductDeal(
      id: 'DEAL-2',
      productName: 'Fortune Sunlite Refined Sunflower Oil (Jar)',
      brand: 'Fortune',
      variantType: 'Sunflower',
      category: 'Cooking Oil',
      packageSize: '5 L',
      unit: 'L',
      bestPrice: 620.0,
      mrp: 649.0,
      bestProvider: 'JioMart',
      unitPrice: 124.0,
      unitPriceLabel: '₹124.00/L',
      savingsVsHighest: 29.0,
      comparisonStore: 'Amazon',
      rating: 4.5,
      reviewCount: 14200,
      isLowestPrice: false,
      isBestValue: true,
      isPopular: false,
      storeOffers: [
        StoreOffer(
          storeName: 'JioMart',
          price: 620.0,
          estimatedDelivery: 'Tomorrow',
        ),
      ],
    );

    const p3 = ProductDeal(
      id: 'DEAL-3',
      productName: 'Idhayam Gingelly Sesame Oil',
      brand: 'Idhayam',
      variantType: 'Sesame',
      category: 'Cooking Oil',
      packageSize: '500 ml',
      unit: 'ml',
      bestPrice: 135.0,
      mrp: 140.0,
      bestProvider: 'Blinkit',
      unitPrice: 270.0,
      unitPriceLabel: '₹270.00/L',
      rating: 4.7,
      reviewCount: 21000,
      isLowestPrice: true,
      isBestValue: false,
      isPopular: false,
      storeOffers: [
        StoreOffer(
          storeName: 'Blinkit',
          price: 135.0,
          estimatedDelivery: '10 mins',
        ),
      ],
    );

    return const ProductDealSearchResponse(
      intent: ProductSearchIntent(
        rawQuery: 'Oil',
        normalizedQuery: 'oil',
        searchMode: 'GENERIC_DISCOVERY',
        searchPriority: 'GENERIC_CATEGORY',
        primaryCategory: 'Cooking Oil',
        allowedTypes: ['Sunflower', 'Groundnut', 'Sesame', 'Coconut'],
      ),
      summary: DealSummary(
        totalProducts: 3,
        priceRangeMin: 135.0,
        priceRangeMax: 620.0,
        lowestPrice: 135.0,
        bestUnitValue: 124.0,
        bestUnitValueLabel: '₹124.00/L',
        aiRecommendation:
            'Showing 3 options for cooking oil. Bulk 5L jar offers the best value at ₹124/L. Lowest price is ₹135 on Blinkit.',
      ),
      highlights: DealHighlights(
        lowestPrice: p3,
        bestValue: p2,
        popular: p1,
      ),
      products: [p1, p2, p3],
      filters: DealFilters(
        availableTypes: [
          FilterOption(key: 'Sunflower', label: 'Sunflower', count: 2),
          FilterOption(key: 'Sesame', label: 'Sesame', count: 1),
        ],
        availableBrands: [
          FilterOption(key: 'Fortune', label: 'Fortune', count: 2),
          FilterOption(key: 'Idhayam', label: 'Idhayam', count: 1),
        ],
        availablePackSizes: [
          FilterOption(key: '1 L', label: '1 L', count: 1),
          FilterOption(key: '5 L', label: '5 L', count: 1),
          FilterOption(key: '500 ml', label: '500 ml', count: 1),
        ],
      ),
    );
  }
}

class FakeExactDealRepository implements ProductDealRepository {
  @override
  Future<ProductDealSearchResponse> searchDeals({
    required String homeId,
    String? query,
    String? barcode,
    String? brand,
    String? unit,
    String? subtype,
    String? filterBrand,
    String? filterPackSize,
    String sortBy = 'default',
  }) async {
    const p1 = ProductDeal(
      id: 'EXACT-1',
      productName: 'Fortune Sunlite Refined Sunflower Oil',
      brand: 'Fortune',
      variantType: 'Sunflower',
      category: 'Cooking Oil',
      packageSize: '1 L',
      unit: 'L',
      bestPrice: 142.0,
      mrp: 155.0,
      bestProvider: 'JioMart',
      unitPrice: 142.0,
      unitPriceLabel: '₹142.00/L',
      savingsVsHighest: 13.0,
      comparisonStore: 'Amazon',
      isExactMatch: true,
      matchConfidence: 0.98,
      storeOffers: [
        StoreOffer(storeName: 'JioMart', price: 142.0, estimatedDelivery: 'Tomorrow'),
        StoreOffer(storeName: 'BigBasket', price: 145.0, estimatedDelivery: 'Today evening'),
        StoreOffer(storeName: 'Blinkit', price: 149.0, deliveryFee: 15.0, estimatedDelivery: '12 mins'),
        StoreOffer(storeName: 'Amazon', price: 155.0, estimatedDelivery: 'Tomorrow'),
      ],
    );

    return const ProductDealSearchResponse(
      intent: ProductSearchIntent(
        rawQuery: 'Fortune Sunflower Refined Oil 1L',
        normalizedQuery: 'fortune sunflower refined oil 1l',
        searchMode: 'EXACT_PRODUCT',
        searchPriority: 'EXACT_PRODUCT_NAME',
        primaryCategory: 'Cooking Oil',
        extractedBrand: 'Fortune',
        extractedVariant: 'Sunflower',
        extractedPackSize: '1 L',
      ),
      summary: DealSummary(
        totalProducts: 1,
        priceRangeMin: 142.0,
        priceRangeMax: 155.0,
        lowestPrice: 142.0,
        aiRecommendation:
            'Found Fortune Sunlite Refined Sunflower Oil across 4 stores. JioMart currently offers the lowest price at ₹142 (saves ₹13 vs Amazon).',
      ),
      highlights: DealHighlights(lowestPrice: p1, bestValue: p1, popular: p1),
      products: [p1],
      filters: DealFilters(),
    );
  }

  @override
  Future<ProductDealSearchResponse> getItemDeals({
    required String homeId,
    required String itemId,
    String sortBy = 'default',
  }) async {
    return searchDeals(homeId: homeId);
  }

  @override
  Future<bool> validateDeal(String dealId) async => true;
}

void main() {
  testWidgets('ProductDealSearchScreen renders generic discovery view with AI insights, highlights and store prices',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeRepo = FakeProductDealRepository();
    final testHome = HomeModel(
      id: 'home-123',
      name: 'Valarmathi',
      inviteCode: 'VALAR123',
      currentUserRole: 'OWNER',
      memberCount: 3,
      createdAt: '2026-09-01T00:00:00Z',
    );

    final mockHomeCtrl = MockHomeController(
      HomeState(homes: [testHome], activeHome: testHome, isLoading: false),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productDealRepositoryProvider.overrideWithValue(fakeRepo),
          homeControllerProvider.overrideWith((ref) => mockHomeCtrl),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProductDealSearchScreen(initialQuery: 'Oil'),
        ),
      ),
    );

    // Initial pump & settle
    await tester.pumpAndSettle();

    // 1. Verify Header & Search input
    expect(find.text('Deals: Oil'), findsOneWidget);
    expect(find.text('Oil'), findsWidgets);

    // 2. Verify AI Insight Banner
    expect(find.text('GENERIC DISCOVERY: COOKING OIL'), findsOneWidget);
    expect(
        find.text(
            'Showing 3 options for cooking oil. Bulk 5L jar offers the best value at ₹124/L. Lowest price is ₹135 on Blinkit.'),
        findsOneWidget);
    expect(find.text('₹135 - ₹620'), findsOneWidget);

    // 3. Verify Highlight Cards
    expect(find.text('🏆 CHEAPEST'), findsOneWidget);
    expect(find.text('⭐ TOP VALUE'), findsOneWidget);
    expect(find.text('🔥 POPULAR'), findsWidgets);
    expect(find.text('₹124.00/L'), findsWidgets);

    // 4. Verify Filter Chips
    expect(find.text('Type: Sunflower (2)'), findsOneWidget);
    expect(find.text('Brand: Fortune (2)'), findsOneWidget);

    // 5. Verify Product Deals Cards
    expect(find.text('Fortune Sunlite Refined Sunflower Oil'), findsOneWidget);
    expect(find.text('Save ₹13 vs Amazon'), findsOneWidget);
    expect(find.text('View Deal at JioMart'), findsWidgets);

    // 6. Verify Cross-Store Availability
    expect(find.text('Cross-Store Availability:'), findsWidgets);
    expect(find.text('Tomorrow • '), findsWidgets);
  });

  testWidgets('ProductDealSearchScreen renders exact match mode with exact badge and store comparison',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeRepo = FakeExactDealRepository();
    final testHome = HomeModel(
      id: 'home-123',
      name: 'Valarmathi',
      inviteCode: 'VALAR123',
      currentUserRole: 'OWNER',
      memberCount: 3,
      createdAt: '2026-09-01T00:00:00Z',
    );

    final mockHomeCtrl = MockHomeController(
      HomeState(homes: [testHome], activeHome: testHome, isLoading: false),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productDealRepositoryProvider.overrideWithValue(fakeRepo),
          homeControllerProvider.overrideWith((ref) => mockHomeCtrl),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProductDealSearchScreen(
            initialQuery: 'Fortune Sunflower Refined Oil 1L',
            initialBrand: 'Fortune',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify EXACT PRODUCT MATCH badge
    expect(find.text('EXACT PRODUCT MATCH'), findsOneWidget);
    expect(find.text('Fortune Sunlite Refined Sunflower Oil'), findsOneWidget);
    expect(find.text('Save ₹13 vs Amazon'), findsOneWidget);
    expect(find.text('JioMart'), findsWidgets);
    expect(find.text('BigBasket'), findsWidgets);
    expect(find.text('Blinkit'), findsWidgets);
    expect(find.text('Amazon'), findsWidgets);
  });
}
