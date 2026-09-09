import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/database/app_database.dart';
import 'package:homestock/core/database/daos/inventory_dao.dart';
import 'package:homestock/core/database/daos/shopping_dao.dart';
import 'package:homestock/core/database/daos/sync_dao.dart';
import 'package:homestock/core/network/api_client.dart';
import 'package:homestock/core/storage/secure_storage_service.dart';
import 'package:homestock/core/sync/connectivity_monitor.dart';
import 'package:homestock/core/sync/sync_engine.dart';
import 'package:homestock/features/dashboard/dashboard_repository.dart';
import 'package:homestock/features/shopping/shopping_repository.dart';

void main() {
  late AppDatabase db;
  late ShoppingDao shoppingDao;
  late InventoryDao inventoryDao;
  late SyncDao syncDao;
  late ConnectivityMonitor connectivity;
  late SyncEngine syncEngine;
  late ShoppingRepository shoppingRepo;
  late DashboardRepository dashboardRepo;

  const testHomeId = 'home-connection-test-123';

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

    dashboardRepo = DashboardRepository(
      apiClient: apiClient,
      inventoryDao: inventoryDao,
      shoppingDao: shoppingDao,
      connectivity: connectivity,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Shopping List to Inventory & Dashboard Connection Tests', () {
    test('Adding shopping item auto-connects to existing inventory item by name', () async {
      // 1. Create a low-stock inventory item
      await inventoryDao.upsertItem(LocalInventoryItemsCompanion(
        id: const Value('inv-milk-1'),
        homeId: const Value(testHomeId),
        name: const Value('Fresh Whole Milk'),
        categoryName: const Value('Dairy & Eggs'),
        quantity: const Value(0.5),
        unit: const Value('L'),
        minimumQuantity: const Value(2.0),
        stockStatus: const Value('LOW_STOCK'),
        isLocalOnly: const Value(true),
        isDeleted: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));

      // 2. Add shopping item with matching name
      final defaultList = await shoppingDao.ensureDefaultList(testHomeId);
      final shopItem = await shoppingRepo.addItem(
        testHomeId,
        defaultList.id,
        itemName: 'Fresh Whole Milk',
        quantity: 2.0,
        unit: 'L',
      );

      expect(shopItem.inventoryItemId, 'inv-milk-1');
      expect(shopItem.categoryName, 'Dairy & Eggs');
    });

    test('Toggling shopping item to completed updates inventory stock, clears low-stock, and updates dashboard', () async {
      // 1. Setup out of stock item
      await inventoryDao.upsertItem(LocalInventoryItemsCompanion(
        id: const Value('inv-bread-1'),
        homeId: const Value(testHomeId),
        name: const Value('Whole Wheat Bread'),
        categoryName: const Value('Bakery'),
        quantity: const Value(0.0),
        unit: const Value('pk'),
        minimumQuantity: const Value(1.0),
        stockStatus: const Value('OUT_OF_STOCK'),
        isLocalOnly: const Value(true),
        isDeleted: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));

      // Initial dashboard check
      var summary = await dashboardRepo.getLocalSummary(testHomeId);
      expect(summary.outOfStockCount, 1);
      expect(summary.lowStockCount, 0);

      // 2. Add shopping item
      final defaultList = await shoppingDao.ensureDefaultList(testHomeId);
      final shopItem = await shoppingRepo.addItem(
        testHomeId,
        defaultList.id,
        itemName: 'Whole Wheat Bread',
        quantity: 2.0,
        unit: 'pk',
      );

      // 3. Mark bought (toggleItem)
      await shoppingRepo.toggleItem(testHomeId, defaultList.id, shopItem.id);

      // Verify inventory item was restocked
      final updatedInv = await inventoryDao.getItemById('inv-bread-1');
      expect(updatedInv, isNotNull);
      expect(updatedInv!.quantity, 2.0);
      expect(updatedInv.stockStatus, 'IN_STOCK');

      // Verify STOCK_IN transaction was recorded
      final transactions = await inventoryDao.getTransactions('inv-bread-1');
      expect(transactions.length, 1);
      expect(transactions.first.transactionType, 'STOCK_IN');
      expect(transactions.first.quantityChange, 2.0);
      expect(transactions.first.newQuantity, 2.0);

      // Verify dashboard summary now shows 0 out-of-stock and 0 low-stock
      summary = await dashboardRepo.getLocalSummary(testHomeId);
      expect(summary.outOfStockCount, 0);
      expect(summary.lowStockCount, 0);

      // 4. Undo toggle (uncheck)
      await shoppingRepo.toggleItem(testHomeId, defaultList.id, shopItem.id);

      final revertedInv = await inventoryDao.getItemById('inv-bread-1');
      expect(revertedInv, isNotNull);
      expect(revertedInv!.quantity, 0.0);
      expect(revertedInv.stockStatus, 'OUT_OF_STOCK');

      // Verify STOCK_OUT recorded
      final transactionsAfterUndo = await inventoryDao.getTransactions('inv-bread-1');
      expect(transactionsAfterUndo.length, 2);
      expect(transactionsAfterUndo.first.transactionType, 'STOCK_OUT');

      // Dashboard reverts to 1 out of stock
      summary = await dashboardRepo.getLocalSummary(testHomeId);
      expect(summary.outOfStockCount, 1);
    });

    test('Unit conversion works during shopping item purchase (500g to 0.5kg)', () async {
      // 1. Inventory tracks Flour in kg
      await inventoryDao.upsertItem(LocalInventoryItemsCompanion(
        id: const Value('inv-flour-1'),
        homeId: const Value(testHomeId),
        name: const Value('All Purpose Flour'),
        categoryName: const Value('Grains & Oils'),
        quantity: const Value(0.5),
        unit: const Value('kg'),
        minimumQuantity: const Value(1.0),
        stockStatus: const Value('LOW_STOCK'),
        isLocalOnly: const Value(true),
        isDeleted: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));

      // 2. Shopping item was added in grams: 500g
      final defaultList = await shoppingDao.ensureDefaultList(testHomeId);
      final shopItem = await shoppingRepo.addItem(
        testHomeId,
        defaultList.id,
        itemName: 'All Purpose Flour',
        quantity: 500.0,
        unit: 'g',
      );

      // 3. Complete item
      await shoppingRepo.toggleItem(testHomeId, defaultList.id, shopItem.id);

      // 4. 0.5kg + 500g (0.5kg) = 1.0kg -> stockStatus becomes LOW_STOCK (<= min 1.0)
      // or if we buy another 500g it becomes 1.5kg (IN_STOCK)
      var updated = await inventoryDao.getItemById('inv-flour-1');
      expect(updated!.quantity, 1.0);
    });

    test('Purchasing an unlisted item auto-creates it into inventory pantry with IN_STOCK', () async {
      final defaultList = await shoppingDao.ensureDefaultList(testHomeId);
      final shopItem = await shoppingRepo.addItem(
        testHomeId,
        defaultList.id,
        itemName: 'Organic Olive Oil',
        categoryName: 'Grains & Oils',
        quantity: 1.0,
        unit: 'bottle',
      );

      // Mark purchased
      await shoppingRepo.toggleItem(testHomeId, defaultList.id, shopItem.id);

      // Check that inventory now has Organic Olive Oil
      final invItem = await inventoryDao.findItemByName(testHomeId, 'Organic Olive Oil');
      expect(invItem, isNotNull);
      expect(invItem!.quantity, 1.0);
      expect(invItem.stockStatus, 'IN_STOCK');
      expect(invItem.unit, 'bottle');
    });
  });
}
