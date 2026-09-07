import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/features/barcode/barcode_models.dart';
import 'package:homestock/features/barcode/barcode_normalization_service.dart';

void main() {
  late BarcodeNormalizationService normalizer;

  setUp(() {
    normalizer = BarcodeNormalizationService();
  });

  group('Barcode Normalization & Type Detection Tests', () {
    test('Normalizes spaces and dashes correctly', () {
      expect(normalizer.normalizeBarcode(' 890-103-000-0003 '), equals('8901030000003'));
      expect(normalizer.normalizeBarcode('012345 678905'), equals('012345678905'));
    });

    test('Identifies valid EAN-13 barcodes', () {
      // Tata Salt: 8901030000003
      expect(normalizer.detectBarcodeType('8901030000003'), equals(BarcodeFormatType.ean13));
      expect(normalizer.validateEan13Checksum('8901030000003'), isTrue);
      expect(normalizer.isValidBarcode('8901030000003'), isTrue);

      // Aashirvaad Atta: 8901725181222
      expect(normalizer.detectBarcodeType('8901725181222'), equals(BarcodeFormatType.ean13));
      expect(normalizer.validateEan13Checksum('8901725181222'), isTrue);

      // Fortune Sunlite Sunflower Oil: 8906007280013
      expect(normalizer.detectBarcodeType('8906007280013'), equals(BarcodeFormatType.ean13));
      expect(normalizer.validateEan13Checksum('8906007280013'), isTrue);

      // Invalid EAN-13 check digit
      expect(normalizer.validateEan13Checksum('8901030000004'), isFalse);
      expect(normalizer.isValidBarcode('8901030000004'), isFalse);
    });

    test('Identifies valid EAN-8 barcodes', () {
      // Valid EAN-8: 96385074
      expect(normalizer.detectBarcodeType('96385074'), equals(BarcodeFormatType.ean8));
      expect(normalizer.validateEan8Checksum('96385074'), isTrue);
      expect(normalizer.isValidBarcode('96385074'), isTrue);

      // Invalid EAN-8 check digit
      expect(normalizer.validateEan8Checksum('96385070'), isFalse);
      expect(normalizer.isValidBarcode('96385070'), isFalse);
    });

    test('Identifies valid UPC-A barcodes', () {
      // Valid UPC-A: 012345678905
      expect(normalizer.detectBarcodeType('012345678905'), equals(BarcodeFormatType.upcA));
      expect(normalizer.validateUpcAChecksum('012345678905'), isTrue);
      expect(normalizer.isValidBarcode('012345678905'), isTrue);

      // Invalid UPC-A check digit
      expect(normalizer.validateUpcAChecksum('012345678909'), isFalse);
      expect(normalizer.isValidBarcode('012345678909'), isFalse);
    });
  });

  group('Barcode Models Serialization & Deserialization Tests', () {
    test('ProductCatalogModel deserialization and serialization', () {
      final json = {
        'id': 'prod-001',
        'barcode': '8901030000003',
        'barcodeType': 'EAN_13',
        'name': 'Tata Salt Vacuum Evaporated',
        'normalizedName': 'tata salt vacuum evaporated',
        'brand': 'Tata',
        'categoryName': 'Pantry & Spices',
        'packageSize': 1.0,
        'unit': 'kg',
        'imageUrl': 'https://assets.homestock.app/tata_salt.png',
        'source': 'INTERNAL_CATALOG',
      };

      final product = ProductCatalogModel.fromJson(json);
      expect(product.id, equals('prod-001'));
      expect(product.barcode, equals('8901030000003'));
      expect(product.name, equals('Tata Salt Vacuum Evaporated'));
      expect(product.brand, equals('Tata'));
      expect(product.packageSize, equals(1.0));
      expect(product.unit, equals('kg'));
      expect(product.source, equals('INTERNAL_CATALOG'));

      final outJson = product.toJson();
      expect(outJson['barcode'], equals('8901030000003'));
      expect(outJson['name'], equals('Tata Salt Vacuum Evaporated'));
    });

    test('BarcodeLookupResult with existing inventory and shopping context', () {
      final json = {
        'barcode': '8901030000003',
        'found': true,
        'source': 'INTERNAL_CATALOG',
        'confidence': 1.0,
        'product': {
          'id': 'prod-001',
          'barcode': '8901030000003',
          'name': 'Tata Salt',
          'normalizedName': 'tata salt',
          'brand': 'Tata',
          'packageSize': 1.0,
          'unit': 'kg',
        },
        'existingInventory': {
          'id': 'inv-123',
          'name': 'Tata Salt',
          'currentQuantity': 0.5,
          'minimumQuantity': 1.0,
          'unit': 'kg',
          'storageLocation': 'Kitchen Cabinet',
        },
        'existingShopping': {
          'id': 'shop-456',
          'name': 'Tata Salt',
          'quantity': 1.0,
          'unit': 'kg',
          'isCompleted': false,
        },
      };

      final result = BarcodeLookupResult.fromJson(json);
      expect(result.barcode, equals('8901030000003'));
      expect(result.found, isTrue);
      expect(result.product?.name, equals('Tata Salt'));
      expect(result.existingInventory != null, isTrue);
      expect(result.existingInventory?.id, equals('inv-123'));
      expect(result.existingInventory?.currentQuantity, equals(0.5));
      expect(result.existingInventory?.minimumQuantity, equals(1.0));
      expect(result.existingShopping != null, isTrue);
      expect(result.existingShopping?.id, equals('shop-456'));
    });

    test('QuickScanSessionItem copyWith update', () {
      const item = QuickScanSessionItem(
        barcode: '8901030000003',
        name: 'Tata Salt',
        brand: 'Tata',
        quantity: 1.0,
        unit: 'kg',
      );

      expect(item.quantity, equals(1.0));
      final updated = item.copyWith(quantity: 3.0);
      expect(updated.quantity, equals(3.0));
      expect(updated.barcode, equals('8901030000003'));
      expect(updated.name, equals('Tata Salt'));
    });
  });
}
