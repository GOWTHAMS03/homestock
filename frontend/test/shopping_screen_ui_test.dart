import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/features/inventory/inventory_controller.dart';
import 'package:homestock/features/inventory/inventory_model.dart';
import 'package:homestock/features/shopping/shopping_controller.dart';
import 'package:homestock/features/shopping/shopping_model.dart';
import 'package:homestock/features/shopping/shopping_screen.dart';

class MockInventoryController extends StateNotifier<InventoryState>
    implements InventoryController {
  MockInventoryController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockShoppingController extends StateNotifier<ShoppingState>
    implements ShoppingController {
  MockShoppingController(super.state);

  String? lastAddedItemName;
  double? lastAddedQuantity;
  String? lastAddedUnit;

  @override
  Future<bool> addItem({
    String? inventoryItemId,
    required String itemName,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    required double quantity,
    String unit = 'pcs',
    String? notes,
  }) async {
    lastAddedItemName = itemName;
    lastAddedQuantity = quantity;
    lastAddedUnit = unit;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ShoppingScreen UI/UX Tests', () {
    testWidgets('renders all smart features when shopping list is empty without duplication',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockShoppingCtrl = MockShoppingController(
        ShoppingState(
          isLoading: false,
          list: ShoppingListModel(
            id: 'list-1',
            homeId: 'home-1',
            name: 'Shared Shopping List',
            isDefault: true,
            pendingCount: 0,
            completedCount: 0,
            items: const [],
          ),
        ),
      );

      final mockInventoryCtrl = MockInventoryController(
        const InventoryState(items: []),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingControllerProvider.overrideWith((ref) => mockShoppingCtrl),
            inventoryControllerProvider.overrideWith((ref) => mockInventoryCtrl),
          ],
          child: const MaterialApp(
            home: ShoppingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Check AppBar
      expect(find.text('Shopping List'), findsOneWidget);
      expect(find.text('0 items • Offline ready'), findsOneWidget);

      // 2. Check Unified Existing Search Bar
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search or add shopping items...'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);

      // 3. Check 3 Non-Redundant Feature Action Cards (Exact 1 instance each!)
      expect(find.text('Price Deals ⚡'), findsOneWidget);
      expect(find.text('Shop Mode'), findsOneWidget);
      expect(find.text('Restocked'), findsOneWidget);

      // 4. Check 1-Tap Household Essentials Carousel
      expect(find.text('Quick-Add Essentials (1-Tap)'), findsOneWidget);
      expect(find.text('1-Tap'), findsOneWidget);
      expect(find.textContaining('Milk'), findsWidgets);
      expect(find.textContaining('Eggs'), findsWidgets);

      // 5. Check Clean Empty Guide (No duplicate buttons) & FAB
      expect(find.text('Your Shopping List is Empty'), findsOneWidget);
      expect(find.text('100% Offline Ready • Changes saved locally'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('renders pantry low-stock suggestions with Restock All button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockShoppingCtrl = MockShoppingController(
        ShoppingState(
          isLoading: false,
          list: ShoppingListModel(
            id: 'list-1',
            homeId: 'home-1',
            name: 'Shared Shopping List',
            isDefault: true,
            pendingCount: 0,
            completedCount: 0,
            items: const [],
          ),
        ),
      );

      final lowStockItem = InventoryItemModel(
        id: 'inv-101',
        homeId: 'home-1',
        name: 'Cooking Oil',
        categoryId: 'cat-oils',
        categoryName: 'Oils',
        categoryIcon: 'oil_barrel',
        categoryColor: '#F59E0B',
        quantity: 0.2,
        unit: 'L',
        minimumQuantity: 1.0,
        stockStatus: 'LOW_STOCK',
        expiryStatus: 'SAFE',
      );

      final mockInventoryCtrl = MockInventoryController(
        InventoryState(items: [lowStockItem]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingControllerProvider.overrideWith((ref) => mockShoppingCtrl),
            inventoryControllerProvider.overrideWith((ref) => mockInventoryCtrl),
          ],
          child: const MaterialApp(
            home: ShoppingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Pantry Running Low section
      expect(find.text('Pantry Running Low'), findsOneWidget);
      expect(find.text('Restock All (1)'), findsOneWidget);
      expect(find.text('Cooking Oil'), findsOneWidget);
      expect(find.textContaining('Low stock'), findsOneWidget);

      // Tap Restock All
      await tester.tap(find.text('Restock All (1)'));
      await tester.pump();

      expect(mockShoppingCtrl.lastAddedItemName, 'Cooking Oil');
    });

    testWidgets('tapping quick staple adds it to the shopping list',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockShoppingCtrl = MockShoppingController(
        ShoppingState(
          isLoading: false,
          list: ShoppingListModel(
            id: 'list-1',
            homeId: 'home-1',
            name: 'Shared Shopping List',
            isDefault: true,
            pendingCount: 0,
            completedCount: 0,
            items: const [],
          ),
        ),
      );

      final mockInventoryCtrl = MockInventoryController(
        const InventoryState(items: []),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingControllerProvider.overrideWith((ref) => mockShoppingCtrl),
            inventoryControllerProvider.overrideWith((ref) => mockInventoryCtrl),
          ],
          child: const MaterialApp(
            home: ShoppingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Milk (1 L) staple
      final milkStapleFinder = find.text('Milk (1 L)');
      expect(milkStapleFinder, findsOneWidget);

      await tester.tap(milkStapleFinder);
      await tester.pump();

      expect(mockShoppingCtrl.lastAddedItemName, 'Milk');
      expect(mockShoppingCtrl.lastAddedQuantity, 1.0);
      expect(mockShoppingCtrl.lastAddedUnit, 'L');
    });

    testWidgets('renders active items with progress card and in-card steppers',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockShoppingCtrl = MockShoppingController(
        ShoppingState(
          isLoading: false,
          list: ShoppingListModel(
            id: 'list-1',
            homeId: 'home-1',
            name: 'Shared Shopping List',
            isDefault: true,
            pendingCount: 1,
            completedCount: 1,
            items: [
              ShoppingItemModel(
                id: 'item-1',
                shoppingListId: 'list-1',
                itemName: 'Basmati Rice',
                categoryIcon: 'category',
                categoryColor: '#F59E0B',
                quantity: 5.0,
                unit: 'kg',
                isCompleted: false,
                isAutoGenerated: false,
                addedByName: 'Gowtham',
              ),
              ShoppingItemModel(
                id: 'item-2',
                shoppingListId: 'list-1',
                itemName: 'Organic Milk',
                categoryIcon: 'category',
                categoryColor: '#3B82F6',
                quantity: 2.0,
                unit: 'L',
                isCompleted: true,
                isAutoGenerated: false,
                addedByName: 'Gowtham',
                completedByName: 'Gowtham',
              ),
            ],
          ),
        ),
      );

      final mockInventoryCtrl = MockInventoryController(
        const InventoryState(items: []),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shoppingControllerProvider.overrideWith((ref) => mockShoppingCtrl),
            inventoryControllerProvider.overrideWith((ref) => mockInventoryCtrl),
          ],
          child: const MaterialApp(
            home: ShoppingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Stats check
      expect(find.text('1 to buy'), findsWidgets);
      expect(find.text('50% Done'), findsOneWidget);
      expect(find.text('1 of 2 items checked off'), findsOneWidget);

      // Filter tabs check
      expect(find.text('All (2)'), findsOneWidget);
      expect(find.text('To Buy (1)'), findsOneWidget);
      expect(find.text('Done (1)'), findsOneWidget);

      // Items check
      expect(find.text('Basmati Rice'), findsOneWidget);
      expect(find.text('Organic Milk'), findsOneWidget);
      expect(find.text('Deals'), findsOneWidget);
    });
  });
}
