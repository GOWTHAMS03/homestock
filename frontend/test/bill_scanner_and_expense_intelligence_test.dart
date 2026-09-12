import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/theme/app_theme.dart';
import 'package:homestock/features/bill/controllers/bill_controller.dart';
import 'package:homestock/features/bill/models/bill_models.dart';
import 'package:homestock/features/bill/screens/bill_scanner_screen.dart';
import 'package:homestock/features/bill/screens/expense_intelligence_screen.dart';
import 'package:homestock/features/bill/services/bill_api_service.dart';

class MockBillApiService implements BillApiService {
  @override
  Future<BillScanResponseDto> scanBill(
    String homeId, {
    String? rawText,
    String? base64Image,
    List<String>? base64Images,
    String? storeName,
    DateTime? billDate,
  }) async {
    return const BillScanResponseDto(
      shopName: 'RELIANCE SMART BAZAAR',
      billNumber: 'REL-998822',
      billDate: '2026-09-12',
      totalAmount: 158.00,
      duplicateBillDetected: false,
      items: [
        BillItemCandidateDto(
          rawItemName: 'SUNFLOWER OIL 1L',
          normalizedItemName: 'Sunflower Oil',
          quantity: 1.0,
          unit: 'l',
          unitPrice: 130.00,
          finalPrice: 130.00,
          matchStatus: 'AUTO_MATCHED',
          matchConfidence: 98.0,
          matchedProductId: 'prod-oil-1',
          matchedExistingProductName: 'Sunflower Oil',
        ),
        BillItemCandidateDto(
          rawItemName: 'TATA SALT 1KG',
          normalizedItemName: 'Tata Salt',
          quantity: 1.0,
          unit: 'kg',
          unitPrice: 28.00,
          finalPrice: 28.00,
          matchStatus: 'NEW_PRODUCT',
          matchConfidence: 0.0,
          isNewProductCandidate: true,
        ),
      ],
    );
  }

  @override
  Future<BillResponseDto> confirmBill(String homeId, BillConfirmRequestDto request) async {
    return BillResponseDto(
      id: 'bill-conf-123',
      shopName: request.shopName ?? 'Store',
      billNumber: request.billNumber,
      billDate: request.billDate ?? '2026-09-12',
      totalAmount: request.totalAmount,
      itemCount: request.items.length,
      items: request.items
          .map((i) => BillItemResponseDto(
                id: 'item-1',
                rawItemName: i.rawItemName,
                normalizedItemName: i.newProductName ?? i.rawItemName,
                quantity: i.quantity,
                unit: i.unit,
                unitPrice: i.unitPrice,
                finalPrice: i.finalPrice,
              ))
          .toList(),
    );
  }

  @override
  Future<List<BillResponseDto>> getBills(String homeId, {int page = 0, int size = 20}) async {
    return [];
  }

  @override
  Future<BillResponseDto> getBillDetails(String homeId, String billId) async {
    return const BillResponseDto(
      id: 'bill-1',
      shopName: 'DMart',
      billDate: '2026-09-12',
      totalAmount: 250.0,
    );
  }

  @override
  Future<MonthlyExpenseReportDto> getMonthlyExpenseReport(String homeId, {int? year, int? month}) async {
    return const MonthlyExpenseReportDto(
      year: 2026,
      month: 9,
      totalSpend: 4250.50,
      previousMonthSpend: 3900.00,
      momPercentageChange: 8.99,
      totalBills: 6,
      totalItemsPurchased: 24,
      categoryBreakdown: [
        CategoryExpenseDto(category: 'Dairy & Eggs', totalSpend: 1200.00, percentageOfTotal: 28.2, itemCount: 8),
        CategoryExpenseDto(category: 'Staples & Oil', totalSpend: 2050.50, percentageOfTotal: 48.2, itemCount: 10),
      ],
      topRetailers: [
        TopRetailerDto(retailerName: 'DMart Ready', totalSpend: 2800.00, billCount: 3, percentageOfTotal: 65.9),
        TopRetailerDto(retailerName: 'Local Kirana', totalSpend: 1450.50, billCount: 3, percentageOfTotal: 34.1),
      ],
      priceAnomalies: [
        PriceAnomalyDto(
          productName: 'Sunflower Oil',
          category: 'Staples & Oil',
          currentPrice: 145.00,
          previousPrice: 125.00,
          percentageChange: 16.0,
          unit: 'l',
          alertType: 'PRICE_HIKE',
        ),
      ],
    );
  }

  @override
  Future<List<StoreComparisonDto>> getStoreComparison(String homeId) async {
    return const [
      StoreComparisonDto(storeName: 'DMart Ready', totalSpent: 2800.00, visitCount: 3, avgSpendPerVisit: 933.33),
    ];
  }

  @override
  Future<ProductPriceHistoryDto> getProductPriceHistory(String homeId, String productId) async {
    return const ProductPriceHistoryDto(
      productId: 'prod-oil-1',
      productName: 'Sunflower Oil',
      lowestPrice: 120.00,
      highestPrice: 145.00,
      currentPrice: 145.00,
    );
  }
}

void main() {
  group('Bill Models & Serialization', () {
    test('BillScanResponseDto parses complete receipt OCR payload', () {
      final json = {
        'shopName': 'DMART SUPERMARKET',
        'billNumber': 'DM-5544',
        'billDate': '2026-09-12',
        'totalAmount': 520.0,
        'duplicateBillDetected': true,
        'existingBillId': 'bill-old-1',
        'items': [
          {
            'rawItemName': 'FREEDOM SUNFLOWER 1L',
            'normalizedItemName': 'Freedom Sunflower Oil',
            'quantity': 2.0,
            'unit': 'l',
            'mrp': 150.0,
            'unitPrice': 130.0,
            'discount': 40.0,
            'tax': 0.0,
            'finalPrice': 260.0,
            'standardUnitPrice': 130.0,
            'matchConfidence': 96.5,
            'matchStatus': 'AUTO_MATCHED',
            'matchedProductId': 'prod-1',
            'matchedExistingProductName': 'Freedom Sunflower Oil',
            'isNewProductCandidate': false,
            'suggestedMatches': [],
          }
        ]
      };

      final dto = BillScanResponseDto.fromJson(json);
      expect(dto.shopName, 'DMART SUPERMARKET');
      expect(dto.billNumber, 'DM-5544');
      expect(dto.totalAmount, 520.0);
      expect(dto.duplicateBillDetected, true);
      expect(dto.items.length, 1);
      expect(dto.items.first.finalPrice, 260.0);
      expect(dto.items.first.matchStatus, 'AUTO_MATCHED');
    });

    test('MonthlyExpenseReportDto parses anomalies and categories correctly', () {
      final json = {
        'year': 2026,
        'month': 9,
        'totalSpend': 3450.0,
        'previousMonthSpend': 3000.0,
        'momPercentageChange': 15.0,
        'totalBills': 4,
        'totalItemsPurchased': 18,
        'categoryBreakdown': [
          {'category': 'Dairy', 'totalSpend': 900.0, 'percentageOfTotal': 26.08, 'itemCount': 5}
        ],
        'topRetailers': [
          {'retailerName': 'Reliance Fresh', 'totalSpend': 2000.0, 'billCount': 2, 'percentageOfTotal': 57.97}
        ],
        'priceAnomalies': [
          {
            'productName': 'Milk 500ml',
            'category': 'Dairy',
            'currentPrice': 32.0,
            'previousPrice': 28.0,
            'percentageChange': 14.28,
            'unit': 'pkt',
            'alertType': 'PRICE_HIKE',
          }
        ]
      };

      final report = MonthlyExpenseReportDto.fromJson(json);
      expect(report.totalSpend, 3450.0);
      expect(report.momPercentageChange, 15.0);
      expect(report.priceAnomalies.length, 1);
      expect(report.priceAnomalies.first.alertType, 'PRICE_HIKE');
      expect(report.priceAnomalies.first.percentageChange, closeTo(14.28, 0.01));
    });
  });

  group('BillScannerController Logic', () {
    late MockBillApiService mockService;
    late BillScannerController controller;

    setUp(() {
      mockService = MockBillApiService();
      controller = BillScannerController(mockService, 'test-home-id');
    });

    test('updateItem recalculates total bill amount', () {
      final initialItem1 = const BillItemCandidateDto(
        rawItemName: 'Item 1',
        normalizedItemName: 'Item 1',
        quantity: 1,
        unitPrice: 100,
        finalPrice: 100,
      );
      final initialItem2 = const BillItemCandidateDto(
        rawItemName: 'Item 2',
        normalizedItemName: 'Item 2',
        quantity: 1,
        unitPrice: 50,
        finalPrice: 50,
      );

      controller.state = controller.state.copyWith(
        editableItems: [initialItem1, initialItem2],
        totalAmount: 150,
      );

      final updatedItem1 = initialItem1.copyWith(quantity: 2, finalPrice: 200);
      controller.updateItem(0, updatedItem1);

      expect(controller.state.editableItems[0].finalPrice, 200);
      expect(controller.state.totalAmount, 250);
    });

    test('removeItem removes item and updates total amount', () {
      final item1 = const BillItemCandidateDto(
        rawItemName: 'Item 1',
        normalizedItemName: 'Item 1',
        quantity: 1,
        unitPrice: 100,
        finalPrice: 100,
      );
      final item2 = const BillItemCandidateDto(
        rawItemName: 'Item 2',
        normalizedItemName: 'Item 2',
        quantity: 1,
        unitPrice: 50,
        finalPrice: 50,
      );

      controller.state = controller.state.copyWith(
        editableItems: [item1, item2],
        totalAmount: 150,
      );

      controller.removeItem(1);
      expect(controller.state.editableItems.length, 1);
      expect(controller.state.totalAmount, 100);
    });

    test('assignMatch maps existing product and marks as AUTO_MATCHED', () {
      final item = const BillItemCandidateDto(
        rawItemName: 'SUGAR 1KG',
        normalizedItemName: 'Sugar',
        quantity: 1,
        unitPrice: 45,
        finalPrice: 45,
        matchStatus: 'SUGGESTED_MATCH',
        isNewProductCandidate: true,
      );

      controller.state = controller.state.copyWith(editableItems: [item]);

      const match = ExistingProductMatchDto(
        productId: 'sugar-prod-1',
        inventoryItemId: 'sugar-inv-1',
        productName: 'White Sugar',
        matchScore: 92.0,
      );

      controller.assignMatch(0, match);

      final updated = controller.state.editableItems.first;
      expect(updated.matchedProductId, 'sugar-prod-1');
      expect(updated.matchedInventoryItemId, 'sugar-inv-1');
      expect(updated.matchedExistingProductName, 'White Sugar');
      expect(updated.matchStatus, 'AUTO_MATCHED');
      expect(updated.isNewProductCandidate, false);
    });
  });

  group('Widget Tests', () {
    testWidgets('BillScannerScreen renders capture cards and title', (tester) async {
      final mockService = MockBillApiService();
      final scannerController = BillScannerController(mockService, 'home-123');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            billApiServiceProvider.overrideWithValue(mockService),
            billScannerControllerProvider.overrideWith((ref) => scannerController),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const BillScannerScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Smart Bill Scanner'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose Gallery'), findsOneWidget);
      expect(find.text('Paste Receipt Text Manually'), findsOneWidget);
    });

    testWidgets('ExpenseIntelligenceScreen renders KPI and categories', (tester) async {
      final mockService = MockBillApiService();
      final expenseController = ExpenseIntelligenceController(mockService, 'home-123');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            billApiServiceProvider.overrideWithValue(mockService),
            expenseIntelligenceControllerProvider.overrideWith((ref) => expenseController),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ExpenseIntelligenceScreen(),
          ),
        ),
      );

      // Pump to resolve the async loadData
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Expense Intelligence'), findsOneWidget);
      expect(find.text('Total Household Spend'), findsOneWidget);
      expect(find.text('4250.50'), findsOneWidget);
      expect(find.textContaining('vs last month'), findsOneWidget);
      expect(find.textContaining('Price Spike & Inflation Alerts'), findsOneWidget);
      expect(find.text('Sunflower Oil'), findsOneWidget);
      expect(find.text('Spending by Category'), findsOneWidget);
      expect(find.text('Top Retailers & Supermarkets'), findsOneWidget);
    });
  });
}
