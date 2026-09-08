import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/features/inventory/consumption_model.dart';
import 'package:homestock/features/inventory/inventory_model.dart';
import 'package:homestock/features/inventory/smart_confirmation_sheet.dart';

void main() {
  group('Smart Consumption Engine - Human Quantity Display', () {
    test('Displays out of stock when quantity is 0 or status is OUT_OF_STOCK', () {
      final item = InventoryItemModel(
        id: '1',
        homeId: 'h1',
        name: 'Milk',
        quantity: 0.0,
        unit: 'L',
        minimumQuantity: 1.0,
        categoryName: 'Dairy',
        categoryIcon: 'local_drink',
        categoryColor: '#60A5FA',
        stockStatus: 'OUT_OF_STOCK',
        expiryStatus: 'SAFE',
      );
      expect(item.humanQuantityDisplay, 'Out of stock');
    });

    test('Displays verified qualitative status cleanly', () {
      final item = InventoryItemModel(
        id: '2',
        homeId: 'h1',
        name: 'Rice',
        quantity: 3.5,
        unit: 'kg',
        minimumQuantity: 1.0,
        categoryName: 'Grains',
        categoryIcon: 'rice_bowl',
        categoryColor: '#F59E0B',
        stockStatus: 'IN_STOCK',
        expiryStatus: 'SAFE',
        quantityStatus: 'ABOUT_HALF',
        quantitySource: 'VERIFIED',
      );
      expect(item.humanQuantityDisplay, 'About half');
    });

    test('Displays estimated days remaining when running low', () {
      final item = InventoryItemModel(
        id: '3',
        homeId: 'h1',
        name: 'Sunflower Oil',
        quantity: 0.8,
        unit: 'L',
        minimumQuantity: 1.0,
        categoryName: 'Oils',
        categoryIcon: 'opacity',
        categoryColor: '#FBBF24',
        stockStatus: 'LOW_STOCK',
        expiryStatus: 'SAFE',
        quantitySource: 'ESTIMATED',
        estimatedDaysRemaining: 4,
      );
      expect(item.humanQuantityDisplay, 'Likely enough for 3–5 days');
    });

    test('Avoids decimal spam for whole numbers', () {
      final item = InventoryItemModel(
        id: '4',
        homeId: 'h1',
        name: 'Eggs',
        quantity: 12.0,
        unit: 'pcs',
        minimumQuantity: 6.0,
        categoryName: 'Dairy',
        categoryIcon: 'egg',
        categoryColor: '#FBBF24',
        stockStatus: 'IN_STOCK',
        expiryStatus: 'SAFE',
        quantitySource: 'VERIFIED',
      );
      expect(item.humanQuantityDisplay, '12 pcs');
    });
  });

  group('Consumption Models Deserialization', () {
    test('ConsumptionProfileModel parses JSON correctly', () {
      final json = {
        'id': 'p1',
        'homeId': 'h1',
        'inventoryItemId': 'i1',
        'itemName': 'Basmati Rice',
        'averagePurchaseInterval': 24.5,
        'averageDailyConsumption': 0.208,
        'weightedDailyConsumption': 0.210,
        'unit': 'kg',
        'confidence': 'HIGH',
        'sampleCount': 4,
        'typicalRangeText': 'Purchased every 21–28 days',
      };

      final model = ConsumptionProfileModel.fromJson(json);
      expect(model.itemName, 'Basmati Rice');
      expect(model.averagePurchaseInterval, 24.5);
      expect(model.confidence, 'HIGH');
      expect(model.typicalRangeText, 'Purchased every 21–28 days');
    });

    test('HomeInsightModel and ReturnSummaryModel parse JSON correctly', () {
      final insightJson = {
        'homeId': 'h1',
        'primaryInsight': 'Rice consumption cycle: ~24 days',
        'bulletInsights': ['Coffee usage was slightly higher this week'],
        'weeklySpent': 1450.0,
      };

      final insight = HomeInsightModel.fromJson(insightJson);
      expect(insight.primaryInsight, contains('Rice'));
      expect(insight.insights.length, 2);

      final returnJson = {
        'greeting': 'Welcome back 👋',
        'subtitle': 'Nothing expired while you were away',
        'itemsLikelyLowCount': 1,
        'itemsExpiringCount': 0,
        'hasUpdates': true,
      };

      final ret = ReturnSummaryModel.fromJson(returnJson);
      expect(ret.hasAbsence, true);
      expect(ret.message, 'Nothing expired while you were away');
    });
  });

  group('SmartConfirmationSheet Widget', () {
    testWidgets('Renders qualitative buttons and 1-tap action buttons', (tester) async {
      final testItem = InventoryItemModel(
        id: 'test-1',
        homeId: 'h1',
        name: 'Tata Salt',
        quantity: 1.0,
        unit: 'kg',
        minimumQuantity: 1.0,
        categoryName: 'Spices',
        categoryIcon: 'rice_bowl',
        categoryColor: '#F59E0B',
        stockStatus: 'IN_STOCK',
        expiryStatus: 'SAFE',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SmartConfirmationSheet(item: testItem),
            ),
          ),
        ),
      );

      // Verify header and item name
      expect(find.text('Tata Salt'), findsOneWidget);
      expect(find.text('How is your stock at home right now?'), findsOneWidget);

      // Verify 6 qualitative levels
      expect(find.text('Almost Full'), findsOneWidget);
      expect(find.text('More than Half'), findsOneWidget);
      expect(find.text('About Half'), findsOneWidget);
      expect(find.text('Less than Half'), findsOneWidget);
      expect(find.text('Almost Empty'), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget);

      // Verify 1-tap quick actions
      expect(find.text('Still Have Enough'), findsOneWidget);
      expect(find.text('Add to Shopping'), findsOneWidget);
    });
  });
}
