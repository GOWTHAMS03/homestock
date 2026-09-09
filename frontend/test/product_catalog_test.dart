import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/constants/household_staples.dart';
import 'package:homestock/core/constants/product_icon_mapper.dart';
import 'package:homestock/core/models/product.dart';
import 'package:homestock/core/repositories/product_repository.dart';

void main() {
  group('Product Catalog JSON & Integrity Tests', () {
    late String jsonString;
    late List<dynamic> rawList;
    late List<Product> products;

    setUpAll(() {
      final file = File('assets/data/products.json');
      expect(file.existsSync(), isTrue, reason: 'assets/data/products.json must exist');
      jsonString = file.readAsStringSync();
      rawList = jsonDecode(jsonString) as List<dynamic>;
      products = rawList.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    });

    test('Catalog contains at least 2000 unique products', () {
      expect(products.length, greaterThanOrEqualTo(2000));
      expect(products.length, equals(2055));
    });

    test('All product IDs are unique snake_case slugs', () {
      final ids = <String>{};
      final slugRegex = RegExp(r'^[a-z0-9_]+$');

      for (final p in products) {
        expect(ids.contains(p.id), isFalse, reason: 'Duplicate ID: ${p.id}');
        ids.add(p.id);
        expect(slugRegex.hasMatch(p.id), isTrue, reason: 'Invalid slug: ${p.id}');
      }
    });

    test('All product names are unique case-insensitively', () {
      final names = <String>{};
      for (final p in products) {
        final lower = p.name.toLowerCase().trim();
        expect(names.contains(lower), isFalse, reason: 'Duplicate name: ${p.name}');
        names.add(lower);
      }
    });

    test('Every product has authentic Tamil script representation', () {
      final tamilRegex = RegExp(r'[\u0B80-\u0BFF]');
      for (final p in products) {
        expect(p.tamilName, isNotNull);
        expect(p.tamilName!.trim().isNotEmpty, isTrue, reason: 'Empty tamilName for ${p.id}');
        expect(tamilRegex.hasMatch(p.tamilName!), isTrue,
            reason: 'tamilName does not contain Tamil characters: "${p.tamilName}" for ${p.id}');
      }
    });

    test('All products have valid units and soldBy types', () {
      const allowedUnits = {'kg', 'g', 'l', 'ml', 'piece', 'pack', 'bunch', 'dozen', 'roll'};
      const allowedSoldBy = {'weight', 'volume', 'piece', 'package'};

      for (final p in products) {
        expect(allowedUnits.contains(p.defaultUnit.toLowerCase()), isTrue,
            reason: 'Invalid unit "${p.defaultUnit}" for ${p.id}');
        expect(allowedSoldBy.contains(p.soldBy.toLowerCase()), isTrue,
            reason: 'Invalid soldBy "${p.soldBy}" for ${p.id}');
        expect(p.minimumQuantity, greaterThan(0));
        expect(p.customQuantities, isNotEmpty);
      }
    });

    test('Zero fake or placeholder barcodes exist', () {
      for (final p in products) {
        for (final barcode in p.barcodes) {
          expect(barcode.startsWith('890') && barcode.length == 13, isTrue,
              reason: 'Fake barcode found: $barcode in ${p.id}');
        }
      }
    });
  });

  group('Product Model Tests', () {
    test('Product fromJson and toJson roundtrip', () {
      final jsonMap = {
        'id': 'test_rice_grain',
        'name': 'Test Rice Grain',
        'tamilName': 'டெஸ்ட் அரிசி',
        'category': 'Grains & Oils',
        'subCategory': 'Raw Rice',
        'productType': 'Grains',
        'defaultUnit': 'kg',
        'soldBy': 'weight',
        'storageLocation': 'Pantry Shelf',
        'minimumQuantity': 1.0,
        'customQuantities': [1.0, 5.0, 10.0],
        'commonNames': ['Test Arisi'],
        'aliases': ['Raw Test Rice'],
        'brands': ['Brand A', 'Brand B'],
        'barcodeSupport': true,
        'barcodeType': 'EAN_13',
        'barcodes': <String>[],
        'isLoose': true,
        'isPackaged': true,
        'iconKey': 'grain',
      };

      final product = Product.fromJson(jsonMap);
      expect(product.id, equals('test_rice_grain'));
      expect(product.name, equals('Test Rice Grain'));
      expect(product.tamilName, equals('டெஸ்ட் அரிசி'));
      expect(product.displayName, equals('Test Rice Grain (டெஸ்ட் அரிசி)'));
      expect(product.defaultUnit, equals('kg'));
      expect(product.soldBy, equals('weight'));
      expect(product.customQuantities, equals([1.0, 5.0, 10.0]));
      expect(product.brands, contains('Brand A'));
      expect(product.iconKey, equals('grain'));

      final outJson = product.toJson();
      expect(outJson['id'], equals('test_rice_grain'));
      expect(outJson['name'], equals('Test Rice Grain'));
      expect(outJson['tamilName'], equals('டெஸ்ட் அரிசி'));
    });

    test('toHouseholdStaple converts accurately', () {
      const product = Product(
        id: 'ponni_raw_rice',
        name: 'Ponni Raw Rice',
        tamilName: 'பொன்னி பச்சரிசி',
        category: 'Grains & Oils',
        subCategory: 'Raw Rice',
        defaultUnit: 'kg',
        soldBy: 'weight',
        storageLocation: 'Pantry Shelf',
        minimumQuantity: 1.0,
        customQuantities: [1.0, 5.0, 10.0, 25.0],
        commonNames: ['Ponni Arisi'],
        brands: ['BB Royal'],
        iconKey: 'grain',
      );

      final staple = product.toHouseholdStaple();
      expect(staple.name, equals('Ponni Raw Rice'));
      expect(staple.tamilName, equals('பொன்னி பச்சரிசி'));
      expect(staple.defaultUnit, equals('kg'));
      expect(staple.category, equals('Grains & Oils'));
      expect(staple.storageLocation, equals('Pantry Shelf'));
      expect(staple.customQuantities, equals([1.0, 5.0, 10.0, 25.0]));
      expect(staple.customBrands, equals(['BB Royal']));
      expect(staple.commonNames, equals(['Ponni Arisi']));
    });
  });

  group('ProductIconMapper Tests', () {
    test('Resolves known iconKeys correctly', () {
      expect(ProductIconMapper.getEmoji('grain'), equals('🌾'));
      expect(ProductIconMapper.getEmoji('oil'), equals('🫒'));
      expect(ProductIconMapper.getEmoji('dairy'), equals('🥛'));
      expect(ProductIconMapper.getEmoji('fruit'), equals('🍎'));
      expect(ProductIconMapper.getEmoji('vegetable'), equals('🥦'));
      expect(ProductIconMapper.getEmoji('cleaning'), equals('🧹'));
    });

    test('Returns graceful fallbacks for unknown iconKeys', () {
      expect(ProductIconMapper.getEmoji('unknown_xyz_key'), equals('📦'));
      expect(ProductIconMapper.getIcon('unknown_xyz_key'), isNotNull);
    });
  });

  group('ProductRepository Tests', () {
    late ProductRepository repository;

    setUpAll(() {
      final file = File('assets/data/products.json');
      final list = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      final products = list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      repository = ProductRepository(preloadProducts: products);
    });

    test('getAllProducts returns all 2055 products', () async {
      final all = await repository.getAllProducts();
      expect(all.length, equals(2055));
    });

    test('getProductById retrieves existing and handles missing', () async {
      final ponni = await repository.getProductById('rice_ponni_raw_rice');
      expect(ponni, isNotNull);
      expect(ponni!.name, equals('Ponni Raw Rice'));
      expect(ponni.tamilName, equals('பொன்னி பச்சரிசி'));

      final nonexistent = await repository.getProductById('non_existent_item_slug');
      expect(nonexistent, isNull);
    });

    test('getCategories returns distinct sorted categories', () async {
      final cats = await repository.getCategories();
      expect(cats, isNotEmpty);
      expect(cats, contains('Food & Grocery'));
      expect(cats, contains('Fresh Produce'));
    });

    test('getProductsByCategory returns products for category', () async {
      final grains = await repository.getProductsByCategory('Food & Grocery');
      expect(grains, isNotEmpty);
      for (final p in grains) {
        expect(p.category, equals('Food & Grocery'));
      }
    });

    test('searchProducts handles English query', () async {
      final results = await repository.searchProducts('Toor Dal');
      expect(results, isNotEmpty);
      expect(results.any((p) => p.name.toLowerCase().contains('toor')), isTrue);
    });

    test('searchProducts handles Tamil query', () async {
      final results = await repository.searchProducts('சீரக சம்பா');
      expect(results, isNotEmpty);
      expect(results.any((p) => p.tamilName != null && p.tamilName!.contains('சீரக சம்பா')), isTrue);
    });

    test('searchProducts handles Brand search', () async {
      final results = await repository.searchProducts('Aashirvaad');
      expect(results, isNotEmpty);
      expect(results.any((p) => p.brands.any((b) => b.toLowerCase().contains('aashirvaad'))), isTrue);
    });

    test('searchProducts handles Alias / Common name search', () async {
      final results = await repository.searchProducts('Pachari Ponni');
      expect(results, isNotEmpty);
      expect(results.any((p) => p.id == 'rice_ponni_raw_rice'), isTrue);
    });

    test('searchProducts with empty query returns all products', () async {
      final results = await repository.searchProducts('');
      expect(results.length, equals(2055));
    });
  });

  group('Backward Compatibility Tests', () {
    test('kMasterProductCatalogStaples has 2055 entries', () {
      expect(kMasterProductCatalogStaples.length, equals(2055));
    });

    test('kHouseholdStaples contains full catalog plus curated staples', () {
      expect(kHouseholdStaples.length, greaterThanOrEqualTo(2055));
    });

    test('findStapleForName resolves English staple names', () {
      final milk = findStapleForName('Milk');
      expect(milk, isNotNull);
      expect(milk!.name, equals('Milk'));

      final toorDal = findStapleForName('Toor Dal');
      expect(toorDal, isNotNull);
      expect(toorDal!.name, contains('Toor Dal'));
    });

    test('findStapleForName resolves Tamil script staple names', () {
      final milk = findStapleForName('பால்');
      expect(milk, isNotNull);
      expect(milk!.name, equals('Milk'));

      final ponni = findStapleForName('பொன்னி பச்சரிசி');
      expect(ponni, isNotNull);
      expect(ponni!.name, equals('Ponni Raw Rice'));
    });

    test('findStapleForName resolves aliases', () {
      final ponni = findStapleForName('Pachari Ponni');
      expect(ponni, isNotNull);
      expect(ponni!.name, equals('Ponni Raw Rice'));
    });
  });
}

