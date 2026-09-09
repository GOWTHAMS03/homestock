import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/constants/household_staples.dart';
import 'package:homestock/core/database/app_database.dart';
import 'package:homestock/core/database/daos/inventory_dao.dart';
import 'package:homestock/core/database/daos/shopping_dao.dart';
import 'package:homestock/core/database/daos/sync_dao.dart';
import 'package:homestock/core/network/api_client.dart';
import 'package:homestock/core/storage/secure_storage_service.dart';
import 'package:homestock/core/sync/connectivity_monitor.dart';
import 'package:homestock/core/sync/sync_engine.dart';
import 'package:homestock/features/inventory/inventory_repository.dart';
import 'package:homestock/features/shopping/shopping_repository.dart';

void main() {
  late AppDatabase db;
  late ShoppingDao shoppingDao;
  late InventoryDao inventoryDao;
  late SyncDao syncDao;
  late ConnectivityMonitor connectivity;
  late SyncEngine syncEngine;
  late ShoppingRepository shoppingRepo;
  late InventoryRepository inventoryRepo;

  const testHomeId = 'home-essentials-test-123';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    shoppingDao = ShoppingDao(db);
    inventoryDao = InventoryDao(db);
    syncDao = SyncDao(db);
    connectivity = ConnectivityMonitor();
    final storage = SecureStorageService();
    final apiClient = ApiClient(secureStorage: storage);

    syncEngine = SyncEngine(
      database: db,
      apiClient: apiClient,
      connectivity: connectivity,
    );

    shoppingRepo = ShoppingRepository(
      shoppingDao: shoppingDao,
      syncDao: syncDao,
      apiClient: apiClient,
      syncEngine: syncEngine,
      connectivity: connectivity,
      inventoryDao: inventoryDao,
    );

    inventoryRepo = InventoryRepository(
      inventoryDao: inventoryDao,
      syncDao: syncDao,
      apiClient: apiClient,
      syncEngine: syncEngine,
      connectivity: connectivity,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Household Staples Constants Tests', () {
    test('household staples dataset contains expected categories and rich staples', () {
      expect(kHouseholdStapleCategories.length, equals(9));
      expect(kHouseholdStapleCategories, contains('All'));
      expect(kHouseholdStapleCategories, contains('Dairy & Bakery'));
      expect(kHouseholdStapleCategories, contains('Veg & Fruits'));
      expect(kHouseholdStapleCategories, contains('Grains & Oils'));
      expect(kHouseholdStapleCategories, contains('Pantry & Spices'));

      expect(kHouseholdStaples.length, greaterThanOrEqualTo(70));

      for (final s in kHouseholdStaples) {
        expect(s.name.trim().isNotEmpty, isTrue);
        expect(s.category.trim().isNotEmpty, isTrue);
        expect(s.defaultQty, greaterThan(0));
        expect(s.defaultUnit.trim().isNotEmpty, isTrue);
        expect(s.emoji.isNotEmpty, isTrue);
      }
    });

    test('staple helper getters work backwards-compatible', () {
      final staple = kHouseholdStaples.first;
      expect(staple.qty, equals(staple.defaultQty));
      expect(staple.unit, equals(staple.defaultUnit));
    });

    test('household staples provide product-tailored suggested quantities and brands', () {
      final milk = kHouseholdStaples.firstWhere((s) => s.name == 'Milk');
      expect(milk.suggestedQuantities, contains(1.0));
      expect(milk.suggestedQuantities, contains(2.0));
      expect(milk.suggestedBrands, contains('Amul'));

      final rice = kHouseholdStaples.firstWhere((s) => s.name == 'Basmati Rice');
      expect(rice.suggestedQuantities, contains(5.0));
      expect(rice.suggestedQuantities, contains(10.0));
      expect(rice.suggestedBrands, contains('India Gate'));

      final eggs = kHouseholdStaples.firstWhere((s) => s.name == 'Eggs');
      expect(eggs.suggestedQuantities, contains(6.0));
      expect(eggs.suggestedQuantities, contains(12.0));
      expect(eggs.suggestedQuantities, contains(24.0));

      final butter = kHouseholdStaples.firstWhere((s) => s.name == 'Butter');
      expect(butter.suggestedQuantities, contains(100.0));
      expect(butter.suggestedQuantities, contains(500.0));
      expect(butter.suggestedBrands, contains('Amul'));
    });

    test('all curated staples have non-empty authentic Tamil names and icons', () {
      expect(kCuratedStaples.length, greaterThanOrEqualTo(70));
      for (final s in kCuratedStaples) {
        expect(s.tamilName, isNotNull);
        expect(s.tamilName!.trim().isNotEmpty, isTrue);
        expect(s.icon, isNotNull);
        expect(s.iconData, isNotNull);
        expect(s.displayName, contains(s.tamilName!));
      }

      final milk = kCuratedStaples.firstWhere((s) => s.name == 'Milk');
      expect(milk.tamilName, equals('பால்'));

      final toorDal = kCuratedStaples.firstWhere((s) => s.name == 'Toor Dal');
      expect(toorDal.tamilName, equals('துவரம் பருப்பு'));

      final onions = kCuratedStaples.firstWhere((s) => s.name == 'Onions');
      expect(onions.tamilName, equals('வெங்காயம்'));
    });

    test('master product catalog contains 2000+ items with full Tamil names, icons and emojis', () {
      expect(kMasterProductCatalogStaples.length, greaterThanOrEqualTo(2000));
      expect(kHouseholdStaples.length, greaterThanOrEqualTo(2000));

      for (final s in kMasterProductCatalogStaples) {
        expect(s.name.trim().isNotEmpty, isTrue);
        expect(s.tamilName, isNotNull);
        expect(s.tamilName!.trim().isNotEmpty, isTrue);
        expect(s.emoji.isNotEmpty, isTrue);
        expect(s.icon, isNotNull);
        expect(s.category.isNotEmpty, isTrue);
      }
    });
  });

  group('Inventory Quick Essentials & Created Items Shopping Flow', () {
    test('1-tap Quick Essential creates item directly in inventory with IN_STOCK', () async {
      final eggsStaple = kHouseholdStaples.firstWhere((s) => s.name == 'Eggs');

      final created = await inventoryRepo.createItem(
        testHomeId,
        {
          'name': eggsStaple.name,
          'categoryName': eggsStaple.category,
          'categoryIcon': 'egg_rounded',
          'quantity': eggsStaple.defaultQty,
          'unit': eggsStaple.defaultUnit,
          'minimumQuantity': eggsStaple.minimumQuantity,
        },
      );

      expect(created.id, isNotEmpty);
      expect(created.name, 'Eggs');
      expect(created.quantity, 12.0);
      expect(created.stockStatus, 'IN_STOCK');

      // Verify in DB
      final local = await inventoryDao.getItemById(created.id);
      expect(local, isNotNull);
      expect(local!.name, 'Eggs');
      expect(local.stockStatus, 'IN_STOCK');
    });

    test('Adding created inventory item to shopping list strictly links inventoryItemId', () async {
      // 1. Create an item in inventory
      final item = await inventoryRepo.createItem(
        testHomeId,
        {
          'name': 'Basmati Rice',
          'categoryName': 'Grains & Oils',
          'categoryIcon': 'grain_rounded',
          'quantity': 5.0,
          'unit': 'kg',
          'minimumQuantity': 2.0,
        },
      );

      final defaultList = await shoppingDao.ensureDefaultList(testHomeId);

      // 2. Add this created item to the shopping list
      final shopItem = await shoppingRepo.addItem(
        testHomeId,
        defaultList.id,
        itemName: item.name,
        quantity: 1.0,
        unit: item.unit,
        categoryName: item.categoryName,
        inventoryItemId: item.id,
      );

      expect(shopItem.inventoryItemId, equals(item.id));
      expect(shopItem.itemName, equals('Basmati Rice'));
      expect(shopItem.categoryName, equals('Grains & Oils'));

      // 3. Completing shopping item updates the created inventory item quantity
      await shoppingRepo.toggleItem(testHomeId, defaultList.id, shopItem.id);

      final updatedInv = await inventoryDao.getItemById(item.id);
      expect(updatedInv, isNotNull);
      // 5.0 original + 1.0 purchased = 6.0
      expect(updatedInv!.quantity, equals(6.0));
      expect(updatedInv.stockStatus, equals('IN_STOCK'));
    });

    test('Multi-select batch add creates all shopping items linked to created inventory items', () async {
      final defaultList = await shoppingDao.ensureDefaultList(testHomeId);

      final itemA = await inventoryRepo.createItem(
        testHomeId,
        {
          'name': 'Dish Soap',
          'categoryName': 'Cleaning',
          'categoryIcon': 'cleaning_services_rounded',
          'quantity': 1.0,
          'unit': 'bottle',
          'minimumQuantity': 1.0,
        },
      );

      final itemB = await inventoryRepo.createItem(
        testHomeId,
        {
          'name': 'Mustard Oil',
          'categoryName': 'Grains & Oils',
          'categoryIcon': 'opacity_rounded',
          'quantity': 1.0,
          'unit': 'L',
          'minimumQuantity': 1.0,
        },
      );

      final selectedCreatedItems = [itemA, itemB];

      // Simulate multi-select action in inventory screen
      for (final invItem in selectedCreatedItems) {
        await shoppingRepo.addItem(
          testHomeId,
          defaultList.id,
          itemName: invItem.name,
          quantity: invItem.quantity > 0 ? invItem.quantity : 1.0,
          unit: invItem.unit,
          categoryName: invItem.categoryName,
          inventoryItemId: invItem.id,
        );
      }

      final listItems = await shoppingDao.getShoppingItems(defaultList.id);
      expect(listItems.length, equals(2));

      final shopDishSoap = listItems.firstWhere((i) => i.itemName == 'Dish Soap');
      final shopMustardOil = listItems.firstWhere((i) => i.itemName == 'Mustard Oil');

      expect(shopDishSoap.inventoryItemId, equals(itemA.id));
      expect(shopMustardOil.inventoryItemId, equals(itemB.id));
    });

    test('Existing pantry item restock increments quantity directly', () async {
      final eggs = await inventoryRepo.createItem(
        testHomeId,
        {
          'name': 'Eggs',
          'categoryName': 'Dairy & Bakery',
          'categoryIcon': 'egg_rounded',
          'quantity': 12.0,
          'unit': 'pcs',
          'minimumQuantity': 6.0,
        },
      );

      // Restock action adds 12.0
      await inventoryRepo.updateItem(
        testHomeId,
        eggs.id,
        {'quantity': eggs.quantity + 12.0},
      );

      final reloaded = await inventoryDao.getItemById(eggs.id);
      expect(reloaded!.quantity, equals(24.0));
      expect(reloaded.stockStatus, equals('IN_STOCK'));
    });
  });
}
