import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/database/app_database.dart';
import 'package:homestock/core/database/daos/sync_dao.dart';
import 'package:homestock/core/sync/sync_operation.dart';
import 'package:homestock/core/sync/sync_status.dart';

void main() {
  late AppDatabase db;
  late SyncDao syncDao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    syncDao = SyncDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Sync 8-State Lifecycle & Models', () {
    test('SyncStatus has 8 distinct lifecycle states in order', () {
      expect(SyncStatus.values, equals([
        SyncStatus.offline,
        SyncStatus.networkAvailable,
        SyncStatus.syncingPush,
        SyncStatus.syncingPull,
        SyncStatus.reconciling,
        SyncStatus.synced,
        SyncStatus.error,
        SyncStatus.authRequired,
      ]));
    });

    test('SyncState statusMessage accurately reflects each state', () {
      const offline = SyncState(syncStatus: SyncStatus.offline, pendingOperationsCount: 2);
      expect(offline.isOffline, isTrue);
      expect(offline.statusMessage, contains('Offline • 2 change(s) saved locally'));

      const netAvailable = SyncState(syncStatus: SyncStatus.networkAvailable, pendingOperationsCount: 3);
      expect(netAvailable.statusMessage, contains('Network available • Syncing soon (3 pending)'));

      const pushing = SyncState(syncStatus: SyncStatus.syncingPush, pendingOperationsCount: 4);
      expect(pushing.isPushing, isTrue);
      expect(pushing.isSyncing, isTrue);
      expect(pushing.statusMessage, contains('Uploading 4 local change(s)...'));

      const pulling = SyncState(syncStatus: SyncStatus.syncingPull);
      expect(pulling.isPulling, isTrue);
      expect(pulling.isSyncing, isTrue);
      expect(pulling.statusMessage, equals('Checking for remote updates...'));

      const reconciling = SyncState(syncStatus: SyncStatus.reconciling);
      expect(reconciling.isReconciling, isTrue);
      expect(reconciling.isSyncing, isTrue);
      expect(reconciling.statusMessage, equals('Reconciling data with server...'));

      const synced = SyncState(syncStatus: SyncStatus.synced);
      expect(synced.isSynced, isTrue);
      expect(synced.statusMessage, equals('Synced with server'));

      const authReq = SyncState(syncStatus: SyncStatus.authRequired);
      expect(authReq.isAuthRequired, isTrue);
      expect(authReq.statusMessage, contains('Session expired'));

      const err = SyncState(syncStatus: SyncStatus.error, lastError: 'Network timeout');
      expect(err.statusMessage, contains('Sync error: Network timeout'));
    });
  });

  group('SyncDao Timestamps and Retention Cleanup', () {
    test('markSyncing records lastAttemptAt timestamp', () async {
      final now = DateTime.now().toUtc();
      await syncDao.addToSyncQueue(SyncQueueEntriesCompanion(
        operationId: const Value('op-test-1'),
        operationType: const Value('CREATE_ITEM'),
        entityType: const Value('INVENTORY_ITEM'),
        entityId: const Value('item-1'),
        payload: const Value('{}'),
        createdAt: Value(now),
        homeId: const Value('home-1'),
      ));

      await syncDao.markSyncing('op-test-1');

      final pending = await (db.select(db.syncQueueEntries)..where((t) => t.operationId.equals('op-test-1'))).getSingle();
      expect(pending.status, equals('SYNCING'));
      expect(pending.lastAttemptAt, isNotNull);
    });

    test('markSynced records serverAcknowledgedAt timestamp', () async {
      final now = DateTime.now().toUtc();
      await syncDao.addToSyncQueue(SyncQueueEntriesCompanion(
        operationId: const Value('op-test-2'),
        operationType: const Value('UPDATE_ITEM'),
        entityType: const Value('INVENTORY_ITEM'),
        entityId: const Value('item-2'),
        payload: const Value('{}'),
        createdAt: Value(now),
        homeId: const Value('home-1'),
      ));

      await syncDao.markSynced('op-test-2');

      final synced = await (db.select(db.syncQueueEntries)..where((t) => t.operationId.equals('op-test-2'))).getSingle();
      expect(synced.status, equals('SYNCED'));
      expect(synced.serverAcknowledgedAt, isNotNull);
    });

    test('cleanupOldSyncedOperations retains recent operations and cleans older than 24 hours', () async {
      final now = DateTime.now().toUtc();
      final oldTime = now.subtract(const Duration(hours: 25));

      // Recent synced op (acknowledged 1 hour ago)
      await db.into(db.syncQueueEntries).insert(SyncQueueEntriesCompanion(
        operationId: const Value('op-recent'),
        operationType: const Value('UPDATE_ITEM'),
        entityType: const Value('INVENTORY_ITEM'),
        entityId: const Value('item-recent'),
        payload: const Value('{}'),
        createdAt: Value(now),
        homeId: const Value('home-1'),
        status: const Value('SYNCED'),
        serverAcknowledgedAt: Value(now.subtract(const Duration(hours: 1))),
      ));

      // Old synced op (acknowledged 25 hours ago)
      await db.into(db.syncQueueEntries).insert(SyncQueueEntriesCompanion(
        operationId: const Value('op-old'),
        operationType: const Value('UPDATE_ITEM'),
        entityType: const Value('INVENTORY_ITEM'),
        entityId: const Value('item-old'),
        payload: const Value('{}'),
        createdAt: Value(oldTime),
        homeId: const Value('home-1'),
        status: const Value('SYNCED'),
        serverAcknowledgedAt: Value(oldTime),
      ));

      // Pending op (never delete pending ops!)
      await db.into(db.syncQueueEntries).insert(SyncQueueEntriesCompanion(
        operationId: const Value('op-pending'),
        operationType: const Value('CREATE_ITEM'),
        entityType: const Value('INVENTORY_ITEM'),
        entityId: const Value('item-pending'),
        payload: const Value('{}'),
        createdAt: Value(oldTime),
        homeId: const Value('home-1'),
        status: const Value('PENDING'),
      ));

      await syncDao.cleanupOldSyncedOperations();

      final all = await db.select(db.syncQueueEntries).get();
      final opIds = all.map((e) => e.operationId).toSet();

      expect(opIds.contains('op-old'), isFalse);
      expect(opIds.contains('op-recent'), isTrue);
      expect(opIds.contains('op-pending'), isTrue);
    });
  });

  group('SyncDao Family & Home Reconciliation in Transaction', () {
    test('applyPullChangesInTransaction reconciles home members and details', () async {
      final now = DateTime.now().toUtc();

      await syncDao.applyPullChangesInTransaction(
        homeId: 'home-100',
        categories: [],
        inventoryItems: [],
        stockTransactions: [],
        shoppingLists: [],
        shoppingListItems: [],
        purchases: [],
        purchaseItems: [],
        stores: [],
        homeMembers: [
          const LocalHomeMembersCompanion(
            id: Value('member-1'),
            homeId: Value('home-100'),
            userId: Value('user-1'),
            fullName: Value('Alice Sekar'),
            email: Value('alice@example.com'),
            role: Value('ADMIN'),
          ),
          const LocalHomeMembersCompanion(
            id: Value('member-2'),
            homeId: Value('home-100'),
            userId: Value('user-2'),
            fullName: Value('Bob Sekar'),
            email: Value('bob@example.com'),
            role: Value('MEMBER'),
          ),
        ],
        homeDetails: const LocalHomesCompanion(
          id: Value('home-100'),
          name: Value('Sekar Residence'),
          inviteCode: Value('SEKAR123'),
          currentUserRole: Value('ADMIN'),
          memberCount: Value(2),
        ),
        deletedShoppingItemIds: [],
        deletedInventoryItemIds: [],
        deletedStoreIds: [],
        deletedCategoryIds: [],
        serverTimestamp: now,
        nextServerVersion: 42,
      );

      final members = await (db.select(db.localHomeMembers)..where((t) => t.homeId.equals('home-100'))).get();
      expect(members.length, equals(2));
      expect(members.first.fullName, equals('Alice Sekar'));

      final home = await (db.select(db.localHomes)..where((t) => t.id.equals('home-100'))).getSingle();
      expect(home.name, equals('Sekar Residence'));

      final cursor = await syncDao.getSyncVersion('home-100');
      expect(cursor, equals(42));
    });

    test('applyPullChangesInTransaction deletes removed members atomically', () async {
      final now = DateTime.now().toUtc();

      // Seed initial member
      await db.into(db.localHomeMembers).insert(const LocalHomeMembersCompanion(
        id: Value('mem-to-remove'),
        homeId: Value('home-200'),
        userId: Value('user-to-remove'),
        fullName: Value('Ex Member'),
        email: Value('ex@example.com'),
        role: Value('MEMBER'),
      ));

      await syncDao.applyPullChangesInTransaction(
        homeId: 'home-200',
        categories: [],
        inventoryItems: [],
        stockTransactions: [],
        shoppingLists: [],
        shoppingListItems: [],
        purchases: [],
        purchaseItems: [],
        stores: [],
        deletedMemberUserIds: ['user-to-remove'],
        deletedShoppingItemIds: [],
        deletedInventoryItemIds: [],
        deletedStoreIds: [],
        deletedCategoryIds: [],
        serverTimestamp: now,
        nextServerVersion: 50,
      );

      final members = await (db.select(db.localHomeMembers)..where((t) => t.homeId.equals('home-200'))).get();
      expect(members.isEmpty, isTrue);
    });
  });

  group('SyncPullResponse Home & Member Parsing', () {
    test('parses homeMembers, homeDetails, and deletedMemberUserIds', () {
      final json = {
        'inventoryItems': [],
        'stockTransactions': [],
        'shoppingListItems': [],
        'shoppingLists': [],
        'purchases': [],
        'purchaseItems': [],
        'categories': [],
        'stores': [],
        'homeMembers': [
          {'id': 'm-1', 'userId': 'u-1', 'fullName': 'Jane', 'email': 'jane@test.com', 'role': 'MEMBER'}
        ],
        'homeDetails': {
          'id': 'h-1',
          'name': 'Sunny Villa',
          'inviteCode': 'SUNNY99',
          'currentUserRole': 'MEMBER',
          'memberCount': 3,
        },
        'deletedMemberUserIds': ['u-old-1'],
        'serverTimestamp': '2026-09-10T12:00:00Z',
        'serverVersion': 10,
        'nextServerVersion': 11,
      };

      final pull = SyncPullResponse.fromJson(json);
      expect(pull.isEmpty, isFalse);
      expect(pull.homeMembers.length, equals(1));
      expect(pull.homeMembers.first['fullName'], equals('Jane'));
      expect(pull.homeDetails?['name'], equals('Sunny Villa'));
      expect(pull.deletedMemberUserIds, equals(['u-old-1']));
      expect(pull.serverVersion, equals(10));
      expect(pull.nextServerVersion, equals(11));
    });
  });
}
