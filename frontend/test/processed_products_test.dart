import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/features/inventory/inventory_controller.dart';
import 'package:homestock/features/purchase/purchase_model.dart';
import 'package:homestock/features/shopping/processed_products_screen.dart';

class MockInventoryController extends StateNotifier<InventoryState>
    implements InventoryController {
  MockInventoryController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ProcessedProductsScreen Widget Tests', () {
    testWidgets('renders celebration banner, stats, and line items when just completed',
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
            ),
          ),
        ),
      );

      // Verify header & celebration
      expect(find.text('Restocked Products'), findsOneWidget);
      expect(find.text('3 items added to household pantry'), findsOneWidget);
      expect(find.text('Process Completed! 🎉'), findsOneWidget);
      expect(find.text('Reliance Fresh'), findsOneWidget);

      // Verify KPI metrics
      expect(find.text('Total Spent'), findsOneWidget);
      expect(find.text('₹450'), findsOneWidget);
      expect(find.text('Products Added'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Restocked in pantry'), findsOneWidget);

      // Verify line items
      expect(find.text('Aashirvaad Atta'), findsOneWidget);
      expect(find.text('+5 kg'), findsOneWidget);
      expect(find.text('Tata Salt'), findsOneWidget);
      expect(find.text('+2 kg'), findsOneWidget);
      expect(find.text('Fortune Sunflower Oil'), findsOneWidget);
      expect(find.text('+1 L'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Shopping List'), findsOneWidget);
      expect(find.text('View in Inventory'), findsOneWidget);
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

      // Verify header for historical view
      expect(find.text('Restocked Products'), findsOneWidget);
      expect(find.text('Restock Record'), findsOneWidget);
      expect(find.text('DMart'), findsOneWidget);
      expect(find.text('Parle-G Biscuits'), findsOneWidget);
      expect(find.text('+4 packs'), findsOneWidget);
      expect(find.text('Total Spent'), findsOneWidget);
      expect(find.text('₹120'), findsWidgets);
      expect(find.text('Products Added'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });
}
