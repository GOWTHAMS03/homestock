import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/database/app_database.dart';
import 'package:homestock/core/database/daos/inventory_dao.dart';
import 'package:homestock/core/database/daos/purchase_dao.dart';
import 'package:homestock/core/database/daos/shopping_dao.dart';
import 'package:homestock/core/database/daos/sync_dao.dart';
import 'package:homestock/core/network/api_client.dart';
import 'package:homestock/core/storage/secure_storage_service.dart';
import 'package:homestock/core/sync/connectivity_monitor.dart';
import 'package:homestock/core/sync/sync_engine.dart';
import 'package:homestock/core/sync/sync_operation.dart';
import 'package:homestock/core/sync/sync_status.dart';
import 'package:homestock/features/inventory/inventory_repository.dart';
import 'package:homestock/features/purchase/purchase_repository.dart';
import 'package:homestock/features/shopping/shopping_repository.dart';

void main() {
  late AppDatabase db;
  late InventoryDao inventoryDao;
  late ShoppingDao shoppingDao;
  late PurchaseDao purchaseDao;
  late SyncDao syncDao;
  late ConnectivityMonitor connectivity;
  late SyncEngine syncEngine;
  late InventoryRepository inventoryRepo;
  late ShoppingRepository shoppingRepo;
  late PurchaseRepository purchaseRepo;

  const testHomeId = 'home-offline-test-123';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    inventoryDao = InventoryDao(db);
    shoppingDao = ShoppingDao(db);
    purchaseDao = PurchaseDao(db);
    syncDao = SyncDao(db);

    connectivity = ConnectivityMonitor();
    final storage = SecureStorageService();
    final apiClient = ApiClient(secureStorage: storage);

    syncEngine = SyncEngine(
      database: db,
      apiClient: apiClient,
      connectivity: connectivity,
    );

    inventoryRepo = InventoryRepository(
      inventoryDao: inventoryDao,
      syncDao: syncDao,
      apiClient: apiClient,
      connectivity: connectivity,
      syncEngine: syncEngine,
    );

    shoppingRepo = ShoppingRepository(
      shoppingDao: shoppingDao,
      syncDao: syncDao,
      apiClient: apiClient,
      syncEngine: syncEngine,
    );

    purchaseRepo = PurchaseRepository(
      purchaseDao: purchaseDao,
      inventoryDao: inventoryDao,
      syncDao: syncDao,
      apiClient: apiClient,
      syncEngine: syncEngine,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Universal Offline Record Creation', () {
    test('Offline inventory item creation saves to SQLite and queues sync operation', () async {
      final item = await inventoryRepo.createItem(testHomeId, {
        'name': 'Basmati Rice',
        'quantity': 5.0,
        'unit': 'kg',
        'minimumQuantity': 2.0,
        'storageLocation': 'Pantry Shelf A',
      });

      expect(item.name, 'Basmati Rice');
      expect(item.quantity, 5.0);
      expect(item.homeId, testHomeId);

      // Verify item exists in local SQLite
      final localItem = await inventoryDao.getItemById(item.id);
      expect(localItem, isNotNull);
      expect(localItem!.name, 'Basmati Rice');
      expect(localItem.isLocalOnly, isTrue);

      // Verify queued in sync queue
      final pendingOps = await syncDao.getPendingOperations();
      expect(pendingOps.length, 1);
      expect(pendingOps.first.operationType, SyncOperationType.createItem);
      expect(pendingOps.first.entityId, item.id);
    });

    test('Offline category creation saves to SQLite and queues CREATE_CATEGORY', () async {
      final category = await inventoryRepo.createCategory(
        testHomeId,
        name: 'Beverages & Juices',
        icon: 'local_drink',
        colorHex: '#3B82F6',
      );

      expect(category.name, 'Beverages & Juices');
      expect(category.homeId, testHomeId);

      // Verify in SQLite
      final categories = await inventoryDao.getCategories(testHomeId);
      expect(categories.any((c) => c.name == 'Beverages & Juices'), isTrue);

      // Verify queued
      final pendingOps = await syncDao.getPendingOperations();
      expect(pendingOps.any((o) => o.operationType == SyncOperationType.createCategory), isTrue);
    });

    test('Offline shopping item creation auto-creates default list and queues ADD_SHOPPING_ITEM', () async {
      // Intentionally pass null listId to verify auto-seeding
      final shoppingItem = await shoppingRepo.addItem(
        testHomeId,
        null,
        itemName: 'Organic Whole Milk',
        quantity: 2.0,
        unit: 'L',
      );

      expect(shoppingItem.itemName, 'Organic Whole Milk');
      expect(shoppingItem.quantity, 2.0);

      // Verify default shopping list was created in SQLite
      final defaultList = await shoppingDao.getDefaultList(testHomeId);
      expect(defaultList, isNotNull);

      // Verify shopping item exists in SQLite
      final items = await shoppingDao.getShoppingItems(defaultList!.id);
      expect(items.length, 1);
      expect(items.first.itemName, 'Organic Whole Milk');

      // Verify queued
      final pendingOps = await syncDao.getPendingOperations();
      expect(pendingOps.any((o) => o.operationType == SyncOperationType.addShoppingItem), isTrue);
    });

    test('Offline store creation saves to SQLite and queues CREATE_STORE', () async {
      final store = await purchaseRepo.createStore(testHomeId, 'Nature Basket', 'City Center');

      expect(store.name, 'Nature Basket');
      expect(store.location, 'City Center');

      // Verify in SQLite
      final stores = await purchaseDao.getStores(testHomeId);
      expect(stores.length, 1);
      expect(stores.first.name, 'Nature Basket');

      // Verify queued
      final pendingOps = await syncDao.getPendingOperations();
      expect(pendingOps.any((o) => o.operationType == SyncOperationType.createStore), isTrue);
    });

    test('Offline purchase recording creates purchase, items, restocks inventory, and queues RECORD_PURCHASE', () async {
      // First create an inventory item to link
      final invItem = await inventoryRepo.createItem(testHomeId, {
        'name': 'Olive Oil',
        'quantity': 1.0,
        'unit': 'bottle',
        'minimumQuantity': 2.0,
      });

      // Now record a purchase that restocks this item
      final purchase = await purchaseRepo.recordPurchase(testHomeId, {
        'purchaseDate': '2026-09-07',
        'totalAmount': 650.0,
        'items': [
          {
            'inventoryItemId': invItem.id,
            'itemName': 'Olive Oil',
            'quantity': 2.0,
            'unit': 'bottle',
            'unitPrice': 325.0,
            'totalPrice': 650.0,
          },
        ],
      });

      expect(purchase.totalAmount, 650.0);
      expect(purchase.items.length, 1);

      // Verify inventory stock was increased: 1.0 + 2.0 = 3.0
      final updatedInv = await inventoryDao.getItemById(invItem.id);
      expect(updatedInv!.quantity, 3.0);
      expect(updatedInv.stockStatus, 'IN_STOCK');

      // Verify stock transaction was recorded
      final txs = await inventoryDao.getTransactions(invItem.id);
      expect(txs.any((t) => t.transactionType == 'STOCK_IN' && t.quantityChange == 2.0), isTrue);

      // Verify queued in sync queue
      final pendingOps = await syncDao.getPendingOperations();
      expect(pendingOps.any((o) => o.operationType == SyncOperationType.recordPurchase), isTrue);
    });

    test('Clearing completed shopping items offline queues CLEAR_COMPLETED_SHOPPING', () async {
      final list = await shoppingDao.ensureDefaultList(testHomeId);
      await shoppingRepo.clearCompleted(testHomeId, list.id);

      final pendingOps = await syncDao.getPendingOperations();
      expect(pendingOps.any((o) => o.operationType == SyncOperationType.clearCompletedShopping), isTrue);
    });

    test('SyncEngine.syncAll() returns immediately when offline without network call', () async {
      connectivity.markOffline();
      expect(connectivity.isOnline, isFalse);

      // syncAll should exit immediately without throwing and without starting sync
      await syncEngine.syncAll();
      expect(syncEngine.currentState.isSyncInProgress, isFalse);
      expect(syncEngine.currentState.status, NetworkStatus.offline);
    });
  });
}
