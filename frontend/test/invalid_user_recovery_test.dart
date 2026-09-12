import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/database/app_database.dart';
import 'package:homestock/core/database/daos/inventory_dao.dart';
import 'package:homestock/core/database/daos/sync_dao.dart';
import 'package:homestock/core/network/api_client.dart';
import 'package:homestock/core/storage/cache_service.dart';
import 'package:homestock/core/storage/secure_storage_service.dart';
import 'package:homestock/core/sync/connectivity_monitor.dart';
import 'package:homestock/core/sync/sync_engine.dart';
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

class Mock401Adapter implements HttpClientAdapter {
  final String body;
  Mock401Adapter(this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('Invalid User & Deleted Account Recovery Tests', () {
    late AppDatabase db;
    late InventoryDao inventoryDao;
    late SyncDao syncDao;
    late SecureStorageService storage;
    late FakeCacheService cache;
    late InventoryRepository inventoryRepo;
    late SyncEngine syncEngine;
    late ApiClient apiClient;
    late ConnectivityMonitor connectivity;

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
    });

    tearDown(() async {
      syncEngine.dispose();
      await db.close();
    });

    test('Local inventory items in SQLite remain intact when user is not found', () async {
      // 1. User performs offline changes creating local inventory items
      final item = await inventoryRepo.createItem('home-101', {
        'name': 'Whole Milk',
        'quantity': 2.0,
        'unit': 'L',
        'minimumQuantity': 1.0,
        'storageLocation': 'Fridge',
      });

      // Verify item and sync queue exist locally
      final localItem = await inventoryDao.getItemById(item.id);
      expect(localItem, isNotNull);
      expect(localItem!.name, equals('Whole Milk'));

      final queueBefore = await syncDao.getPendingOperations();
      expect(queueBefore.length, equals(1));
      expect(queueBefore.first.entityId, equals(item.id));

      // 2. Simulate User Not Found response: clear tokens from SecureStorage
      await storage.saveTokens(accessToken: 'orphan-token', refreshToken: 'orphan-refresh');
      expect(storage.hasCachedTokensSync(), isTrue);

      await storage.clearAll();
      expect(storage.hasCachedTokensSync(), isFalse);

      // 3. Verify SQLite data is NEVER deleted on USER_NOT_FOUND
      final localItemAfter = await inventoryDao.getItemById(item.id);
      expect(localItemAfter, isNotNull);
      expect(localItemAfter!.name, equals('Whole Milk'));
      expect(localItemAfter.quantity, equals(2.0));

      final queueAfter = await syncDao.getPendingOperations();
      expect(queueAfter.length, equals(1));
      expect(queueAfter.first.entityId, equals(item.id));
    });

    test('ApiClient triggers onUserNotFound callback on 401 USER_NOT_FOUND error', () async {
      bool userNotFoundTriggered = false;
      apiClient.onUserNotFound = () {
        userNotFoundTriggered = true;
      };

      apiClient.dio.httpClientAdapter = Mock401Adapter(
        jsonEncode({
          'code': 'USER_NOT_FOUND',
          'message': 'This HomeStock account could not be verified. Please sign in again.',
        }),
      );

      try {
        await apiClient.get('/api/v1/users/me');
      } catch (_) {}

      expect(userNotFoundTriggered, isTrue);
    });

    test('ApiClient does not attempt refresh loop when error code is USER_NOT_FOUND', () async {
      await storage.saveTokens(accessToken: 'expired-access', refreshToken: 'dummy-refresh');

      bool userNotFoundFired = false;
      apiClient.onUserNotFound = () {
        userNotFoundFired = true;
      };

      apiClient.dio.httpClientAdapter = Mock401Adapter(
        jsonEncode({
          'code': 'USER_NOT_FOUND',
          'message': 'This HomeStock account could not be verified.',
        }),
      );

      try {
        await apiClient.get('/api/v1/inventory/home-101');
      } catch (_) {}

      // Expect userNotFound callback to fire and refresh loop to NOT trigger
      expect(userNotFoundFired, isTrue);
      final token = await storage.getAccessToken();
      expect(token, equals('expired-access'));
    });
  });
}
