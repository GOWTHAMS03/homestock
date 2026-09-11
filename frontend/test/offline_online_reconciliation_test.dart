import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/database/app_database.dart';
import 'package:homestock/core/database/daos/inventory_dao.dart';
import 'package:homestock/core/database/daos/sync_dao.dart';
import 'package:homestock/core/network/api_client.dart';
import 'package:homestock/core/storage/secure_storage_service.dart';
import 'package:homestock/core/sync/connectivity_monitor.dart';
import 'package:homestock/core/sync/sync_engine.dart';
import 'package:homestock/core/sync/sync_operation.dart';
import 'package:homestock/features/inventory/inventory_repository.dart';

void main() {
  late AppDatabase db;
  late SyncDao syncDao;
  late InventoryDao inventoryDao;
  late InventoryRepository inventoryRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    syncDao = SyncDao(db);
    inventoryDao = InventoryDao(db);

    final monitor = ConnectivityMonitor();
    final apiClient = ApiClient(
      secureStorage: SecureStorageService(),
      connectivityMonitor: monitor,
    );
    final syncEngine = SyncEngine(
      database: db,
      apiClient: apiClient,
      connectivity: monitor,
    );

    inventoryRepo = InventoryRepository(
      inventoryDao: inventoryDao,
      syncDao: syncDao,
      apiClient: apiClient,
      connectivity: monitor,
      syncEngine: syncEngine,
      database: db,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Offline/Online Reconciliation & Data Preservation Tests', () {
    test('getActivePendingEntityIds accurately tracks pending and syncing entity IDs', () async {
      await syncDao.addToSyncQueue(SyncQueueEntriesCompanion(
        operationId: const Value('op-1'),
        operationType: const Value(SyncOperationType.updateItem),
        entityType: const Value(SyncEntityType.inventoryItem),
        entityId: const Value('item-123'),
        payload: const Value('{}'),
        createdAt: Value(DateTime.now()),
        homeId: const Value('home-1'),
      ));

      await syncDao.addToSyncQueue(SyncQueueEntriesCompanion(
        operationId: const Value('op-2'),
        operationType: const Value(SyncOperationType.toggleShoppingItem),
        entityType: const Value(SyncEntityType.shoppingListItem),
        entityId: const Value('shop-456'),
        payload: const Value('{}'),
        createdAt: Value(DateTime.now()),
        homeId: const Value('home-1'),
      ));

      // Mark op-2 as syncing
      await syncDao.markSyncing('op-2');

      final pendingIds = await syncDao.getActivePendingEntityIds(homeId: 'home-1');
      expect(pendingIds, contains('item-123'));
      expect(pendingIds, contains('shop-456'));

      // Mark op-1 as SYNCED
      await syncDao.markSynced('op-1');

      final afterSyncedIds = await syncDao.getActivePendingEntityIds(homeId: 'home-1');
      expect(afterSyncedIds.contains('item-123'), isFalse);
      expect(afterSyncedIds.contains('shop-456'), isTrue);
    });

    test('applyPullChangesInTransaction does not overwrite items with pending local modifications', () async {
      const homeId = 'home-1';
      const itemId = 'item-local-mod';

      // 1. Insert item locally
      await inventoryDao.upsertItem(LocalInventoryItemsCompanion(
        id: const Value(itemId),
        homeId: const Value(homeId),
        name: const Value('Amul Milk 500ml'),
        quantity: const Value(4.0),
        stockStatus: const Value('IN_STOCK'),
        categoryName: const Value('Dairy'),
        brand: const Value('Amul'),
        expiryDate: const Value('2026-10-15'),
        updatedAt: Value(DateTime.now()),
      ));

      // 2. User modifies quantity to 1.0 offline -> queues pending operation
      await inventoryDao.updateLocalStock(itemId, 1.0, 'LOW_STOCK');
      await syncDao.addToSyncQueue(SyncQueueEntriesCompanion(
        operationId: const Value('op-stock-out'),
        operationType: const Value(SyncOperationType.stockOut),
        entityType: const Value(SyncEntityType.inventoryItem),
        entityId: const Value(itemId),
        payload: Value(jsonEncode({'quantityChange': 3.0})),
        createdAt: Value(DateTime.now()),
        homeId: const Value(homeId),
      ));

      // 3. Server pull arrives with OLD data (quantity = 4.0, stockStatus = IN_STOCK)
      await syncDao.applyPullChangesInTransaction(
        homeId: homeId,
        categories: [],
        inventoryItems: [
          LocalInventoryItemsCompanion(
            id: const Value(itemId),
            homeId: const Value(homeId),
            name: const Value('Amul Milk 500ml'),
            quantity: const Value(4.0), // Stale server value
            stockStatus: const Value('IN_STOCK'), // Stale server value
            categoryName: const Value('Dairy'),
            brand: const Value('Amul'),
            updatedAt: Value(DateTime.now()),
          ),
        ],
        stockTransactions: [],
        shoppingLists: [],
        shoppingListItems: [],
        purchases: [],
        purchaseItems: [],
        stores: [],
        deletedShoppingItemIds: [],
        deletedInventoryItemIds: [],
        deletedStoreIds: [],
        deletedCategoryIds: [],
        serverTimestamp: DateTime.now(),
      );

      // 4. Verify local modifications were PROTECTED from being overwritten
      final protectedItem = await inventoryDao.getItemById(itemId);
      expect(protectedItem, isNotNull);
      expect(protectedItem!.quantity, equals(1.0));
      expect(protectedItem.stockStatus, equals('LOW_STOCK'));
    });

    test('InventoryRepository.updateItem preserves existing metadata on partial updates', () async {
      const homeId = 'home-1';
      const itemId = 'item-full-meta';

      // 1. Create item with full metadata
      await inventoryDao.upsertItem(LocalInventoryItemsCompanion(
        id: const Value(itemId),
        homeId: const Value(homeId),
        name: const Value('Organic Basmati Rice'),
        brand: const Value('Daawat'),
        categoryName: const Value('Grains'),
        quantity: const Value(5.0),
        unit: const Value('kg'),
        minimumQuantity: const Value(2.0),
        maximumQuantity: const Value(10.0),
        storageLocation: const Value('Pantry Shelf A'),
        purchasePrice: const Value(350.0),
        purchaseDate: const Value('2026-09-01'),
        expiryDate: const Value('2027-09-01'),
        notes: const Value('Keep in airtight container'),
        stockStatus: const Value('IN_STOCK'),
        updatedAt: Value(DateTime.now()),
      ));

      // 2. Perform partial update (e.g. quick confirmation or simple quantity update)
      final updated = await inventoryRepo.updateItem(homeId, itemId, {
        'quantity': 3.0,
        'stockStatus': 'IN_STOCK',
      });

      // 3. Verify quantity was updated
      expect(updated.quantity, equals(3.0));

      // 4. Verify existing fields were PRESERVED and not wiped to null
      expect(updated.name, equals('Organic Basmati Rice'));
      expect(updated.brand, equals('Daawat'));
      expect(updated.categoryName, equals('Grains'));
      expect(updated.unit, equals('kg'));
      expect(updated.minimumQuantity, equals(2.0));
      expect(updated.maximumQuantity, equals(10.0));
      expect(updated.storageLocation, equals('Pantry Shelf A'));
      expect(updated.purchasePrice, equals(350.0));
      expect(updated.purchaseDate, equals('2026-09-01'));
      expect(updated.expiryDate, equals('2027-09-01'));
      expect(updated.notes, equals('Keep in airtight container'));
    });
  });
}
