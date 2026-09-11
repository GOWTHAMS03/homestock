import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/theme/app_theme.dart';
import 'package:homestock/features/inventory/category_model.dart';
import 'package:homestock/features/inventory/inventory_controller.dart';
import 'package:homestock/features/inventory/inventory_model.dart';
import 'package:homestock/features/inventory/inventory_screen.dart';
import 'package:homestock/features/shopping/shopping_controller.dart';
import 'package:homestock/features/voice/widgets/voice_input_button.dart';

class MockInventoryController extends StateNotifier<InventoryState>
    implements InventoryController {
  MockInventoryController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockShoppingController extends StateNotifier<ShoppingState>
    implements ShoppingController {
  MockShoppingController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
      'InventoryScreen renders cleanly matching mockup design: header, pills, category tiles, staples, and cards',
      (WidgetTester tester) async {
    final item1 = InventoryItemModel(
      id: 'item-1',
      homeId: 'home-123',
      name: 'rice', // lowercase name in DB
      categoryName: 'Kitchen',
      categoryIcon: 'restaurant',
      categoryColor: '#F59E0B',
      quantity: 5.0,
      unit: 'pcs',
      minimumQuantity: 1.0,
      stockStatus: 'IN_STOCK',
      expiryStatus: 'SAFE',
    );

    // Categories with duplicate "Kitchen" to verify deduplication
    final duplicateCategories = <CategoryModel>[
      CategoryModel(
        id: 'cat-1',
        homeId: 'home-123',
        name: 'Kitchen',
        icon: 'restaurant',
        colorHex: '#F59E0B',
        displayOrder: 1,
      ),
      CategoryModel(
        id: 'default_kitchen_home-123',
        homeId: 'home-123',
        name: 'Kitchen',
        icon: 'restaurant',
        colorHex: '#F59E0B',
        displayOrder: 2,
      ),
      CategoryModel(
        id: 'cat-2',
        homeId: 'home-123',
        name: 'Cleaning',
        icon: 'cleaning_services',
        colorHex: '#3B82F6',
        displayOrder: 3,
      ),
    ];

    final mockController = MockInventoryController(
      InventoryState(
        items: [item1],
        categories: duplicateCategories,
        isLoading: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryControllerProvider.overrideWith((ref) => mockController),
          shoppingControllerProvider.overrideWith((ref) => MockShoppingController(const ShoppingState())),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const InventoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify item name is properly capitalized as "Rice" (not lowercase "rice")
    expect(find.text('Rice'), findsWidgets);

    // 2. Verify "Kitchen" category tile appears in category strip
    expect(find.text('Kitchen'), findsWidgets);
    expect(find.text('Cleaning'), findsWidgets);

    // 3. Verify title and dynamic subtitle
    expect(find.text('Household Inventory'), findsOneWidget);
    expect(find.textContaining('1 item tracked'), findsOneWidget);
    expect(find.textContaining('All stocked'), findsOneWidget);

    // 4. Verify search box is present with barcode and voice action
    expect(find.byIcon(Icons.qr_code_scanner_rounded), findsWidgets);
    expect(find.byType(VoiceInputButton), findsOneWidget);

    // 5. Verify the 3 status filter pills (All, Low Stock, Expiring)
    expect(find.text('All'), findsWidgets);
    expect(find.text('Low Stock'), findsOneWidget);
    expect(find.text('Expiring'), findsOneWidget);

    // 6. Verify Quick Add Staples suggestion card (650+ items, Explore)
    expect(find.text('Quick Add Staples'), findsOneWidget);
    expect(find.text('650+ items'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);

    // 7. Verify All Items section header
    expect(find.text('All Items (1)'), findsOneWidget);
    expect(find.text('Sort'), findsOneWidget);

    // 8. Verify floating Add Item button
    expect(find.text('Add Item'), findsOneWidget);
  });

  testWidgets(
      'Household Essentials modal matches mockup design: header, search, category chips, orange add button, and in-pantry cards',
      (WidgetTester tester) async {
    // Existing item in pantry: Eggs
    final eggItem = InventoryItemModel(
      id: 'item-egg',
      homeId: 'home-123',
      name: 'Eggs',
      categoryName: 'Dairy & Bakery',
      categoryIcon: 'egg',
      categoryColor: '#F59E0B',
      quantity: 12.0,
      unit: 'pcs',
      minimumQuantity: 6.0,
      stockStatus: 'IN_STOCK',
      expiryStatus: 'SAFE',
    );

    final mockController = MockInventoryController(
      InventoryState(
        items: [eggItem],
        categories: [],
        isLoading: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryControllerProvider.overrideWith((ref) => mockController),
          shoppingControllerProvider.overrideWith((ref) => MockShoppingController(const ShoppingState())),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const InventoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Open Household Essentials modal by tapping "Explore"
    final exploreButton = find.text('Explore');
    expect(exploreButton, findsOneWidget);
    await tester.tap(exploreButton);
    await tester.pumpAndSettle();

    // 2. Verify Header elements
    expect(find.text('Household Essentials'), findsOneWidget);
    expect(find.textContaining('Select suggested items for quick details'), findsOneWidget);
    expect(find.byIcon(Icons.bolt_rounded), findsWidgets);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // 3. Verify Search Bar
    expect(find.textContaining('Search 650+ essentials in English or தமிழ்...'), findsOneWidget);

    // 4. Verify Category Chips
    expect(find.text('All'), findsWidgets);
    expect(find.text('Dairy & Bakery'), findsWidgets);
    expect(find.text('Veg & Fruits'), findsWidgets);
    expect(find.text('Grains & Oils'), findsWidgets);

    // 5. Verify Not-In-Pantry item: Milk has orange "Add" button & Tamil badge "பால்"
    expect(find.text('Milk'), findsWidgets);
    expect(find.text('பால்'), findsWidgets);
    expect(find.text('Add'), findsWidgets);

    // 6. Verify In-Pantry item: Eggs has "In Pantry" badge and "+ List" button & Tamil badge "முட்டை"
    expect(find.text('Eggs'), findsWidgets);
    expect(find.text('முட்டை'), findsWidgets);
    expect(find.text('In Pantry'), findsWidgets);
    expect(find.text('+ List'), findsWidgets);
  });
}

