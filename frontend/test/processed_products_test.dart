import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/features/inventory/inventory_controller.dart';
import 'package:homestock/features/inventory/inventory_model.dart';
import 'package:homestock/features/purchase/purchase_model.dart';
import 'package:homestock/features/shopping/processed_products_screen.dart';

class MockInventoryController extends StateNotifier<InventoryState>
    implements InventoryController {
  MockInventoryController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ProcessedProductsScreen 10/10 Premium Restock Tests', () {
    testWidgets('renders contextual hero, summary KPIs, and line items when just completed',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final purchase = PurchaseModel(
        id: 'test-purchase-123',
        storeName: 'Reliance Fresh',
        recordedByName: 'Gowtham',
        purchaseDate: '2026-09-08T14:30:00.000',
        totalAmount: 450.0,
        currency: 'INR',
        items: [
          PurchaseItemModel(
            id: 'item-1',
            inventoryItemId: 'inv-1',
            itemName: 'Aashirvaad Atta',
            quantity: 5.0,
            unitPrice: 50.0,
            totalPrice: 250.0,
            unit: 'kg',
          ),
          PurchaseItemModel(
            id: 'item-2',
            inventoryItemId: 'inv-2',
            itemName: 'Tata Salt',
            quantity: 2.0,
            unitPrice: 25.0,
            totalPrice: 50.0,
            unit: 'kg',
          ),
          PurchaseItemModel(
            id: 'item-3',
            inventoryItemId: 'inv-3',
            itemName: 'Fortune Sunflower Oil',
            quantity: 1.0,
            unitPrice: 150.0,
            totalPrice: 150.0,
            unit: 'L',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryControllerProvider.overrideWith(
              (ref) => MockInventoryController(const InventoryState()),
            ),
          ],
          child: MaterialApp(
            home: ProcessedProductsScreen(
              purchase: purchase,
              isJustCompleted: true,
              source: 'Receipt Entry',
            ),
          ),
        ),
      );

      // Fast-forward animation controller (600ms)
      await tester.pump(const Duration(milliseconds: 700));

      // Verify app bar
      expect(find.text('Restocked Products'), findsOneWidget);
      expect(find.text('3 items added to household pantry'), findsOneWidget);

      // Verify ONE strong confirmation (No redundancy)
      expect(find.text('Restock completed'), findsOneWidget);
      expect(find.text('Your inventory has been updated'), findsOneWidget);
      expect(find.text('3 products added  •  ₹450 spent'), findsOneWidget);
      expect(find.text('Reliance Fresh'), findsOneWidget);

      // Verify KPI summary
      expect(find.text('Total spent'), findsOneWidget);
      expect(find.text('₹450'), findsWidgets);
      expect(find.text('Products added'), findsOneWidget);
      expect(find.text('3'), findsWidgets);

      // Verify line items
      expect(find.text('Aashirvaad Atta'), findsOneWidget);
      expect(find.text('Tata Salt'), findsOneWidget);
      expect(find.text('Fortune Sunflower Oil'), findsOneWidget);

      // Verify action buttons (Primary & Secondary)
      expect(find.text('View Inventory'), findsOneWidget);
      expect(find.text('Shopping List'), findsOneWidget);
    });

    testWidgets('renders historical receipt view when isJustCompleted is false',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final purchase = PurchaseModel(
        id: 'test-purchase-456',
        storeName: 'DMart',
        recordedByName: 'Gowtham',
        purchaseDate: '2026-09-07T10:00:00.000',
        totalAmount: 120.0,
        currency: 'INR',
        items: [
          PurchaseItemModel(
            id: 'item-1',
            inventoryItemId: 'inv-1',
            itemName: 'Parle-G Biscuits',
            quantity: 4.0,
            unitPrice: 30.0,
            totalPrice: 120.0,
            unit: 'packs',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryControllerProvider.overrideWith(
              (ref) => MockInventoryController(const InventoryState()),
            ),
          ],
          child: MaterialApp(
            home: ProcessedProductsScreen(
              purchase: purchase,
              isJustCompleted: false,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify header for historical view
      expect(find.text('Restocked Products'), findsOneWidget);
      expect(find.text('Restock record'), findsOneWidget);
      expect(find.text('Verified purchase and inventory record'), findsOneWidget);
      expect(find.text('DMart'), findsOneWidget);
      expect(find.text('Parle-G Biscuits'), findsOneWidget);
      expect(find.text('Total spent'), findsOneWidget);
      expect(find.text('₹120'), findsWidgets);
      expect(find.text('Product added'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('renders tangible Before -> After inventory value update',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Inventory currently has 4.5 L after 1.0 L was added
      final mockInvState = InventoryState(
        items: [
          InventoryItemModel(
            id: 'inv-milk-1',
            homeId: 'home-1',
            categoryName: 'Dairy',
            categoryIcon: 'milk',
            categoryColor: '#FFFFFF',
            name: 'Milk',
            quantity: 4.5,
            unit: 'L',
            minimumQuantity: 1.0,
            stockStatus: 'IN_STOCK',
            expiryStatus: 'GOOD',
          ),
        ],
      );

      final purchase = PurchaseModel(
        id: 'test-purchase-milk',
        storeName: 'Amul Fresh',
        recordedByName: 'Gowtham',
        purchaseDate: '2026-09-12T10:00:00.000',
        totalAmount: 50.0,
        currency: 'INR',
        items: [
          PurchaseItemModel(
            id: 'item-milk',
            inventoryItemId: 'inv-milk-1',
            itemName: 'Milk',
            quantity: 1.0,
            unitPrice: 50.0,
            totalPrice: 50.0,
            unit: 'L',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryControllerProvider.overrideWith(
              (ref) => MockInventoryController(mockInvState),
            ),
          ],
          child: MaterialApp(
            home: ProcessedProductsScreen(
              purchase: purchase,
              isJustCompleted: true,
              source: 'Receipt Entry',
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 700));

      // Verify product card and Before -> After inventory delta: 3.5 L -> 4.5 L
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Pantry balance: '), findsOneWidget);
      expect(find.text('3.5 L'), findsOneWidget);
      expect(find.text('4.5 L'), findsOneWidget);

      // Verify purchase details
      expect(find.text('Purchase details'), findsOneWidget);
      expect(find.text('Amul Fresh'), findsOneWidget);
      expect(find.text('Receipt scanned ✓ Verified'), findsOneWidget);

      // Verify smart inventory insight
      expect(find.text('Inventory updated'), findsOneWidget);
    });
  });
}
