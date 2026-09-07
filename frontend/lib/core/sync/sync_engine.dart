import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../database/daos/inventory_dao.dart';
import '../database/daos/purchase_dao.dart';
import '../database/daos/shopping_dao.dart';
import '../database/daos/sync_dao.dart';
import '../network/api_client.dart';
import 'connectivity_monitor.dart';
import 'sync_operation.dart';
import 'sync_status.dart';

/// Central synchronization engine that manages bidirectional data flow
/// between the local SQLite database and the remote Spring Boot API.
///
/// Responsibilities:
/// - Push pending local operations to server (batch POST /api/v1/sync)
/// - Pull server changes since last sync (GET /api/v1/sync?homeId=&since=)
/// - Auto-sync on connectivity restoration
/// - Exponential backoff retry for failed operations
/// - Idempotency via operationId
class SyncEngine {
  final AppDatabase _db;
  final ApiClient _apiClient;
  final ConnectivityMonitor _connectivity;

  late final SyncDao _syncDao;
  late final InventoryDao _inventoryDao;
  late final ShoppingDao _shoppingDao;
  late final PurchaseDao _purchaseDao;

  final StreamController<SyncState> _stateController =
      StreamController<SyncState>.broadcast();

  SyncState _currentState = const SyncState();
  bool _isSyncing = false;
  Timer? _retryTimer;

  SyncEngine({
    required AppDatabase database,
    required ApiClient apiClient,
    required ConnectivityMonitor connectivity,
  })  : _db = database,
        _apiClient = apiClient,
        _connectivity = connectivity {
    _syncDao = SyncDao(_db);
    _inventoryDao = InventoryDao(_db);
    _shoppingDao = ShoppingDao(_db);
    _purchaseDao = PurchaseDao(_db);
  }

  /// Stream of sync state changes for UI consumption.
  Stream<SyncState> get stateStream => _stateController.stream;

  /// Current sync state.
  SyncState get currentState => _currentState;

  /// Start automatic synchronization.
  /// Listens for connectivity changes and triggers sync on restoration.
  void startAutoSync() {
    _connectivity.start();
    _connectivity.onConnectivityRestored = () {
      if (kDebugMode) print('[SyncEngine] Connectivity restored — starting sync');
      syncAll();
    };

    // Watch pending count to keep state updated
    _syncDao.watchPendingCount().listen((count) {
      _updateState(_currentState.copyWith(pendingOperationsCount: count));
    });

    // Update status based on connectivity
    _connectivity.statusStream.listen((status) {
      if (status == NetworkStatus.online && !_isSyncing) {
        _updateState(_currentState.copyWith(status: NetworkStatus.online));
      } else if (status == NetworkStatus.offline) {
        _updateState(_currentState.copyWith(status: NetworkStatus.offline));
      }
    });
  }

  /// Full sync cycle for all homes the user belongs to.
  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _connectivity.setSyncing();
    _updateState(_currentState.copyWith(
      status: NetworkStatus.syncing,
      isSyncInProgress: true,
    ));

    try {
      // Push all pending operations
      await _pushPendingOperations();

      // Pull changes for each home: localHomes, pending operations, and sync metadata
      final homes = await (_db.select(_db.localHomes)).get();
      final homeIds = homes.map((h) => h.id).toSet();

      final pendingOps = await _syncDao.getPendingOperations();
      for (final p in pendingOps) {
        if (p.homeId.isNotEmpty) homeIds.add(p.homeId);
      }

      final metadata = await (_db.select(_db.syncMetadataEntries)).get();
      for (final m in metadata) {
        if (m.homeId.isNotEmpty) homeIds.add(m.homeId);
      }

      for (final homeId in homeIds) {
        await _pullServerChanges(homeId);
      }

      _updateState(_currentState.copyWith(
        status: NetworkStatus.online,
        lastSyncedAt: DateTime.now(),
        isSyncInProgress: false,
        lastError: null,
      ));

      // Cleanup synced operations
      await _syncDao.cleanupSyncedOperations();
    } catch (e) {
      if (kDebugMode) print('[SyncEngine] Sync failed: $e');
      _updateState(_currentState.copyWith(
        status: _connectivity.isOnline
            ? NetworkStatus.online
            : NetworkStatus.offline,
        isSyncInProgress: false,
        lastError: e.toString(),
      ));
      // Schedule retry
      _scheduleRetry();
    } finally {
      _isSyncing = false;
      _connectivity.setSyncComplete();
    }
  }

  /// Sync operations for a specific home.
  Future<void> syncHome(String homeId) async {
    if (_isSyncing) return;
    if (!_connectivity.isOnline) return;

    _isSyncing = true;
    _connectivity.setSyncing();
    _updateState(_currentState.copyWith(
      status: NetworkStatus.syncing,
      isSyncInProgress: true,
    ));

    try {
      await _pushPendingOperationsForHome(homeId);
      await _pullServerChanges(homeId);

      _updateState(_currentState.copyWith(
        status: NetworkStatus.online,
        lastSyncedAt: DateTime.now(),
        isSyncInProgress: false,
        lastError: null,
      ));

      await _syncDao.cleanupSyncedOperations();
    } catch (e) {
      if (kDebugMode) print('[SyncEngine] Home sync failed: $e');
      _updateState(_currentState.copyWith(
        status: _connectivity.isOnline
            ? NetworkStatus.online
            : NetworkStatus.offline,
        isSyncInProgress: false,
        lastError: e.toString(),
      ));
    } finally {
      _isSyncing = false;
      _connectivity.setSyncComplete();
    }
  }

  /// Attempt to sync a single pending operation immediately (if online).
  Future<void> trySyncImmediate() async {
    if (!_connectivity.isOnline || _isSyncing) return;
    // Non-blocking: push in background
    Future.microtask(() => syncAll());
  }

  // ──── PUSH ────

  Future<void> _pushPendingOperations() async {
    final pending = await _syncDao.getPendingOperations();
    if (pending.isEmpty) return;

    // Also grab failed operations for retry
    final failed = await _syncDao.getFailedOperations();
    final allOps = [...pending, ...failed];

    if (allOps.isEmpty) return;

    // Batch by home for efficiency
    final byHome = <String, List<SyncQueueEntry>>{};
    for (final op in allOps) {
      byHome.putIfAbsent(op.homeId, () => []).add(op);
    }

    for (final entry in byHome.entries) {
      await _pushBatch(entry.value);
    }
  }

  Future<void> _pushPendingOperationsForHome(String homeId) async {
    final pending = await _syncDao.getPendingOperationsForHome(homeId);
    final failed = await _syncDao.getFailedOperations();
    final homeOps = [...pending, ...failed.where((o) => o.homeId == homeId)];

    if (homeOps.isNotEmpty) {
      await _pushBatch(homeOps);
    }
  }

  Future<void> _pushBatch(List<SyncQueueEntry> operations) async {
    if (operations.isEmpty) return;

    // Mark all as syncing
    for (final op in operations) {
      await _syncDao.markSyncing(op.operationId);
    }

    // Build request payload
    final syncOps = operations.map((op) {
      Map<String, dynamic> payload;
      try {
        payload = jsonDecode(op.payload) as Map<String, dynamic>;
      } catch (_) {
        payload = {};
      }

      return {
        'operationId': op.operationId,
        'operationType': op.operationType,
        'entityType': op.entityType,
        'entityId': op.entityId,
        'payload': payload,
        'createdAt': op.createdAt.toUtc().toIso8601String(),
      };
    }).toList();

    try {
      final response = await _apiClient.dio.post(
        '/sync',
        data: {
          'homeId': operations.first.homeId,
          'operations': syncOps,
        },
      );

      final responseData = response.data['data'];
      if (responseData != null && responseData['results'] != null) {
        final results = responseData['results'] as List;
        for (final result in results) {
          final opId = result['operationId'] as String;
          final status = result['status'] as String;

          switch (status) {
            case 'SYNCED':
            case 'ALREADY_PROCESSED':
              await _syncDao.markSynced(opId);
              break;
            case 'CONFLICT':
              await _syncDao.markConflict(
                  opId, result['errorMessage'] as String? ?? 'Conflict');
              break;
            case 'FAILED':
            default:
              await _syncDao.incrementRetryCount(opId);
              await _syncDao.markFailed(
                  opId, result['errorMessage'] as String? ?? 'Unknown error');
              break;
          }

          // If server returned the entity, update local DB
          if (result['serverEntity'] != null) {
            final serverEntity =
                result['serverEntity'] as Map<String, dynamic>;
            final entityType = operations
                .firstWhere((o) => o.operationId == opId)
                .entityType;
            await _updateLocalFromServerEntity(entityType, serverEntity);
          }
        }
      } else {
        // If server doesn't return per-operation results, mark all synced
        for (final op in operations) {
          await _syncDao.markSynced(op.operationId);
        }
      }
    } catch (e) {
      if (kDebugMode) print('[SyncEngine] Push failed: $e');
      // Mark all operations back to pending for retry
      for (final op in operations) {
        await _syncDao.incrementRetryCount(op.operationId);
        await _syncDao.markFailed(op.operationId, e.toString());
      }
      rethrow;
    }
  }

  // ──── PULL ────

  Future<void> _pullServerChanges(String homeId) async {
    final lastSynced = await _syncDao.getLastSyncedAt(homeId);
    final sinceParam = lastSynced?.toUtc().toIso8601String() ??
        DateTime.fromMillisecondsSinceEpoch(0).toUtc().toIso8601String();

    try {
      final response = await _apiClient.dio.get(
        '/sync',
        queryParameters: {
          'homeId': homeId,
          'since': sinceParam,
        },
      );

      final data = response.data['data'];
      if (data == null) return;

      final pullResponse = SyncPullResponse.fromJson(data);

      // Apply changes to local database
      await _applyPullResponse(homeId, pullResponse);

      // Update last synced timestamp
      final serverTimestamp = DateTime.parse(pullResponse.serverTimestamp);
      await _syncDao.updateLastSyncedAt(homeId, serverTimestamp);
    } catch (e) {
      if (kDebugMode) print('[SyncEngine] Pull failed for home $homeId: $e');
      // Don't rethrow — pull failures shouldn't block push
    }
  }

  Future<void> _applyPullResponse(
      String homeId, SyncPullResponse pullResponse) async {
    if (pullResponse.isEmpty) return;

    // Apply categories
    if (pullResponse.categories.isNotEmpty) {
      final categories = pullResponse.categories.map((json) {
        return LocalCategoriesCompanion(
          id: Value(json['id'] as String),
          homeId: Value(homeId),
          name: Value(json['name'] as String? ?? ''),
          iconName: Value(json['icon'] as String? ?? 'category'),
          colorHex: Value(json['colorHex'] as String? ?? '#6366F1'),
          sortOrder: Value(json['displayOrder'] as int? ?? 0),
          updatedAt: Value(DateTime.now()),
        );
      }).toList();
      await _inventoryDao.upsertCategories(categories);
    }

    // Apply inventory items
    if (pullResponse.inventoryItems.isNotEmpty) {
      final items = pullResponse.inventoryItems.map((json) {
        return LocalInventoryItemsCompanion(
          id: Value(json['id'] as String),
          homeId: Value(homeId),
          categoryId: Value(json['categoryId'] as String?),
          categoryName: Value(json['categoryName'] as String? ?? 'General'),
          categoryIcon: Value(json['categoryIcon'] as String? ?? 'category'),
          categoryColor: Value(json['categoryColor'] as String? ?? '#6366F1'),
          name: Value(json['name'] as String? ?? ''),
          brand: Value(json['brand'] as String?),
          quantity: Value((json['quantity'] as num?)?.toDouble() ?? 0.0),
          unit: Value(json['unit'] as String? ?? 'pcs'),
          minimumQuantity:
              Value((json['minimumQuantity'] as num?)?.toDouble() ?? 1.0),
          maximumQuantity:
              Value((json['maximumQuantity'] as num?)?.toDouble()),
          storageLocation: Value(json['storageLocation'] as String?),
          purchasePrice:
              Value((json['purchasePrice'] as num?)?.toDouble()),
          purchaseDate: Value(json['purchaseDate'] as String?),
          expiryDate: Value(json['expiryDate'] as String?),
          imageUrl: Value(json['imageUrl'] as String?),
          notes: Value(json['notes'] as String?),
          stockStatus: Value(json['stockStatus'] as String? ?? 'IN_STOCK'),
          expiryStatus: Value(json['expiryStatus'] as String? ?? 'SAFE'),
          daysUntilExpiry: Value(json['daysUntilExpiry'] as int?),
          isDeleted: Value(json['isDeleted'] as bool? ?? false),
          isLocalOnly: const Value(false),
          updatedAt: Value(DateTime.now()),
        );
      }).toList();
      await _inventoryDao.upsertItems(items);
    }

    // Apply stock transactions
    if (pullResponse.stockTransactions.isNotEmpty) {
      final txs = pullResponse.stockTransactions.map((json) {
        return LocalStockTransactionsCompanion(
          id: Value(json['id'] as String),
          inventoryItemId: Value(json['itemId'] as String? ?? ''),
          itemName: Value(json['itemName'] as String? ?? ''),
          userName: Value(json['userName'] as String? ?? ''),
          transactionType: Value(json['transactionType'] as String? ?? ''),
          quantityChange:
              Value((json['quantityChange'] as num?)?.toDouble() ?? 0.0),
          previousQuantity:
              Value((json['previousQuantity'] as num?)?.toDouble() ?? 0.0),
          newQuantity:
              Value((json['newQuantity'] as num?)?.toDouble() ?? 0.0),
          unit: Value(json['unit'] as String? ?? 'pcs'),
          reason: Value(json['reason'] as String?),
          createdAt: Value(json['createdAt'] as String? ?? ''),
          isLocalOnly: const Value(false),
        );
      }).toList();
      await _inventoryDao.upsertTransactions(txs);
    }

    // Apply shopping lists
    if (pullResponse.shoppingLists.isNotEmpty) {
      for (final json in pullResponse.shoppingLists) {
        await _shoppingDao.upsertShoppingList(LocalShoppingListsCompanion(
          id: Value(json['id'] as String),
          homeId: Value(homeId),
          name: Value(json['name'] as String? ?? 'Home Shopping List'),
          isDefault: Value(json['isDefault'] as bool? ?? true),
          updatedAt: Value(DateTime.now()),
        ));
      }
    }

    // Apply shopping list items
    if (pullResponse.shoppingListItems.isNotEmpty) {
      final items = pullResponse.shoppingListItems.map((json) {
        return LocalShoppingListItemsCompanion(
          id: Value(json['id'] as String),
          shoppingListId: Value(json['shoppingListId'] as String? ?? ''),
          inventoryItemId: Value(json['inventoryItemId'] as String?),
          itemName: Value(json['itemName'] as String? ?? ''),
          categoryName: Value(json['categoryName'] as String?),
          categoryIcon: Value(json['categoryIcon'] as String? ?? 'category'),
          categoryColor: Value(json['categoryColor'] as String? ?? '#6366F1'),
          quantity: Value((json['quantity'] as num?)?.toDouble() ?? 1.0),
          unit: Value(json['unit'] as String? ?? 'pcs'),
          isCompleted: Value(json['isCompleted'] as bool? ?? false),
          isAutoGenerated: Value(json['isAutoGenerated'] as bool? ?? false),
          addedByName: Value(json['addedByName'] as String? ?? ''),
          completedByName: Value(json['completedByName'] as String?),
          completedAt: Value(json['completedAt'] as String?),
          notes: Value(json['notes'] as String?),
          isLocalOnly: const Value(false),
          isDeleted: const Value(false),
          updatedAt: Value(DateTime.now()),
        );
      }).toList();
      await _shoppingDao.upsertShoppingItems(items);
    }

    // Apply purchases
    if (pullResponse.purchases.isNotEmpty) {
      final purchases = pullResponse.purchases.map((json) {
        return LocalPurchasesCompanion(
          id: Value(json['id'] as String),
          homeId: Value(homeId),
          storeId: Value(json['storeId'] as String?),
          storeName: Value(json['storeName'] as String?),
          recordedByName: Value(json['recordedByName'] as String? ?? ''),
          purchaseDate: Value(json['purchaseDate'] as String? ?? ''),
          totalAmount:
              Value((json['totalAmount'] as num?)?.toDouble() ?? 0.0),
          currency: Value(json['currency'] as String? ?? 'INR'),
          notes: Value(json['notes'] as String?),
          isLocalOnly: const Value(false),
          updatedAt: Value(DateTime.now()),
        );
      }).toList();
      await _purchaseDao.upsertPurchases(purchases);
    }

    // Apply purchase items
    if (pullResponse.purchaseItems.isNotEmpty) {
      final items = pullResponse.purchaseItems.map((json) {
        return LocalPurchaseItemsCompanion(
          id: Value(json['id'] as String),
          purchaseId: Value(json['purchaseId'] as String? ?? ''),
          inventoryItemId: Value(json['inventoryItemId'] as String?),
          itemName: Value(json['itemName'] as String? ?? ''),
          categoryName: Value(json['categoryName'] as String?),
          quantity: Value((json['quantity'] as num?)?.toDouble() ?? 1.0),
          unit: Value(json['unit'] as String? ?? 'pcs'),
          unitPrice:
              Value((json['unitPrice'] as num?)?.toDouble() ?? 0.0),
          totalPrice:
              Value((json['totalPrice'] as num?)?.toDouble() ?? 0.0),
        );
      }).toList();
      await _purchaseDao.upsertPurchaseItems(items);
    }

    // Apply stores
    if (pullResponse.stores.isNotEmpty) {
      final stores = pullResponse.stores.map((json) {
        return LocalStoresCompanion(
          id: Value(json['id'] as String),
          homeId: Value(homeId),
          name: Value(json['name'] as String? ?? ''),
          location: Value(json['location'] as String?),
          updatedAt: Value(DateTime.now()),
        );
      }).toList();
      await _purchaseDao.upsertStores(stores);
    }
  }

  Future<void> _updateLocalFromServerEntity(
      String entityType, Map<String, dynamic> json) async {
    switch (entityType) {
      case SyncEntityType.inventoryItem:
        await _inventoryDao.upsertItem(LocalInventoryItemsCompanion(
          id: Value(json['id'] as String),
          homeId: Value(json['homeId'] as String? ?? ''),
          name: Value(json['name'] as String? ?? ''),
          quantity: Value((json['quantity'] as num?)?.toDouble() ?? 0.0),
          stockStatus: Value(json['stockStatus'] as String? ?? 'IN_STOCK'),
          isLocalOnly: const Value(false),
          updatedAt: Value(DateTime.now()),
        ));
        break;
      case SyncEntityType.shoppingListItem:
        await _shoppingDao.upsertShoppingItem(LocalShoppingListItemsCompanion(
          id: Value(json['id'] as String),
          isLocalOnly: const Value(false),
          updatedAt: Value(DateTime.now()),
        ));
        break;
      default:
        break;
    }
  }

  // ──── RETRY ────

  /// Exponential backoff: 2s, 5s, 15s, 30s, 60s
  static const _retryDelays = [2, 5, 15, 30, 60];

  void _scheduleRetry() {
    _retryTimer?.cancel();
    final pendingCount = _currentState.pendingOperationsCount;
    if (pendingCount == 0) return;

    final retryIndex = min(pendingCount - 1, _retryDelays.length - 1);
    final delay = Duration(seconds: _retryDelays[retryIndex]);

    _retryTimer = Timer(delay, () {
      if (_connectivity.isOnline && !_isSyncing) {
        syncAll();
      }
    });
  }

  void _updateState(SyncState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  /// Dispose all resources.
  void dispose() {
    _retryTimer?.cancel();
    _stateController.close();
  }
}
