import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/theme/app_theme.dart';
import 'package:homestock/features/inventory/category_model.dart';
import 'package:homestock/features/inventory/inventory_controller.dart';
import 'package:homestock/features/inventory/inventory_model.dart';
import 'package:homestock/features/inventory/inventory_screen.dart';
import 'package:homestock/features/voice/widgets/voice_input_button.dart';

class MockInventoryController extends StateNotifier<InventoryState>
    implements InventoryController {
  MockInventoryController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
      'InventoryScreen renders cleanly, capitalizes items, deduplicates categories, and has no repeated voice icon',
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
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const InventoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify item name is properly capitalized as "Rice" (not lowercase "rice")
    expect(find.text('Rice'), findsOneWidget);

    // 2. Verify "Kitchen" category chip appears EXACTLY once in the category strip (deduplicated)
    final horizontalCategoryStrip = find.byType(ListView).at(1);
    expect(find.descendant(of: horizontalCategoryStrip, matching: find.text('Kitchen')), findsOneWidget);
    expect(find.descendant(of: horizontalCategoryStrip, matching: find.text('Cleaning')), findsOneWidget);
    expect(find.text('All Categories'), findsOneWidget);

    // 3. Verify title and dynamic subtitle
    expect(find.text('Household Inventory'), findsOneWidget);
    expect(find.text('1 item tracked • All stocked'), findsOneWidget);

    // 4. Verify search box is present with barcode and voice action (only 1 on the screen, not repeated)
    expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    expect(find.byType(VoiceInputButton), findsOneWidget);
  });
}
