import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:homestock/core/database/app_database.dart';
import 'package:homestock/core/database/daos/inventory_dao.dart';
import 'package:homestock/core/database/daos/sync_dao.dart';
import 'package:homestock/core/network/api_client.dart';
import 'package:homestock/core/storage/cache_service.dart';
import 'package:homestock/core/storage/secure_storage_service.dart';
import 'package:homestock/core/sync/connectivity_monitor.dart';
import 'package:homestock/core/sync/sync_engine.dart';
import 'package:homestock/core/sync/sync_status.dart';
import 'package:homestock/features/inventory/inventory_repository.dart';

class FakeCacheService extends CacheService {
  final Map<String, dynamic> _data = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> set(String key, dynamic value) async {
    _data[key] = value;
  }

  @override
  dynamic get(String key) => _data[key];

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }
}

void main() {
  group('11-Step Reconnection Sequence & Room Membership Tests', () {
    late AppDatabase db;
    late InventoryDao inventoryDao;
    late SyncDao syncDao;
    late FakeCacheService cache;
    late SecureStorageService storage;
    late ApiClient apiClient;
    late ConnectivityMonitor connectivity;
    late SyncEngine syncEngine;
    late InventoryRepository inventoryRepo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      inventoryDao = InventoryDao(db);
      syncDao = SyncDao(db);
      cache = FakeCacheService();
      storage = SecureStorageService(cacheService: cache);
      apiClient = ApiClient(secureStorage: storage);
      connectivity = ConnectivityMonitor();
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
      connectivity.markOnline();
    });

    tearDown(() async {
      syncEngine.dispose();
      await db.close();
    });

    test('Reconnection sequence halts when no authentication tokens are present', () async {
      // No tokens stored
      await syncEngine.syncAll();
      expect(syncEngine.currentState.syncStatus, equals(SyncStatus.authRequired));
    });

    test('Pending sync operations in queue are preserved when sync halts', () async {
      final item = await inventoryRepo.createItem('home-test-1', {
        'name': 'Coffee',
        'quantity': 1.0,
        'unit': 'pack',
      });

      // Attempt sync without tokens
      await syncEngine.syncAll();
      expect(syncEngine.currentState.syncStatus, equals(SyncStatus.authRequired));

      // Verify operation is still pending in local queue
      final pending = await syncDao.getPendingOperations();
      expect(pending.length, equals(1));
      expect(pending.first.entityId, equals(item.id));
      expect(pending.first.status, equals('PENDING'));
    });

    test('Inaccessible home list ignores operations for removed rooms', () async {
      syncEngine.markHomeInaccessible('removed-room-99');
      expect(syncEngine.isHomeInaccessible('removed-room-99'), isTrue);
      expect(syncEngine.isHomeInaccessible('active-room-1'), isFalse);
    });
  });
}
