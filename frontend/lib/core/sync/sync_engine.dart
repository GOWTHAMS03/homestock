import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../database/app_database.dart';
import '../database/daos/inventory_dao.dart';
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
/// - Auto-sync on connectivity restoration and app resume
/// - Exponential backoff retry for failed operations
/// - Idempotency via operationId
/// - 8-state strict lifecycle pipeline
class SyncEngine with WidgetsBindingObserver {
  final AppDatabase _db;
  final ApiClient _apiClient;
  final ConnectivityMonitor _connectivity;

  late final SyncDao _syncDao;
  late final InventoryDao _inventoryDao;

  final StreamController<SyncState> _stateController =
      StreamController<SyncState>.broadcast();

  SyncState _currentState = const SyncState();
  bool _isSyncing = false;
  bool _hasQueuedSyncRequest = false;
  Timer? _retryTimer;
  Completer<void>? _activeSyncAllCompleter;
  final Set<String> _activeHomeSyncs = {};
  bool _isAutoSyncStarted = false;

  SyncEngine({
    required AppDatabase database,
    required ApiClient apiClient,
    required ConnectivityMonitor connectivity,
  })  : _db = database,
        _apiClient = apiClient,
        _connectivity = connectivity {
    _syncDao = SyncDao(_db);
    _inventoryDao = InventoryDao(_db);
  }

  /// Stream of sync state changes for UI consumption.
  Stream<SyncState> get stateStream => _stateController.stream;

  /// Current sync state.
  SyncState get currentState => _currentState;

  /// Start automatic synchronization.
  /// Listens for connectivity changes and triggers sync on restoration.
  void startAutoSync() {
    if (_isAutoSyncStarted) return;
    _isAutoSyncStarted = true;

    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}

    _connectivity.start();
    _connectivity.onConnectivityRestored = () {
      if (kDebugMode) print('[SyncEngine] Connectivity restored — starting sync');
      _updateState(_currentState.copyWith(syncStatus: SyncStatus.networkAvailable));
      syncAll();
    };

    // Watch pending count to keep state updated
    _syncDao.watchPendingCount().listen((count) {
      _updateState(_currentState.copyWith(pendingOperationsCount: count));
    });

    // Update status based on connectivity
    _connectivity.statusStream.listen((status) {
      if (status == NetworkStatus.online && !_isSyncing) {
        _updateState(_currentState.copyWith(
          syncStatus: _currentState.syncStatus == SyncStatus.offline
              ? SyncStatus.networkAvailable
              : _currentState.syncStatus,
        ));
      } else if (status == NetworkStatus.offline) {
        _updateState(_currentState.copyWith(syncStatus: SyncStatus.offline));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (kDebugMode) print('[SyncEngine] App resumed — triggering syncAll');
      syncAll();
    }
  }

  bool _isAuthError(dynamic e) {
    if (e is DioException) {
      return e.response?.statusCode == 401;
    }
    return false;
  }

  /// Full sync cycle for all homes the user belongs to.
  Future<void> syncAll() async {
    if (_isSyncing) {
      _hasQueuedSyncRequest = true;
      if (_activeSyncAllCompleter != null) {
        return _activeSyncAllCompleter!.future;
      }
      return;
    }
    if (!_connectivity.isOnline) {
      if (kDebugMode) print('[SyncEngine] Skipping syncAll - device is offline');
      _updateState(_currentState.copyWith(syncStatus: SyncStatus.offline));
      return;
    }
    _activeSyncAllCompleter = Completer<void>();
    _isSyncing = true;
    _connectivity.setSyncing();
    _updateState(_currentState.copyWith(
      syncStatus: SyncStatus.syncingPush,
      isSyncInProgress: true,
      lastError: null,
    ));

    try {
      // 1. Push pending local operations first
      await _pushPendingOperations();

      // 2. Transition to pulling remote changes
      _updateState(_currentState.copyWith(
        syncStatus: SyncStatus.syncingPull,
      ));

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
        if (homeId.isNotEmpty && homeId != 'default_home') {
          await _pullServerChanges(homeId);
        }
      }

      _updateState(_currentState.copyWith(
        syncStatus: SyncStatus.synced,
        lastSyncedAt: DateTime.now(),
        isSyncInProgress: false,
        lastError: null,
      ));

      // Cleanup synced operations older than 24 hours
      await _syncDao.cleanupOldSyncedOperations();
    } catch (e) {
      if (kDebugMode) print('[SyncEngine] Sync failed: $e');
      final isAuth = _isAuthError(e);
      _updateState(_currentState.copyWith(
        syncStatus: isAuth
            ? SyncStatus.authRequired
            : (_connectivity.isOnline ? SyncStatus.error : SyncStatus.offline),
        isSyncInProgress: false,
        lastError: isAuth
            ? 'Authentication required. Please sign in again.'
            : e.toString(),
      ));
      if (!isAuth) {
        // Schedule retry
        _scheduleRetry();
      }
    } finally {
      _isSyncing = false;
      _connectivity.setSyncComplete();
      _activeSyncAllCompleter?.complete();
      _activeSyncAllCompleter = null;
      if (_hasQueuedSyncRequest) {
        _hasQueuedSyncRequest = false;
        Future.microtask(() => syncAll());
      }
    }
  }

  /// Sync operations for a specific home.
  Future<void> syncHome(String homeId) async {
    if (homeId.isEmpty || homeId == 'default_home') return;
    if (_isSyncing || _activeHomeSyncs.contains(homeId)) return;
    if (!_connectivity.isOnline) return;

    _activeHomeSyncs.add(homeId);
    _connectivity.setSyncing();
    _updateState(_currentState.copyWith(
      syncStatus: SyncStatus.syncingPush,
      isSyncInProgress: true,
      lastError: null,
    ));

    try {
      await _pushPendingOperationsForHome(homeId);

      _updateState(_currentState.copyWith(
        syncStatus: SyncStatus.syncingPull,
      ));

      await _pullServerChanges(homeId);

      _updateState(_currentState.copyWith(
        syncStatus: SyncStatus.synced,
        lastSyncedAt: DateTime.now(),
        isSyncInProgress: false,
        lastError: null,
      ));

      await _syncDao.cleanupOldSyncedOperations();
    } catch (e) {
      if (kDebugMode) print('[SyncEngine] Home sync failed: $e');
      final isAuth = _isAuthError(e);
      _updateState(_currentState.copyWith(
        syncStatus: isAuth
            ? SyncStatus.authRequired
            : (_connectivity.isOnline ? SyncStatus.error : SyncStatus.offline),
        isSyncInProgress: false,
        lastError: isAuth
            ? 'Authentication required. Please sign in again.'
            : e.toString(),
      ));
    } finally {
      _activeHomeSyncs.remove(homeId);
      if (_activeHomeSyncs.isEmpty && !_isSyncing) {
        _connectivity.setSyncComplete();
      }
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

    // Batch by home for efficiency (ignoring invalid/empty homeIds)
    final byHome = <String, List<SyncQueueEntry>>{};
    for (final op in allOps) {
      if (op.homeId.isNotEmpty && op.homeId != 'default_home') {
        byHome.putIfAbsent(op.homeId, () => []).add(op);
      }
    }

    for (final entry in byHome.entries) {
      await _pushBatch(entry.value);
    }
  }

  Future<void> _pushPendingOperationsForHome(String homeId) async {
    if (homeId.isEmpty || homeId == 'default_home') return;
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
              final matchedOp = operations.where((o) => o.operationId == opId).firstOrNull;
              if (matchedOp != null) {
                await _markEntitySyncedLocally(matchedOp.entityType, matchedOp.entityId);
              }
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
          await _markEntitySyncedLocally(op.entityType, op.entityId);
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
    if (homeId.isEmpty || homeId == 'default_home') return;
    bool hasMore = true;
    int iterations = 0;
    const maxIterations = 20;

    while (hasMore && iterations < maxIterations) {
      iterations++;
      final lastSynced = await _syncDao.getLastSyncedAt(homeId);
      final syncVersion = await _syncDao.getSyncVersion(homeId);
      final sinceParam = lastSynced?.toUtc().toIso8601String();

      final queryParams = <String, dynamic>{
        'homeId': homeId,
        'limit': 500,
      };
      if (sinceParam != null) {
        queryParams['since'] = sinceParam;
      }
      if (syncVersion > 0) {
        queryParams['sinceVersion'] = syncVersion;
      }

      try {
        final response = await _apiClient.dio.get(
          '/sync',
          queryParameters: queryParams,
        );

        final data = response.data['data'];
        if (data == null) break;

        final pullResponse = SyncPullResponse.fromJson(data);

        // Transition to reconciling before applying to local DB
        _updateState(_currentState.copyWith(
          syncStatus: SyncStatus.reconciling,
        ));

        // Apply changes atomically to local database within a single SQLite transaction
        await _applyPullResponse(homeId, pullResponse);

        hasMore = pullResponse.hasMore;
      } catch (e) {
        if (kDebugMode) print('[SyncEngine] Pull failed for home $homeId: $e');
        break;
      }
    }
  }

  Future<void> _applyPullResponse(
      String homeId, SyncPullResponse pullResponse) async {
    if (pullResponse.isEmpty) return;

    // Build categories
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

    // Build inventory items
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

    // Build stock transactions
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

    // Build shopping lists
    final shoppingLists = pullResponse.shoppingLists.map((json) {
      return LocalShoppingListsCompanion(
        id: Value(json['id'] as String),
        homeId: Value(homeId),
        name: Value(json['name'] as String? ?? 'Home Shopping List'),
        isDefault: Value(json['isDefault'] as bool? ?? true),
        updatedAt: Value(DateTime.now()),
      );
    }).toList();

    // Build shopping list items
    final shoppingItems = pullResponse.shoppingListItems.map((json) {
      return LocalShoppingListItemsCompanion(
        id: Value(json['id'] as String),
        shoppingListId: Value(json['shoppingListId'] as String? ?? ''),
        homeId: Value(homeId),
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

    // Build purchases
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

    // Build purchase items
    final purchaseItems = pullResponse.purchaseItems.map((json) {
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

    // Build stores
    final stores = pullResponse.stores.map((json) {
      return LocalStoresCompanion(
        id: Value(json['id'] as String),
        homeId: Value(homeId),
        name: Value(json['name'] as String? ?? ''),
        location: Value(json['location'] as String?),
        updatedAt: Value(DateTime.now()),
      );
    }).toList();

    // Build home members
    final homeMembers = pullResponse.homeMembers.map((json) {
      return LocalHomeMembersCompanion(
        id: Value(json['id'] as String? ?? json['userId'] as String? ?? ''),
        homeId: Value(homeId),
        userId: Value(json['userId'] as String? ?? ''),
        fullName: Value(json['fullName'] as String? ?? ''),
        email: Value(json['email'] as String? ?? ''),
        avatarUrl: Value(json['avatarUrl'] as String?),
        role: Value(json['role'] as String? ?? 'MEMBER'),
        joinedAt: Value(json['joinedAt'] as String?),
        updatedAt: Value(DateTime.now()),
      );
    }).toList();

    // Build home details
    LocalHomesCompanion? homeDetails;
    if (pullResponse.homeDetails != null) {
      final h = pullResponse.homeDetails!;
      homeDetails = LocalHomesCompanion(
        id: Value(h['id'] as String? ?? homeId),
        name: Value(h['name'] as String? ?? ''),
        inviteCode: Value(h['inviteCode'] as String? ?? ''),
        currentUserRole: Value(h['currentUserRole'] as String? ?? 'MEMBER'),
        memberCount: Value((h['memberCount'] as num?)?.toInt() ?? 1),
        createdAt: Value(h['createdAt'] != null
            ? DateTime.tryParse(h['createdAt'] as String)
            : null),
        updatedAt: Value(DateTime.now()),
      );
    }

    // Apply entire payload atomically within single transaction
    await _syncDao.applyPullChangesInTransaction(
      homeId: homeId,
      categories: categories,
      inventoryItems: items,
      stockTransactions: txs,
      shoppingLists: shoppingLists,
      shoppingListItems: shoppingItems,
      purchases: purchases,
      purchaseItems: purchaseItems,
      stores: stores,
      homeMembers: homeMembers,
      homeDetails: homeDetails,
      deletedShoppingItemIds: pullResponse.deletedShoppingItemIds,
      deletedInventoryItemIds: pullResponse.deletedInventoryItemIds,
      deletedStoreIds: pullResponse.deletedStoreIds,
      deletedCategoryIds: pullResponse.deletedCategoryIds,
      deletedMemberUserIds: pullResponse.deletedMemberUserIds,
      serverTimestamp: DateTime.tryParse(pullResponse.serverTimestamp) ?? DateTime.now(),
      nextServerVersion: pullResponse.nextServerVersion ?? pullResponse.serverVersion,
    );
  }

  Future<void> _updateLocalFromServerEntity(
      String entityType, Map<String, dynamic> json) async {
    final entityId = json['id'] as String?;
    if (entityId == null || entityId.isEmpty) return;

    switch (entityType) {
      case SyncEntityType.inventoryItem:
        final existing = await _inventoryDao.getItemById(entityId);
        await _inventoryDao.upsertItem(LocalInventoryItemsCompanion(
          id: Value(entityId),
          homeId: Value(json['homeId'] as String? ?? existing?.homeId ?? ''),
          categoryId: Value(json['categoryId'] as String? ?? existing?.categoryId),
          categoryName: Value(json['categoryName'] as String? ?? existing?.categoryName ?? 'General'),
          categoryIcon: Value(json['categoryIcon'] as String? ?? existing?.categoryIcon ?? 'category'),
          categoryColor: Value(json['categoryColor'] as String? ?? existing?.categoryColor ?? '#6366F1'),
          name: Value(json['name'] as String? ?? existing?.name ?? ''),
          brand: Value(json['brand'] as String? ?? existing?.brand),
          quantity: Value((json['quantity'] as num?)?.toDouble() ?? existing?.quantity ?? 0.0),
          unit: Value(json['unit'] as String? ?? existing?.unit ?? 'pcs'),
          minimumQuantity: Value((json['minimumQuantity'] as num?)?.toDouble() ?? existing?.minimumQuantity ?? 1.0),
          maximumQuantity: Value((json['maximumQuantity'] as num?)?.toDouble() ?? existing?.maximumQuantity),
          storageLocation: Value(json['storageLocation'] as String? ?? existing?.storageLocation),
          purchasePrice: Value((json['purchasePrice'] as num?)?.toDouble() ?? existing?.purchasePrice),
          purchaseDate: Value(json['purchaseDate'] as String? ?? existing?.purchaseDate),
          expiryDate: Value(json['expiryDate'] as String? ?? existing?.expiryDate),
          imageUrl: Value(json['imageUrl'] as String? ?? existing?.imageUrl),
          notes: Value(json['notes'] as String? ?? existing?.notes),
          stockStatus: Value(json['stockStatus'] as String? ?? existing?.stockStatus ?? 'IN_STOCK'),
          expiryStatus: Value(json['expiryStatus'] as String? ?? existing?.expiryStatus ?? 'SAFE'),
          daysUntilExpiry: Value(json['daysUntilExpiry'] as int? ?? existing?.daysUntilExpiry),
          isDeleted: Value(json['isDeleted'] as bool? ?? existing?.isDeleted ?? false),
          isLocalOnly: const Value(false),
          updatedAt: Value(DateTime.now()),
        ));
        break;
      case SyncEntityType.shoppingListItem:
        await (_db.update(_db.localShoppingListItems)..where((t) => t.id.equals(entityId)))
            .write(const LocalShoppingListItemsCompanion(isLocalOnly: Value(false)));
        break;
      default:
        break;
    }
  }

  Future<void> _markEntitySyncedLocally(String entityType, String entityId) async {
    try {
      switch (entityType) {
        case SyncEntityType.inventoryItem:
          await (_db.update(_db.localInventoryItems)..where((t) => t.id.equals(entityId)))
              .write(const LocalInventoryItemsCompanion(isLocalOnly: Value(false)));
          break;
        case SyncEntityType.shoppingListItem:
          await (_db.update(_db.localShoppingListItems)..where((t) => t.id.equals(entityId)))
              .write(const LocalShoppingListItemsCompanion(isLocalOnly: Value(false)));
          break;
        case SyncEntityType.purchase:
          await (_db.update(_db.localPurchases)..where((t) => t.id.equals(entityId)))
              .write(const LocalPurchasesCompanion(isLocalOnly: Value(false)));
          break;
      }
    } catch (_) {}
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
    if (_isAutoSyncStarted) {
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (_) {}
    }
    _retryTimer?.cancel();
    _stateController.close();
  }
}
