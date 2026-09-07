import 'package:flutter_test/flutter_test.dart';
import 'package:homestock/core/sync/sync_operation.dart';
import 'package:homestock/core/sync/sync_status.dart';

void main() {
  group('SyncOperation Models', () {
    test('SyncOperation serialization and deserialization', () {
      final now = DateTime.now();
      final op = SyncOperation(
        operationId: 'test-op-123',
        operationType: SyncOperationType.stockOut,
        entityType: SyncEntityType.inventoryItem,
        entityId: 'item-uuid-456',
        payload: {
          'transactionType': 'STOCK_OUT',
          'quantityChange': 2.5,
          'reason': 'Cooking dinner',
        },
        createdAt: now,
        homeId: 'home-uuid-789',
      );

      final json = op.toJson();
      expect(json['operationId'], 'test-op-123');
      expect(json['operationType'], SyncOperationType.stockOut);
      expect(json['entityType'], SyncEntityType.inventoryItem);
      expect(json['entityId'], 'item-uuid-456');
      expect(json['homeId'], 'home-uuid-789');

      final deserialized = SyncOperation.fromJson(json);
      expect(deserialized.operationId, op.operationId);
      expect(deserialized.operationType, op.operationType);
      expect(deserialized.entityType, op.entityType);
      expect(deserialized.entityId, op.entityId);
      expect(deserialized.homeId, op.homeId);
      expect(deserialized.payload['quantityChange'], 2.5);
    });

    test('SyncOperationResult parsing correctly handles status', () {
      final syncedResult = SyncOperationResult.fromJson({
        'operationId': 'op-1',
        'status': 'SYNCED',
      });
      expect(syncedResult.isSynced, isTrue);
      expect(syncedResult.operationId, 'op-1');

      final alreadyProcessedResult = SyncOperationResult.fromJson({
        'operationId': 'op-2',
        'status': 'ALREADY_PROCESSED',
      });
      expect(alreadyProcessedResult.isSynced, isTrue);

      final failedResult = SyncOperationResult.fromJson({
        'operationId': 'op-3',
        'status': 'FAILED',
        'errorMessage': 'Home not found',
      });
      expect(failedResult.isSynced, isFalse);
      expect(failedResult.errorMessage, 'Home not found');
    });

    test('SyncPullResponse properly parses incremental data maps', () {
      final pull = SyncPullResponse.fromJson({
        'inventoryItems': [
          {'id': 'item-1', 'name': 'Milk', 'quantity': 2.0}
        ],
        'stockTransactions': [
          {'id': 'tx-1', 'transactionType': 'STOCK_IN', 'quantityChange': 2.0}
        ],
        'shoppingListItems': [
          {'id': 'shop-1', 'itemName': 'Eggs', 'quantity': 12.0}
        ],
        'shoppingLists': [
          {'id': 'list-1', 'name': 'Default'}
        ],
        'purchases': [],
        'categories': [
          {'id': 'cat-1', 'name': 'Dairy'}
        ],
        'stores': [],
        'serverTimestamp': '2026-09-07T12:00:00Z',
      });

      expect(pull.isEmpty, isFalse);
      expect(pull.inventoryItems.length, 1);
      expect(pull.inventoryItems.first['name'], 'Milk');
      expect(pull.stockTransactions.length, 1);
      expect(pull.shoppingListItems.length, 1);
      expect(pull.shoppingLists.length, 1);
      expect(pull.categories.length, 1);
      expect(pull.serverTimestamp, '2026-09-07T12:00:00Z');
    });
  });

  group('SyncState and NetworkStatus', () {
    test('SyncState offline message displays helpful guidance', () {
      const offlineState = SyncState(
        status: NetworkStatus.offline,
        pendingOperationsCount: 3,
      );

      expect(offlineState.isOffline, isTrue);
      expect(offlineState.isOnline, isFalse);
      expect(offlineState.statusMessage, contains('Offline'));
    });

    test('SyncState online status shows synced clean status', () {
      const onlineState = SyncState(
        status: NetworkStatus.online,
        pendingOperationsCount: 0,
      );

      expect(onlineState.isOnline, isTrue);
      expect(offlineStateStatusMessage(onlineState), 'Online');
    });

    test('SyncState syncing status reflects active sync', () {
      const syncingState = SyncState(
        status: NetworkStatus.syncing,
        isSyncInProgress: true,
      );

      expect(syncingState.isSyncing, isTrue);
      expect(syncingState.statusMessage, 'Syncing...');
    });
  });
}

String offlineStateStatusMessage(SyncState state) => state.statusMessage;
