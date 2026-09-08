import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/inventory_dao.dart';
import '../../core/database/daos/purchase_dao.dart';
import '../../core/database/daos/sync_dao.dart';
import '../../core/network/api_client.dart';
import '../../core/sync/connectivity_monitor.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/sync/sync_operation.dart';
import 'purchase_model.dart';

const _uuid = Uuid();

/// Offline-first purchase repository.
///
/// Purchases are treated as transactional operations.
/// When recording offline: Purchase + PurchaseItems + STOCK_IN transactions
/// are saved locally and queued as a single idempotent operation.
class PurchaseRepository {
  final PurchaseDao _purchaseDao;
  final InventoryDao _inventoryDao;
  final SyncDao _syncDao;
  final ApiClient _apiClient;
  final SyncEngine _syncEngine;
  final ConnectivityMonitor? _connectivity;

  PurchaseRepository({
    required PurchaseDao purchaseDao,
    required InventoryDao inventoryDao,
    required SyncDao syncDao,
    required ApiClient apiClient,
    required SyncEngine syncEngine,
    ConnectivityMonitor? connectivity,
  })  : _purchaseDao = purchaseDao,
        _inventoryDao = inventoryDao,
        _syncDao = syncDao,
        _apiClient = apiClient,
        _syncEngine = syncEngine,
        _connectivity = connectivity;

  bool get isOnline => _connectivity?.isOnline ?? true;

  // ──── READ (always local) ────

  /// Watch all purchases for a home.
  Stream<List<PurchaseModel>> watchPurchases(String homeId) {
    return _purchaseDao.watchPurchases(homeId).asyncMap((purchases) async {
      final models = <PurchaseModel>[];
      for (final p in purchases) {
        final items = await _purchaseDao.getPurchaseItems(p.id);
        models.add(_toPurchaseModel(p, items));
      }
      return models;
    });
  }

  /// Get all purchases (non-reactive).
  Future<List<PurchaseModel>> getPurchases(String homeId) async {
    final purchases = await _purchaseDao.getPurchases(homeId);
    final models = <PurchaseModel>[];
    for (final p in purchases) {
      final items = await _purchaseDao.getPurchaseItems(p.id);
      models.add(_toPurchaseModel(p, items));
    }
    return models;
  }

  /// Watch stores for a home.
  Stream<List<StoreModel>> watchStores(String homeId) {
    return _purchaseDao.watchStores(homeId).map(
          (stores) => stores
              .map((s) => StoreModel(id: s.id, name: s.name, location: s.location))
              .toList(),
        );
  }

  /// Get stores (non-reactive).
  Future<List<StoreModel>> getStores(String homeId) async {
    final stores = await _purchaseDao.getStores(homeId);
    return stores
        .map((s) => StoreModel(id: s.id, name: s.name, location: s.location))
        .toList();
  }

  // ──── WRITE (local-first) ────

  /// Record a purchase locally with atomic local transaction.
  /// Creates: Purchase + PurchaseItems + STOCK_IN for each linked inventory item.
  Future<PurchaseModel> recordPurchase(
      String homeId, Map<String, dynamic> data) async {
    final purchaseId = _uuid.v4();
    final operationId = _uuid.v4();
    final now = DateTime.now();

    final rawItems = data['items'] as List? ?? [];

    // Build purchase companion
    final purchaseCompanion = LocalPurchasesCompanion(
      id: Value(purchaseId),
      homeId: Value(homeId),
      storeId: Value(data['storeId'] as String?),
      storeName: Value(data['storeName'] as String?),
      recordedByName: const Value('You'),
      purchaseDate: Value(data['purchaseDate'] as String? ??
          now.toIso8601String().substring(0, 10)),
      totalAmount: Value((data['totalAmount'] as num?)?.toDouble() ?? 0.0),
      currency: Value(data['currency'] as String? ?? 'INR'),
      notes: Value(data['notes'] as String?),
      isLocalOnly: const Value(true),
      updatedAt: Value(now),
    );

    // Build purchase item companions
    final itemCompanions = <LocalPurchaseItemsCompanion>[];
    for (final rawItem in rawItems) {
      final itemId = _uuid.v4();
      itemCompanions.add(LocalPurchaseItemsCompanion(
        id: Value(itemId),
        purchaseId: Value(purchaseId),
        inventoryItemId: Value(rawItem['inventoryItemId'] as String?),
        itemName: Value(rawItem['itemName'] as String? ?? ''),
        categoryName: Value(rawItem['categoryName'] as String?),
        quantity: Value((rawItem['quantity'] as num?)?.toDouble() ?? 1.0),
        unit: Value(rawItem['unit'] as String? ?? 'pcs'),
        unitPrice: Value((rawItem['unitPrice'] as num?)?.toDouble() ?? 0.0),
        totalPrice: Value((rawItem['totalPrice'] as num?)?.toDouble() ?? 0.0),
      ));
    }

    // 1. Insert purchase + items locally (atomic)
    await _purchaseDao.insertPurchaseWithItems(
      purchase: purchaseCompanion,
      items: itemCompanions,
    );

    // 2. Create STOCK_IN transactions for linked inventory items
    for (final rawItem in rawItems) {
      final invItemId = rawItem['inventoryItemId'] as String?;
      if (invItemId != null && invItemId.isNotEmpty) {
        final qty = (rawItem['quantity'] as num?)?.toDouble() ?? 0.0;
        if (qty > 0) {
          // Update local stock
          final current = await _inventoryDao.getItemById(invItemId);
          if (current != null) {
            final newQty = current.quantity + qty;
            final stockStatus = newQty <= 0
                ? 'OUT_OF_STOCK'
                : newQty <= current.minimumQuantity
                    ? 'LOW_STOCK'
                    : 'IN_STOCK';
            await _inventoryDao.updateLocalStock(
                invItemId, newQty, stockStatus);

            // Record stock transaction
            await _inventoryDao
                .insertTransaction(LocalStockTransactionsCompanion(
              id: Value(_uuid.v4()),
              inventoryItemId: Value(invItemId),
              itemName: Value(current.name),
              userName: const Value('You'),
              transactionType: const Value('STOCK_IN'),
              quantityChange: Value(qty),
              previousQuantity: Value(current.quantity),
              newQuantity: Value(newQty),
              unit: Value(current.unit),
              reason: Value('Purchase restock'),
              createdAt: Value(now.toIso8601String()),
              isLocalOnly: const Value(true),
            ));
          }
        }
      }
    }

    // 3. Enqueue single sync operation for the whole purchase (idempotent)
    await _syncDao.addToSyncQueue(SyncQueueEntriesCompanion(
      operationId: Value(operationId),
      operationType: const Value(SyncOperationType.recordPurchase),
      entityType: const Value(SyncEntityType.purchase),
      entityId: Value(purchaseId),
      payload: Value(jsonEncode(data)),
      createdAt: Value(now),
      homeId: Value(homeId),
    ));

    // 4. Background sync
    _syncEngine.trySyncImmediate();

    // Return model
    final savedPurchase = await _purchaseDao.getPurchaseById(purchaseId);
    final savedItems = await _purchaseDao.getPurchaseItems(purchaseId);
    return _toPurchaseModel(savedPurchase!, savedItems);
  }

  /// Create a store locally and queue for sync.
  Future<StoreModel> createStore(
      String homeId, String name, String? location) async {
    final storeId = _uuid.v4();
    final operationId = _uuid.v4();
    final now = DateTime.now();

    await _purchaseDao.upsertStore(LocalStoresCompanion(
      id: Value(storeId),
      homeId: Value(homeId),
      name: Value(name),
      location: Value(location),
      updatedAt: Value(now),
    ));

    await _syncDao.addToSyncQueue(SyncQueueEntriesCompanion(
      operationId: Value(operationId),
      operationType: const Value(SyncOperationType.createStore),
      entityType: const Value(SyncEntityType.store),
      entityId: Value(storeId),
      payload: Value(jsonEncode({'name': name, 'location': location})),
      createdAt: Value(now),
      homeId: Value(homeId),
    ));

    _syncEngine.trySyncImmediate();

    return StoreModel(id: storeId, name: name, location: location);
  }

  // ──── REMOTE (for initial load) ────

  /// Fetch from server and cache locally.
  Future<void> fetchAndCacheFromServer(String homeId) async {
    if (_connectivity != null && !_connectivity.isOnline) return;
    try {
      // Fetch purchases
      final response = await _apiClient.dio.get(
        ApiEndpoints.purchases(homeId),
        queryParameters: {'size': 50},
      );
      final list = response.data['data']['content'] as List? ?? [];

      for (final json in list) {
        final purchaseId = json['id'] as String;
        final rawItems = json['items'] as List? ?? [];

        await _purchaseDao.upsertPurchase(LocalPurchasesCompanion(
          id: Value(purchaseId),
          homeId: Value(homeId),
          storeName: Value(json['storeName'] as String?),
          recordedByName: Value(json['recordedByName'] as String? ?? ''),
          purchaseDate: Value(json['purchaseDate'] as String? ?? ''),
          totalAmount:
              Value((json['totalAmount'] as num?)?.toDouble() ?? 0.0),
          currency: Value(json['currency'] as String? ?? 'INR'),
          notes: Value(json['notes'] as String?),
          isLocalOnly: const Value(false),
          updatedAt: Value(DateTime.now()),
        ));

        final itemCompanions = rawItems.map((item) {
          return LocalPurchaseItemsCompanion(
            id: Value(item['id'] as String? ?? _uuid.v4()),
            purchaseId: Value(purchaseId),
            inventoryItemId: Value(item['inventoryItemId'] as String?),
            itemName: Value(item['itemName'] as String? ?? ''),
            categoryName: Value(item['categoryName'] as String?),
            quantity: Value((item['quantity'] as num?)?.toDouble() ?? 1.0),
            unit: Value(item['unit'] as String? ?? 'pcs'),
            unitPrice:
                Value((item['unitPrice'] as num?)?.toDouble() ?? 0.0),
            totalPrice:
                Value((item['totalPrice'] as num?)?.toDouble() ?? 0.0),
          );
        }).toList();

        await _purchaseDao.upsertPurchaseItems(itemCompanions);
      }

      // Fetch stores
      final storeResponse =
          await _apiClient.dio.get(ApiEndpoints.stores(homeId));
      final storeList = storeResponse.data['data'] as List? ?? [];
      final storeCompanions = storeList.map((json) {
        return LocalStoresCompanion(
          id: Value(json['id'] as String),
          homeId: Value(homeId),
          name: Value(json['name'] as String? ?? ''),
          location: Value(json['location'] as String?),
          updatedAt: Value(DateTime.now()),
        );
      }).toList();
      await _purchaseDao.upsertStores(storeCompanions);
    } catch (e) {
      if (kDebugMode) print('[PurchaseRepo] Fetch from server failed: $e');
    }
  }

  // ──── HELPERS ────

  PurchaseModel _toPurchaseModel(
      LocalPurchase p, List<LocalPurchaseItem> items) {
    return PurchaseModel(
      id: p.id,
      storeName: p.storeName,
      recordedByName: p.recordedByName,
      purchaseDate: p.purchaseDate,
      totalAmount: p.totalAmount,
      currency: p.currency,
      notes: p.notes,
      items: items
          .map((i) => PurchaseItemModel(
                id: i.id,
                inventoryItemId: i.inventoryItemId,
                itemName: i.itemName,
                categoryName: i.categoryName,
                quantity: i.quantity,
                unit: i.unit,
                unitPrice: i.unitPrice,
                totalPrice: i.totalPrice,
              ))
          .toList(),
    );
  }
}
