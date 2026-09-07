import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/inventory_dao.dart';
import '../../core/database/daos/sync_dao.dart';
import '../../core/network/api_client.dart';
import '../../core/sync/connectivity_monitor.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/sync/sync_operation.dart';
import 'category_model.dart';
import 'inventory_model.dart';

const _uuid = Uuid();

/// Offline-first inventory repository.
///
/// READ operations always come from local SQLite.
/// WRITE operations:
///   1. Validate locally
///   2. Update local database immediately
///   3. Create sync queue entry
///   4. If online, trigger background sync
///
/// The UI observes Drift streams and reacts automatically.
class InventoryRepository {
  final InventoryDao _inventoryDao;
  final SyncDao _syncDao;
  final ApiClient _apiClient;
  final ConnectivityMonitor _connectivity;
  final SyncEngine _syncEngine;

  InventoryRepository({
    required InventoryDao inventoryDao,
    required SyncDao syncDao,
    required ApiClient apiClient,
    required ConnectivityMonitor connectivity,
    required SyncEngine syncEngine,
  })  : _inventoryDao = inventoryDao,
        _syncDao = syncDao,
        _apiClient = apiClient,
        _connectivity = connectivity,
        _syncEngine = syncEngine;

  // ──── READ (always local) ────

  /// Watch all items for a home as a reactive stream.
  Stream<List<InventoryItemModel>> watchItems(
    String homeId, {
    String? categoryId,
    String? categoryName,
    String? query,
  }) {
    return _inventoryDao
        .watchItemsFiltered(
          homeId,
          categoryId: categoryId,
          categoryName: categoryName,
          query: query,
        )
        .map((rows) => rows.map(_toModel).toList());
  }

  /// Get a single item by ID (accepts itemId or (homeId, itemId) for compatibility).
  Future<InventoryItemModel?> getItemById(String first, [String? second]) async {
    final itemId = second ?? first;
    final row = await _inventoryDao.getItemById(itemId);
    return row != null ? _toModel(row) : null;
  }

  /// Get all items for a home (non-reactive).
  Future<List<InventoryItemModel>> getItems(String homeId) async {
    final rows = await _inventoryDao.getAllItems(homeId);
    return rows.map(_toModel).toList();
  }

  /// Watch categories for a home. Auto-seeds defaults into SQLite if empty.
  Stream<List<CategoryModel>> watchCategories(String homeId) {
    return _inventoryDao.watchCategories(homeId).asyncMap(
          (rows) async {
            if (rows.isEmpty) {
              await _inventoryDao.seedDefaultCategories(homeId);
              return CategoryModel.defaultCategories(homeId);
            }
            return rows
                .map((r) => CategoryModel(
                      id: r.id,
                      homeId: r.homeId,
                      name: r.name,
                      icon: r.iconName,
                      colorHex: r.colorHex,
                      displayOrder: r.sortOrder,
                    ))
                .toList();
          },
        );
  }

  /// Get categories (non-reactive). Auto-seeds defaults into SQLite if empty.
  Future<List<CategoryModel>> getCategories(String homeId) async {
    var rows = await _inventoryDao.getCategories(homeId);
    if (rows.isEmpty) {
      await _inventoryDao.seedDefaultCategories(homeId);
      rows = await _inventoryDao.getCategories(homeId);
      if (rows.isEmpty) {
        return CategoryModel.defaultCategories(homeId);
      }
    }
    return rows
        .map((r) => CategoryModel(
              id: r.id,
              homeId: r.homeId,
              name: r.name,
              icon: r.iconName,
              colorHex: r.colorHex,
              displayOrder: r.sortOrder,
            ))
        .toList();
  }

  /// Watch stock transactions for an item.
  Stream<List<StockTransactionModel>> watchTransactions(String itemId) {
    return _inventoryDao.watchTransactions(itemId).map(
          (rows) => rows.map(_toTransactionModel).toList(),
        );
  }

  /// Get transactions (non-reactive).
  Future<List<StockTransactionModel>> getTransactions(
      String homeId, String itemId) async {
    final rows = await _inventoryDao.getTransactions(itemId);
    return rows.map(_toTransactionModel).toList();
  }

  // ──── WRITE (local-first) ────

  /// Create a new category locally and queue for sync.
  Future<CategoryModel> createCategory(
    String homeId, {
    required String name,
    String icon = 'category',
    String colorHex = '#6366F1',
    int displayOrder = 0,
  }) async {
    final catId = _uuid.v4();
    final operationId = _uuid.v4();
    final now = DateTime.now();

    final companion = LocalCategoriesCompanion(
      id: Value(catId),
      homeId: Value(homeId),
      name: Value(name.trim()),
      iconName: Value(icon),
      colorHex: Value(colorHex),
      sortOrder: Value(displayOrder),
      updatedAt: Value(now),
    );

    await _inventoryDao.upsertCategories([companion]);

    await _syncDao.addToSyncQueue(SyncQueueEntriesCompanion(
      operationId: Value(operationId),
      operationType: const Value(SyncOperationType.createCategory),
      entityType: const Value(SyncEntityType.category),
      entityId: Value(catId),
      payload: Value(jsonEncode({
        'name': name.trim(),
        'icon': icon,
        'colorHex': colorHex,
        'displayOrder': displayOrder,
      })),
      createdAt: Value(now),
      homeId: Value(homeId),
    ));

    _syncEngine.trySyncImmediate();

    return CategoryModel(
      id: catId,
      homeId: homeId,
      name: name.trim(),
      icon: icon,
      colorHex: colorHex,
      displayOrder: displayOrder,
    );
  }

  /// Create a new inventory item locally and queue for sync.
  Future<InventoryItemModel> createItem(
      String homeId, Map<String, dynamic> data) async {
    final itemId = _uuid.v4();
    final operationId = _uuid.v4();
    final now = DateTime.now();

    final quantity = (data['quantity'] as num?)?.toDouble() ?? 0.0;
    final minQty = (data['minimumQuantity'] as num?)?.toDouble() ?? 1.0;
    final stockStatus = _computeStockStatus(quantity, minQty);
    final expiryDate = data['expiryDate'] as String?;
    final expiryStatus = _computeExpiryStatus(expiryDate);

    // 1. Insert into local DB
    final companion = LocalInventoryItemsCompanion(
      id: Value(itemId),
      homeId: Value(homeId),
      categoryId: Value(data['categoryId'] as String?),
      categoryName:
          Value(data['categoryName'] as String? ?? 'General'),
      categoryIcon:
          Value(data['categoryIcon'] as String? ?? 'category'),
      categoryColor:
          Value(data['categoryColor'] as String? ?? '#6366F1'),
      name: Value((data['name'] as String?)?.trim() ?? ''),
      brand: Value(data['brand'] as String?),
      quantity: Value(quantity),
      unit: Value((data['unit'] as String?)?.trim() ?? 'pcs'),
      minimumQuantity: Value(minQty),
      maximumQuantity:
          Value((data['maximumQuantity'] as num?)?.toDouble()),
      storageLocation: Value(data['storageLocation'] as String?),
      purchasePrice:
          Value((data['purchasePrice'] as num?)?.toDouble()),
      purchaseDate: Value(data['purchaseDate'] as String?),
      expiryDate: Value(expiryDate),
      imageUrl: Value(data['imageUrl'] as String?),
      notes: Value(data['notes'] as String?),
      barcode: Value(data['barcode'] as String?),
      productId: Value(data['productId'] as String?),
      stockStatus: Value(stockStatus),
      expiryStatus: Value(expiryStatus),
      isDeleted: const Value(false),
      isLocalOnly: const Value(true),
      updatedAt: Value(now),
    );

    await _inventoryDao.upsertItem(companion);

    // 2. Enqueue sync operation
    await _syncDao.addToSyncQueue(SyncQueueEntriesCompanion(
      operationId: Value(operationId),
      operationType: const Value(SyncOperationType.createItem),
      entityType: const Value(SyncEntityType.inventoryItem),
      entityId: Value(itemId),
      payload: Value(jsonEncode(data)),
      createdAt: Value(now),
      homeId: Value(homeId),
    ));

    // 3. Trigger background sync if online
    _syncEngine.trySyncImmediate();

    // Return the model
    return InventoryItemModel(
      id: itemId,
      homeId: homeId,
      categoryId: data['categoryId'] as String?,
      categoryName: data['categoryName'] as String? ?? 'General',
      categoryIcon: data['categoryIcon'] as String? ?? 'category',
      categoryColor: data['categoryColor'] as String? ?? '#6366F1',
      name: (data['name'] as String?)?.trim() ?? '',
      brand: data['brand'] as String?,
      quantity: quantity,
      unit: (data['unit'] as String?)?.trim() ?? 'pcs',
      minimumQuantity: minQty,
      maximumQuantity: (data['maximumQuantity'] as num?)?.toDouble(),
      storageLocation: data['storageLocation'] as String?,
      purchasePrice: (data['purchasePrice'] as num?)?.toDouble(),
      purchaseDate: data['purchaseDate'] as String?,
      expiryDate: expiryDate,
      imageUrl: data['imageUrl'] as String?,
      notes: data['notes'] as String?,
      stockStatus: stockStatus,
      expiryStatus: expiryStatus,
    );
  }

  /// Update an existing inventory item locally and queue for sync.
  Future<InventoryItemModel> updateItem(
      String homeId, String itemId, Map<String, dynamic> data) async {
    final operationId = _uuid.v4();
    final now = DateTime.now();

    final quantity = (data['quantity'] as num?)?.toDouble();
    final minQty = (data['minimumQuantity'] as num?)?.toDouble();
    final expiryDate = data['expiryDate'] as String?;

    // Get current item for fields not being updated
    final current = await _inventoryDao.getItemById(itemId);

    final effectiveQty = quantity ?? current?.quantity ?? 0.0;
    final effectiveMinQty = minQty ?? current?.minimumQuantity ?? 1.0;
    final stockStatus = _computeStockStatus(effectiveQty, effectiveMinQty);
    final expiryStatus =
        _computeExpiryStatus(expiryDate ?? current?.expiryDate);

    // 1. Update local DB
    final companion = LocalInventoryItemsCompanion(
      id: Value(itemId),
      homeId: Value(homeId),
      categoryId: Value(data['categoryId'] as String?),
      categoryName:
          Value(data['categoryName'] as String? ?? current?.categoryName ?? 'General'),
      categoryIcon:
          Value(data['categoryIcon'] as String? ?? current?.categoryIcon ?? 'category'),
      categoryColor:
          Value(data['categoryColor'] as String? ?? current?.categoryColor ?? '#6366F1'),
      name: Value((data['name'] as String?)?.trim() ?? current?.name ?? ''),
      brand: Value(data['brand'] as String?),
      quantity: Value(effectiveQty),
      unit: Value((data['unit'] as String?)?.trim() ?? current?.unit ?? 'pcs'),
      minimumQuantity: Value(effectiveMinQty),
      maximumQuantity:
          Value((data['maximumQuantity'] as num?)?.toDouble()),
      storageLocation: Value(data['storageLocation'] as String?),
      purchasePrice:
          Value((data['purchasePrice'] as num?)?.toDouble()),
      purchaseDate: Value(data['purchaseDate'] as String?),
      expiryDate: Value(expiryDate),
      notes: Value(data['notes'] as String?),
      barcode: Value(data['barcode'] as String? ?? current?.barcode),
      productId: Value(data['productId'] as String? ?? current?.productId),
      stockStatus: Value(stockStatus),
      expiryStatus: Value(expiryStatus),
      updatedAt: Value(now),
    );

    await _inventoryDao.upsertItem(companion);

    // 2. Enqueue sync operation
    await _syncDao.addToSyncQueue(SyncQueueEntriesCompanion(
      operationId: Value(operationId),
      operationType: const Value(SyncOperationType.updateItem),
      entityType: const Value(SyncEntityType.inventoryItem),
      entityId: Value(itemId),
      payload: Value(jsonEncode(data)),
      createdAt: Value(now),
      homeId: Value(homeId),
    ));

    // 3. Background sync
    _syncEngine.trySyncImmediate();

    // Return updated model
    final updated = await _inventoryDao.getItemById(itemId);
    return updated != null ? _toModel(updated) : throw Exception('Item not found after update');
  }

  /// Update stock quantity locally using operation-based delta.
  /// NEVER syncs absolute quantities — always syncs the operation.
  Future<InventoryItemModel> updateStock(
    String homeId,
    String itemId, {
    required String transactionType,
    required double quantityChange,
    String? reason,
  }) async {
    final operationId = _uuid.v4();
    final txId = _uuid.v4();
    final now = DateTime.now();

    // Get current item
    final current = await _inventoryDao.getItemById(itemId);
    if (current == null) throw Exception('Item not found');

    final previousQty = current.quantity;
    double newQty;

    switch (transactionType) {
      case 'STOCK_IN':
        newQty = previousQty + quantityChange;
        break;
      case 'STOCK_OUT':
      case 'EXPIRED':
      case 'DAMAGED':
        if (previousQty < quantityChange) {
          throw Exception(
              'Cannot reduce stock by $quantityChange ${current.unit}. Only $previousQty available.');
        }
        newQty = previousQty - quantityChange;
        break;
      case 'ADJUSTMENT':
        newQty = quantityChange;
        break;
      default:
        throw Exception('Unsupported transaction type: $transactionType');
    }

    final stockStatus = _computeStockStatus(newQty, current.minimumQuantity);

    // 1. Update item quantity locally
    await _inventoryDao.updateLocalStock(itemId, newQty, stockStatus);

    // 2. Insert local stock transaction
    await _inventoryDao.insertTransaction(LocalStockTransactionsCompanion(
      id: Value(txId),
      inventoryItemId: Value(itemId),
      itemName: Value(current.name),
      userName: const Value('You'),
      transactionType: Value(transactionType),
      quantityChange: Value(quantityChange),
      previousQuantity: Value(previousQty),
      newQuantity: Value(newQty),
      unit: Value(current.unit),
      reason: Value(reason),
      createdAt: Value(now.toIso8601String()),
      isLocalOnly: const Value(true),
    ));

    // 3. Enqueue sync operation — sends the OPERATION, not the absolute quantity
    await _syncDao.addToSyncQueue(SyncQueueEntriesCompanion(
      operationId: Value(operationId),
      operationType: Value(transactionType),
      entityType: const Value(SyncEntityType.inventoryItem),
      entityId: Value(itemId),
      payload: Value(jsonEncode({
        'transactionType': transactionType,
        'quantityChange': quantityChange,
        'reason': reason,
      })),
      createdAt: Value(now),
      homeId: Value(homeId),
    ));

    // 4. Background sync
    _syncEngine.trySyncImmediate();

    // Return updated model
    final updated = await _inventoryDao.getItemById(itemId);
    return updated != null ? _toModel(updated) : throw Exception('Item not found');
  }

  /// Soft delete an item locally and queue for sync.
  Future<void> deleteItem(String homeId, String itemId) async {
    final operationId = _uuid.v4();
    final now = DateTime.now();

    await _inventoryDao.softDeleteItem(itemId);

    await _syncDao.addToSyncQueue(SyncQueueEntriesCompanion(
      operationId: Value(operationId),
      operationType: const Value(SyncOperationType.deleteItem),
      entityType: const Value(SyncEntityType.inventoryItem),
      entityId: Value(itemId),
      payload: const Value('{}'),
      createdAt: Value(now),
      homeId: Value(homeId),
    ));

    _syncEngine.trySyncImmediate();
  }

  // ──── REMOTE (for initial load & sync) ────

  /// Fetch all items from server and populate local DB.
  Future<void> fetchAndCacheFromServer(String homeId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.items(homeId),
        queryParameters: {'size': 500},
      );
      final data = response.data['data'];
      final content = data['content'] as List? ?? [];

      final companions = content.map((json) {
        return LocalInventoryItemsCompanion(
          id: Value(json['id'] as String? ?? ''),
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
          isDeleted: const Value(false),
          isLocalOnly: const Value(false),
          updatedAt: Value(DateTime.now()),
        );
      }).toList();

      await _inventoryDao.upsertItems(companions);
    } catch (e) {
      if (kDebugMode) print('[InventoryRepo] Fetch from server failed: $e');
    }
  }

  /// Fetch categories from server and cache locally.
  Future<void> fetchAndCacheCategories(String homeId) async {
    try {
      final response =
          await _apiClient.dio.get(ApiEndpoints.categories(homeId));
      final list = response.data['data'] as List? ?? [];

      final companions = list.map((json) {
        return LocalCategoriesCompanion(
          id: Value(json['id'] as String? ?? ''),
          homeId: Value(homeId),
          name: Value(json['name'] as String? ?? ''),
          iconName: Value(json['icon'] as String? ?? 'category'),
          colorHex: Value(json['colorHex'] as String? ?? '#6366F1'),
          sortOrder: Value(json['displayOrder'] as int? ?? 0),
          updatedAt: Value(DateTime.now()),
        );
      }).toList();

      await _inventoryDao.upsertCategories(companions);
    } catch (e) {
      if (kDebugMode) print('[InventoryRepo] Fetch categories failed: $e');
    }
  }

  /// Upload image (requires network — no offline support for binary uploads).
  Future<String?> uploadImage(
      String homeId, String itemId, XFile file) async {
    if (!_connectivity.isOnline) {
      throw Exception('Image upload requires internet connection');
    }
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: file.name),
    });
    final response = await _apiClient.dio.post(
      ApiEndpoints.itemImage(homeId, itemId),
      data: formData,
    );
    return response.data['data']['imageUrl'] as String?;
  }

  // ──── HELPERS ────

  InventoryItemModel _toModel(LocalInventoryItem row) {
    return InventoryItemModel(
      id: row.id,
      homeId: row.homeId,
      categoryId: row.categoryId,
      categoryName: row.categoryName,
      categoryIcon: row.categoryIcon,
      categoryColor: row.categoryColor,
      name: row.name,
      brand: row.brand,
      quantity: row.quantity,
      unit: row.unit,
      minimumQuantity: row.minimumQuantity,
      maximumQuantity: row.maximumQuantity,
      storageLocation: row.storageLocation,
      purchasePrice: row.purchasePrice,
      purchaseDate: row.purchaseDate,
      expiryDate: row.expiryDate,
      imageUrl: row.imageUrl,
      notes: row.notes,
      barcode: row.barcode,
      productId: row.productId,
      stockStatus: row.stockStatus,
      expiryStatus: row.expiryStatus,
      daysUntilExpiry: row.daysUntilExpiry,
    );
  }

  StockTransactionModel _toTransactionModel(LocalStockTransaction row) {
    return StockTransactionModel(
      id: row.id,
      itemId: row.inventoryItemId,
      itemName: row.itemName,
      userName: row.userName,
      transactionType: row.transactionType,
      quantityChange: row.quantityChange,
      previousQuantity: row.previousQuantity,
      newQuantity: row.newQuantity,
      unit: row.unit,
      reason: row.reason,
      createdAt: row.createdAt,
    );
  }

  String _computeStockStatus(double quantity, double minimumQuantity) {
    if (quantity <= 0) return 'OUT_OF_STOCK';
    if (quantity <= minimumQuantity) return 'LOW_STOCK';
    return 'IN_STOCK';
  }

  String _computeExpiryStatus(String? expiryDateStr) {
    if (expiryDateStr == null || expiryDateStr.isEmpty) return 'SAFE';
    try {
      final expiryDate = DateTime.parse(expiryDateStr);
      final today = DateTime.now();
      if (expiryDate.isBefore(today)) return 'EXPIRED';
      if (expiryDate.difference(today).inDays <= 7) return 'EXPIRING_SOON';
    } catch (_) {}
    return 'SAFE';
  }
}
