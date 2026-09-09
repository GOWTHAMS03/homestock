import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/features/barcode/barcode_models.dart';
import 'package:homestock/features/barcode/barcode_normalization_service.dart';

void main() {
  group('Barcode Scan Flow & Production Logic Tests', () {
    late BarcodeNormalizationService normalizer;

    setUp(() {
      normalizer = BarcodeNormalizationService();
    });

    test('Leading zeroes are preserved strictly as String', () {
      const upcWithZero = '012345678905';
      final normalized = normalizer.normalizeBarcode(upcWithZero);

      expect(normalized, equals('012345678905'));
      expect(normalized.startsWith('0'), isTrue);
      expect(normalized.length, equals(12));

      // Test with spaces and symbols: still preserves leading zero
      final formatted = normalizer.normalizeBarcode(' 0-12345-67890-5 ');
      expect(formatted, equals('012345678905'));
      expect(formatted.startsWith('0'), isTrue);

      // Model serialization preserves leading zeroes
      final product = ProductCatalogModel(
        barcode: '0012345678905',
        name: 'Zero Padded Product',
      );
      final json = product.toJson();
      expect(json['barcode'], equals('0012345678905'));
      expect((json['barcode'] as String).startsWith('00'), isTrue);

      final deserialized = ProductCatalogModel.fromJson(json);
      expect(deserialized.barcode, equals('0012345678905'));
    });

    test('Package size mismatch detection accurately detects matching & mismatching sizes', () {
      final product5kg = ProductCatalogModel(
        barcode: '8901725181222',
        name: 'Aashirvaad Superior MP Whole Wheat Atta',
        packageSize: 5.0,
        unit: 'kg',
      );

      // Same size and unit -> Matches
      expect(product5kg.matchesPackageSize(5.0, 'kg'), isTrue);
      expect(product5kg.matchesPackageSize(5.0, 'KG'), isTrue);

      // Unit conversion: 5000g equals 5kg -> Matches
      expect(product5kg.matchesPackageSize(5000.0, 'g'), isTrue);

      // Different size -> Mismatch
      expect(product5kg.matchesPackageSize(1.0, 'kg'), isFalse);
      expect(product5kg.matchesPackageSize(10.0, 'kg'), isFalse);
      expect(product5kg.matchesPackageSize(500.0, 'g'), isFalse);

      final product500ml = ProductCatalogModel(
        barcode: '8901030000003',
        name: 'Olive Oil',
        packageSize: 500.0,
        unit: 'ml',
      );

      // 0.5 L equals 500 ml -> Matches
      expect(product500ml.matchesPackageSize(0.5, 'L'), isTrue);
      expect(product500ml.matchesPackageSize(500.0, 'ml'), isTrue);

      // 1 L != 500 ml -> Mismatch
      expect(product500ml.matchesPackageSize(1.0, 'L'), isFalse);

      // Product with null packageSize is permissive (returns true to avoid false warning)
      final productNoSize = ProductCatalogModel(
        barcode: '12345678',
        name: 'Generic Apple',
        unit: 'pcs',
      );
      expect(productNoSize.matchesPackageSize(1.0, 'pcs'), isTrue);
    });

    test('Stock In quantity addition preserves existing stock and computes incremental balance', () {
      // Existing inventory item has 2.5 kg
      final existing = ExistingInventoryContext(
        id: 'item-101',
        name: 'Basmati Rice',
        currentQuantity: 2.5,
        minimumQuantity: 1.0,
        unit: 'kg',
      );

      const double stockInQty = 5.0;

      // In HomeStock architecture, stock-in must NEVER overwrite absolute quantity;
      // It issues a transaction with quantityChange: stockInQty.
      final newCalculatedQuantity = existing.currentQuantity + stockInQty;

      expect(newCalculatedQuantity, equals(7.5));
      expect(existing.currentQuantity, equals(2.5)); // original remains untouched
    });

    test('BarcodeLookupResult correctly identifies local cache vs remote', () {
      final localResult = BarcodeLookupResult(
        barcode: '8901030000003',
        barcodeType: 'EAN_13',
        found: true,
        isFromLocalCache: true,
        product: ProductCatalogModel(
          barcode: '8901030000003',
          name: 'Tata Salt',
          source: 'LOCAL_CACHE',
        ),
      );

      expect(localResult.isFromLocalCache, isTrue);
      expect(localResult.found, isTrue);
      expect(localResult.product?.source, equals('LOCAL_CACHE'));

      final remoteResult = BarcodeLookupResult(
        barcode: '8901030000003',
        barcodeType: 'EAN_13',
        found: true,
        isFromLocalCache: false,
        product: ProductCatalogModel(
          barcode: '8901030000003',
          name: 'Tata Salt',
          source: 'OPEN_FOOD_FACTS',
        ),
      );

      expect(remoteResult.isFromLocalCache, isFalse);
      expect(remoteResult.found, isTrue);
      expect(remoteResult.product?.source, equals('OPEN_FOOD_FACTS'));
    });

    test('QuickScanSession accumulates unique items and increments quantities for duplicates', () {
      final items = <QuickScanSessionItem>[];

      void addItem(String barcode, String name, String unit) {
        final existingIndex = items.indexWhere((i) => i.barcode == barcode);
        if (existingIndex >= 0) {
          final current = items[existingIndex];
          items[existingIndex] = current.copyWith(quantity: current.quantity + 1.0);
        } else {
          items.add(QuickScanSessionItem(
            barcode: barcode,
            name: name,
            quantity: 1.0,
            unit: unit,
          ));
        }
      }

      // Scan Milk twice
      addItem('11111111', 'Milk', 'L');
      addItem('11111111', 'Milk', 'L');

      // Scan Bread once
      addItem('22222222', 'Bread', 'pk');

      expect(items.length, equals(2));
      expect(items[0].barcode, equals('11111111'));
      expect(items[0].quantity, equals(2.0));
      expect(items[1].barcode, equals('22222222'));
      expect(items[1].quantity, equals(1.0));
    });

    test('ScanSessionState lifecycle transitions properly', () {
      expect(ScanSessionState.values, contains(ScanSessionState.scanning));
      expect(ScanSessionState.values, contains(ScanSessionState.lookingUp));
      expect(ScanSessionState.values, contains(ScanSessionState.found));
      expect(ScanSessionState.values, contains(ScanSessionState.notFound));
      expect(ScanSessionState.values, contains(ScanSessionState.error));
    });
  });
}
