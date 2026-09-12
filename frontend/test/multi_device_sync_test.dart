import 'dart:convert';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/database/app_database.dart';
import 'package:homestock/core/database/daos/inventory_dao.dart';
import 'package:homestock/core/database/daos/sync_dao.dart';
import 'package:homestock/core/sync/sync_operation.dart';
import 'package:uuid/uuid.dart';

void main() {
  const uuid = Uuid();
  const homeId = 'home-family-123';
  const riceItemId = 'rice-item-id-001';

  group('Multi-Device Synchronization Integration Tests', () {
    late AppDatabase dbPhoneA;
    late AppDatabase dbPhoneB;
    late SyncDao syncDaoA;
    late SyncDao syncDaoB;
    late InventoryDao invDaoA;
    late InventoryDao invDaoB;

    setUpAll(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    });

    setUp(() async {
      // Create two isolated in-memory Drift SQLite databases for Phone A and Phone B
      dbPhoneA = AppDatabase.forTesting(NativeDatabase.memory());
      dbPhoneB = AppDatabase.forTesting(NativeDatabase.memory());

      syncDaoA = SyncDao(dbPhoneA);
      syncDaoB = SyncDao(dbPhoneB);
      invDaoA = InventoryDao(dbPhoneA);
      invDaoB = InventoryDao(dbPhoneB);

      // Seed initial synchronized state: 10.0 kg of Basmati Rice on both phones
      final initialRice = LocalInventoryItemsCompanion(
        id: const Value(riceItemId),
        homeId: const Value(homeId),
        name: const Value('Basmati Rice'),
        quantity: const Value(10.0),
        unit: const Value('kg'),
        minimumQuantity: const Value(2.0),
        stockStatus: const Value('IN_STOCK'),
        categoryName: const Value('Grains'),
        updatedAt: Value(DateTime.now()),
      );

      await invDaoA.upsertItem(initialRice);
      await invDaoB.upsertItem(initialRice);
    });

    tearDown(() async {
      await dbPhoneA.close();
      await dbPhoneB.close();
    });

    test('Requirement 12: Phone A offline (+5kg) and Phone B offline (-1kg) converge to 14kg', () async {
      // ──── Step 1: Phone A goes offline and adds 5kg ────
      final currentA = await invDaoA.getItemById(riceItemId);
      expect(currentA!.quantity, equals(10.0));

      final newQtyA = currentA.quantity + 5.0; // 15.0kg
      await invDaoA.updateLocalStock(riceItemId, newQtyA, 'IN_STOCK');

      final opIdA = 'op-phoneA-${uuid.v4()}';
      await syncDaoA.addToSyncQueue(SyncQueueEntriesCompanion(
        operationId: Value(opIdA),
        operationType: const Value(SyncOperationType.stockIn),
        entityType: const Value(SyncEntityType.inventoryItem),
        entityId: const Value(riceItemId),
        payload: Value(jsonEncode({
          'transactionType': 'STOCK_IN',
          'quantityChange': 5.0,
          'reason': 'Bought 5kg from grocery',
        })),
        createdAt: Value(DateTime.now().toUtc()),
        homeId: const Value(homeId),
      ));

      // Local UI on Phone A reflects 15.0kg immediately
      final itemAfterModA = await invDaoA.getItemById(riceItemId);
      expect(itemAfterModA!.quantity, equals(15.0));

      // ──── Step 2: Phone B goes offline and consumes 1kg ────
      final currentB = await invDaoB.getItemById(riceItemId);
      expect(currentB!.quantity, equals(10.0));

      final newQtyB = currentB.quantity - 1.0; // 9.0kg
      await invDaoB.updateLocalStock(riceItemId, newQtyB, 'IN_STOCK');

      final opIdB = 'op-phoneB-${uuid.v4()}';
      await syncDaoB.addToSyncQueue(SyncQueueEntriesCompanion(
        operationId: Value(opIdB),
        operationType: const Value(SyncOperationType.stockOut),
        entityType: const Value(SyncEntityType.inventoryItem),
        entityId: const Value(riceItemId),
        payload: Value(jsonEncode({
          'transactionType': 'STOCK_OUT',
          'quantityChange': 1.0,
          'reason': 'Dinner consumption',
        })),
        createdAt: Value(DateTime.now().toUtc()),
        homeId: const Value(homeId),
      ));

      // Local UI on Phone B reflects 9.0kg immediately
      final itemAfterModB = await invDaoB.getItemById(riceItemId);
      expect(itemAfterModB!.quantity, equals(9.0));

      // ──── Step 3: Phone A reconnects and pushes opA ────
      final pendingA = await syncDaoA.getPendingOperations();
      expect(pendingA.length, equals(1));
      expect(pendingA.first.operationId, equals(opIdA));

      // Mark syncing -> synced
      await syncDaoA.markSyncing(opIdA);
      await syncDaoA.markSynced(opIdA);

      // Server state becomes 10.0 + 5.0 = 15.0 kg (Version 1)
      double serverStock = 10.0 + 5.0; // 15.0
      int serverVersion = 1;

      // Phone A pulls changes (returns 15kg, version 1)
      await syncDaoA.applyPullChangesInTransaction(
        homeId: homeId,
        categories: [],
        inventoryItems: [
          LocalInventoryItemsCompanion(
            id: const Value(riceItemId),
            homeId: const Value(homeId),
            name: const Value('Basmati Rice'),
            quantity: Value(serverStock),
            unit: const Value('kg'),
            stockStatus: const Value('IN_STOCK'),
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
        nextServerVersion: serverVersion,
      );

      final postSyncA = await invDaoA.getItemById(riceItemId);
      expect(postSyncA!.quantity, equals(15.0));

      // ──── Step 4: Phone B reconnects and pushes opB ────
      final pendingB = await syncDaoB.getPendingOperations();
      expect(pendingB.length, equals(1));
      expect(pendingB.first.operationId, equals(opIdB));

      await syncDaoB.markSyncing(opIdB);
      await syncDaoB.markSynced(opIdB);

      // Server applies delta with lock: 15.0 - 1.0 = 14.0 kg (Version 2)
      serverStock = serverStock - 1.0; // 14.0
      serverVersion = 2;

      // Phone B pulls server state (reconciles with server version 2)
      await syncDaoB.applyPullChangesInTransaction(
        homeId: homeId,
        categories: [],
        inventoryItems: [
          LocalInventoryItemsCompanion(
            id: const Value(riceItemId),
            homeId: const Value(homeId),
            name: const Value('Basmati Rice'),
            quantity: Value(serverStock),
            unit: const Value('kg'),
            stockStatus: const Value('IN_STOCK'),
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
        nextServerVersion: serverVersion,
      );

      final finalStockPhoneB = await invDaoB.getItemById(riceItemId);
      expect(finalStockPhoneB!.quantity, equals(14.0), reason: 'Phone B should reconcile to 14.0kg');

      // ──── Step 5: Phone A pulls incremental update (Version 2) ────
      await syncDaoA.applyPullChangesInTransaction(
        homeId: homeId,
        categories: [],
        inventoryItems: [
          LocalInventoryItemsCompanion(
            id: const Value(riceItemId),
            homeId: const Value(homeId),
            name: const Value('Basmati Rice'),
            quantity: Value(serverStock),
            unit: const Value('kg'),
            stockStatus: const Value('IN_STOCK'),
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
        nextServerVersion: serverVersion,
      );

      final finalStockPhoneA = await invDaoA.getItemById(riceItemId);
      expect(finalStockPhoneA!.quantity, equals(14.0), reason: 'Phone A should reconcile to 14.0kg');

      // ──── FINAL ASSERTION: BOTH DEVICES HAVE EXACTLY 14.0 KG ────
      expect(finalStockPhoneA.quantity, equals(finalStockPhoneB.quantity));
      expect(finalStockPhoneA.quantity, equals(14.0));
    });

    test('Requirement 17: App crash / restart recovers stranded SYNCING operations to PENDING', () async {
      // Simulate an operation that was in-flight when app crashed or was killed
      await syncDaoA.addToSyncQueue(SyncQueueEntriesCompanion(
        operationId: const Value('op-stranded-in-flight'),
        operationType: const Value(SyncOperationType.updateItem),
        entityType: const Value(SyncEntityType.inventoryItem),
        entityId: const Value(riceItemId),
        payload: const Value('{}'),
        createdAt: Value(DateTime.now().toUtc()),
        homeId: const Value(homeId),
        status: const Value('SYNCING'), // Stranded in-flight!
      ));

      // Verify that getPendingOperations would ignore it before recovery
      final beforeRecovery = await syncDaoA.getPendingOperations();
      expect(beforeRecovery.isEmpty, isTrue);

      // Perform crash recovery on restart
      final recoveredCount = await syncDaoA.recoverIncompleteSyncingOperations();
      expect(recoveredCount, equals(1));

      // Verify the operation is now PENDING and ready for sync
      final afterRecovery = await syncDaoA.getPendingOperations();
      expect(afterRecovery.length, equals(1));
      expect(afterRecovery.first.operationId, equals('op-stranded-in-flight'));
      expect(afterRecovery.first.status, equals('PENDING'));
    });

    test('Requirement 16: Queue diagnostics summary tracks pending, syncing, synced, failed, conflict', () async {
      final now = DateTime.now().toUtc();

      // Add one of each status to Phone A's queue
      await syncDaoA.addToSyncQueue(SyncQueueEntriesCompanion(
        operationId: const Value('diag-pending'),
        operationType: const Value('CREATE_ITEM'),
        entityType: const Value('INVENTORY_ITEM'),
        entityId: const Value('item-1'),
        payload: const Value('{}'),
        createdAt: Value(now),
        homeId: const Value(homeId),
        status: const Value('PENDING'),
      ));

      await syncDaoA.addToSyncQueue(SyncQueueEntriesCompanion(
        operationId: const Value('diag-syncing'),
        operationType: const Value('UPDATE_ITEM'),
        entityType: const Value('INVENTORY_ITEM'),
        entityId: const Value('item-2'),
        payload: const Value('{}'),
        createdAt: Value(now),
        homeId: const Value(homeId),
        status: const Value('SYNCING'),
      ));

      await syncDaoA.addToSyncQueue(SyncQueueEntriesCompanion(
        operationId: const Value('diag-synced'),
        operationType: const Value('STOCK_IN'),
        entityType: const Value('INVENTORY_ITEM'),
        entityId: const Value('item-3'),
        payload: const Value('{}'),
        createdAt: Value(now),
        homeId: const Value(homeId),
        status: const Value('SYNCED'),
        serverAcknowledgedAt: Value(now),
      ));

      await syncDaoA.addToSyncQueue(SyncQueueEntriesCompanion(
        operationId: const Value('diag-failed'),
        operationType: const Value('STOCK_OUT'),
        entityType: const Value('INVENTORY_ITEM'),
        entityId: const Value('item-4'),
        payload: const Value('{}'),
        createdAt: Value(now),
        homeId: const Value(homeId),
        status: const Value('FAILED'),
        lastError: const Value('Connection timeout'),
        retryCount: const Value(2),
      ));

      await syncDaoA.addToSyncQueue(SyncQueueEntriesCompanion(
        operationId: const Value('diag-conflict'),
        operationType: const Value('UPDATE_ITEM'),
        entityType: const Value('INVENTORY_ITEM'),
        entityId: const Value('item-5'),
        payload: const Value('{}'),
        createdAt: Value(now),
        homeId: const Value(homeId),
        status: const Value('CONFLICT'),
        lastError: const Value('Concurrent version conflict on server'),
      ));

      // Verify diagnostics summary
      final summary = await syncDaoA.getQueueSummary();
      expect(summary.pending, equals(1));
      expect(summary.syncing, equals(1));
      expect(summary.synced, equals(1));
      expect(summary.failed, equals(1));
      expect(summary.conflict, equals(1));
      expect(summary.totalTracked, equals(5));
      expect(summary.hasFailures, isTrue);
      expect(summary.hasConflicts, isTrue);

      // Verify retryAllFailedOperations resets failed and conflict to PENDING
      final retried = await syncDaoA.retryAllFailedOperations();
      expect(retried, equals(2)); // failed + conflict

      final afterRetrySummary = await syncDaoA.getQueueSummary();
      expect(afterRetrySummary.pending, equals(3)); // 1 original + 2 retried
      expect(afterRetrySummary.failed, equals(0));
      expect(afterRetrySummary.conflict, equals(0));

      // Verify clearSyncedHistory clears SYNCED without touching pending
      final cleared = await syncDaoA.clearSyncedHistory();
      expect(cleared, equals(1));

      final finalSummary = await syncDaoA.getQueueSummary();
      expect(finalSummary.synced, equals(0));
      expect(finalSummary.pending, equals(3));
    });

    test('Requirement 15: Local unpushed modifications are protected from being overwritten by stale pull', () async {
      const itemId = 'protected-item-001';

      // 1. Initial item in Phone A
      await invDaoA.upsertItem(LocalInventoryItemsCompanion(
        id: const Value(itemId),
        homeId: const Value(homeId),
        name: const Value('Organic Eggs'),
        quantity: const Value(12.0),
        unit: const Value('pcs'),
        stockStatus: const Value('IN_STOCK'),
        updatedAt: Value(DateTime.now()),
      ));

      // 2. User locally changes quantity to 6 offline
      await invDaoA.updateLocalStock(itemId, 6.0, 'IN_STOCK');
      await syncDaoA.addToSyncQueue(SyncQueueEntriesCompanion(
        operationId: const Value('op-unpushed-eggs'),
        operationType: const Value(SyncOperationType.stockOut),
        entityType: const Value(SyncEntityType.inventoryItem),
        entityId: const Value(itemId),
        payload: const Value('{"quantityChange": 6.0}'),
        createdAt: Value(DateTime.now().toUtc()),
        homeId: const Value(homeId),
        status: const Value('PENDING'),
      ));

      // 3. Stale pull arrives with old server quantity 12.0
      await syncDaoA.applyPullChangesInTransaction(
        homeId: homeId,
        categories: [],
        inventoryItems: [
          LocalInventoryItemsCompanion(
            id: const Value(itemId),
            homeId: const Value(homeId),
            name: const Value('Organic Eggs'),
            quantity: const Value(12.0), // Stale
            unit: const Value('pcs'),
            stockStatus: const Value('IN_STOCK'),
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
        nextServerVersion: 5,
      );

      // 4. Verify local changes were preserved (still 6.0, not overwritten by 12.0)
      final protectedItem = await invDaoA.getItemById(itemId);
      expect(protectedItem!.quantity, equals(6.0));
    });
  });
}
