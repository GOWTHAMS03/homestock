import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/database/app_database.dart';
import 'package:homestock/core/database/daos/shopping_dao.dart';
import 'package:homestock/core/database/daos/sync_dao.dart';
import 'package:homestock/core/network/api_client.dart';
import 'package:homestock/core/storage/secure_storage_service.dart';
import 'package:homestock/core/sync/connectivity_monitor.dart';
import 'package:homestock/core/sync/sync_engine.dart';
import 'package:homestock/features/shopping/shopping_controller.dart';
import 'package:homestock/features/shopping/shopping_repository.dart';

void main() {
  late AppDatabase db;
  late ShoppingDao shoppingDao;
  late SyncDao syncDao;
  late ConnectivityMonitor connectivity;
  late SyncEngine syncEngine;
  late ShoppingRepository shoppingRepo;

  const testHomeId = 'test-home-id-456';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    shoppingDao = ShoppingDao(db);
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
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ShoppingDao & Repository Resilience Tests', () {
    test('getDefaultList handles multiple default lists without throwing StateError', () async {
      // Insert duplicate default lists for the same home
      await shoppingDao.upsertShoppingList(LocalShoppingListsCompanion(
        id: const Value('list-local-1'),
        homeId: const Value(testHomeId),
        name: const Value('Local Default List'),
        isDefault: const Value(true),
        updatedAt: Value(DateTime.now().subtract(const Duration(minutes: 5))),
      ));

      await shoppingDao.upsertShoppingList(LocalShoppingListsCompanion(
        id: const Value('list-server-2'),
        homeId: const Value(testHomeId),
        name: const Value('Server Default List'),
        isDefault: const Value(true),
        updatedAt: Value(DateTime.now()),
      ));

      // Must not throw "Bad state: Too many elements"
      final defaultList = await shoppingDao.getDefaultList(testHomeId);
      expect(defaultList, isNotNull);
      expect(defaultList!.id, 'list-server-2');
    });

    test('watchShoppingItemsForHome observes items across different list IDs for the same home', () async {
      // 1. Create list 1
      await shoppingDao.upsertShoppingList(LocalShoppingListsCompanion(
        id: const Value('list-1'),
        homeId: const Value(testHomeId),
        name: const Value('List 1'),
        isDefault: const Value(true),
      ));

      // Add item to list 1
      await shoppingRepo.addItem(
        testHomeId,
        'list-1',
        itemName: 'Apple',
        quantity: 3.0,
      );

      // 2. Create list 2 for the same home (e.g. from sync)
      await shoppingDao.upsertShoppingList(LocalShoppingListsCompanion(
        id: const Value('list-2'),
        homeId: const Value(testHomeId),
        name: const Value('List 2'),
        isDefault: const Value(true),
      ));

      // Add item to list 2
      await shoppingRepo.addItem(
        testHomeId,
        'list-2',
        itemName: 'Banana',
        quantity: 6.0,
      );

      // Stream should see both items without StateError!
      final items = await shoppingDao.watchShoppingItemsForHome(testHomeId).first;
      expect(items.length, 2);
      final names = items.map((i) => i.itemName).toSet();
      expect(names.contains('Apple'), isTrue);
      expect(names.contains('Banana'), isTrue);
    });

    test('resolveFallbackHomeId inspects local tables or returns null', () async {
      // Initially empty tables
      final initialFallback = await shoppingDao.resolveFallbackHomeId();
      expect(initialFallback, isNull);

      // Now insert a local home
      await db.into(db.localHomes).insert(LocalHomesCompanion(
        id: const Value('cached-home-777'),
        name: const Value('My Sweet Home'),
        inviteCode: const Value('ABCDEF'),
      ));

      final resolved = await shoppingDao.resolveFallbackHomeId();
      expect(resolved, 'cached-home-777');
    });

    test('ShoppingController can add item and resolve fallback home when initially null', () async {
      // Pre-populate a home in SQLite
      await db.into(db.localHomes).insert(LocalHomesCompanion(
        id: const Value(testHomeId),
        name: const Value('Test Home'),
        inviteCode: const Value('123456'),
      ));

      // Controller constructed with null homeId
      final controller = ShoppingController(shoppingRepo, null);

      final success = await controller.addItem(
        itemName: 'Fresh Sourdough Bread',
        quantity: 1.0,
        unit: 'loaf',
      );

      expect(success, isTrue);

      final items = await shoppingDao.getShoppingItemsForHome(testHomeId);
      expect(items.length, 1);
      expect(items.first.itemName, 'Fresh Sourdough Bread');

      controller.dispose();
    });
  });
}
