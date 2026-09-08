import 'package:flutter/foundation.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/database/daos/inventory_dao.dart';
import '../../core/database/daos/shopping_dao.dart';
import '../../core/network/api_client.dart';
import '../../core/sync/connectivity_monitor.dart';
import 'dashboard_model.dart';

/// Offline-first dashboard repository.
///
/// Fetches real-time server dashboard when online and caches results.
/// Falls back to local SQLite computations seamlessly when offline.
class DashboardRepository {
  final ApiClient _apiClient;
  final InventoryDao _inventoryDao;
  final ShoppingDao _shoppingDao;
  final ConnectivityMonitor _connectivity;

  DashboardSummaryModel? _cachedSummary;
  WhatDoINeedModel? _cachedRecommendations;

  DashboardRepository({
    required ApiClient apiClient,
    required InventoryDao inventoryDao,
    required ShoppingDao shoppingDao,
    required ConnectivityMonitor connectivity,
  })  : _apiClient = apiClient,
        _inventoryDao = inventoryDao,
        _shoppingDao = shoppingDao,
        _connectivity = connectivity;

  bool get isOnline => _connectivity.isOnline;

  /// Instant local summary computation from SQLite (0ms wait, zero network).
  Future<DashboardSummaryModel> getLocalSummary(String homeId, {String homeName = 'My Home'}) async {
    final local = await _computeLocalSummary(homeId, homeName);
    _cachedSummary = local;
    return local;
  }

  /// Remote background fetch (only if online, non-blocking).
  Future<DashboardSummaryModel?> fetchRemoteSummary(String homeId) async {
    if (!_connectivity.isOnline) return null;
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.dashboard(homeId));
      final summary = DashboardSummaryModel.fromJson(response.data['data']);
      _cachedSummary = summary;
      return summary;
    } catch (e) {
      if (kDebugMode) print('[DashboardRepo] Remote fetch failed: $e');
      return null;
    }
  }

  /// Get dashboard summary: returns cached or local immediately if offline, or checks server if online.
  Future<DashboardSummaryModel> getSummary(String homeId, {String homeName = 'My Home'}) async {
    if (_connectivity.isOnline) {
      final remote = await fetchRemoteSummary(homeId);
      if (remote != null) return remote;
    }

    if (_cachedSummary != null) {
      return _cachedSummary!;
    }

    return getLocalSummary(homeId, homeName: homeName);
  }

  /// Instant local recommendations computation (0ms wait).
  Future<WhatDoINeedModel> getLocalRecommendations(String homeId) async {
    final local = await _computeLocalRecommendations(homeId);
    _cachedRecommendations = local;
    return local;
  }

  /// Remote recommendations fetch (only if online).
  Future<WhatDoINeedModel?> fetchRemoteRecommendations(String homeId) async {
    if (!_connectivity.isOnline) return null;
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.whatDoINeed(homeId));
      final recs = WhatDoINeedModel.fromJson(response.data['data']);
      _cachedRecommendations = recs;
      return recs;
    } catch (e) {
      if (kDebugMode) print('[DashboardRepo] Remote recommendations failed: $e');
      return null;
    }
  }

  /// Get smart recommendations.
  Future<WhatDoINeedModel> getRecommendations(String homeId) async {
    if (_connectivity.isOnline) {
      final remote = await fetchRemoteRecommendations(homeId);
      if (remote != null) return remote;
    }

    if (_cachedRecommendations != null) {
      return _cachedRecommendations!;
    }

    return getLocalRecommendations(homeId);
  }

  /// Compute dashboard metrics directly from SQLite.
  Future<DashboardSummaryModel> _computeLocalSummary(String homeId, String homeName) async {
    final items = await _inventoryDao.getAllItems(homeId);

    int lowStock = 0;
    int outOfStock = 0;
    int expiringSoon = 0;
    final needsAttention = <NeedsAttentionModel>[];

    for (final item in items) {
      final isOut = item.quantity <= 0 || item.stockStatus == 'OUT_OF_STOCK';
      final isLow = !isOut && (item.quantity <= item.minimumQuantity || item.stockStatus == 'LOW_STOCK');
      final isExpiring = item.expiryStatus == 'EXPIRING_SOON' || item.expiryStatus == 'EXPIRED';

      if (isOut) {
        outOfStock++;
        needsAttention.add(NeedsAttentionModel(
          itemId: item.id,
          name: item.name,
          categoryName: item.categoryName,
          quantity: item.quantity,
          unit: item.unit,
          stockStatus: 'OUT_OF_STOCK',
          expiryStatus: item.expiryStatus,
          expiryDate: item.expiryDate,
          daysUntilExpiry: item.daysUntilExpiry,
          reasonMessage: 'Out of stock (0 ${item.unit})',
        ));
      } else if (isLow) {
        lowStock++;
        needsAttention.add(NeedsAttentionModel(
          itemId: item.id,
          name: item.name,
          categoryName: item.categoryName,
          quantity: item.quantity,
          unit: item.unit,
          stockStatus: 'LOW_STOCK',
          expiryStatus: item.expiryStatus,
          expiryDate: item.expiryDate,
          daysUntilExpiry: item.daysUntilExpiry,
          reasonMessage: 'Low stock: ${item.quantity}/${item.minimumQuantity} ${item.unit}',
        ));
      } else if (isExpiring) {
        expiringSoon++;
        needsAttention.add(NeedsAttentionModel(
          itemId: item.id,
          name: item.name,
          categoryName: item.categoryName,
          quantity: item.quantity,
          unit: item.unit,
          stockStatus: item.stockStatus,
          expiryStatus: item.expiryStatus,
          expiryDate: item.expiryDate,
          daysUntilExpiry: item.daysUntilExpiry,
          reasonMessage: item.expiryStatus == 'EXPIRED' ? 'Item expired' : 'Expiring soon',
        ));
      }
    }

    // Pending shopping count
    int pendingShopping = 0;
    try {
      final defaultList = await _shoppingDao.getDefaultList(homeId);
      if (defaultList != null) {
        pendingShopping = await _shoppingDao.getPendingCount(defaultList.id);
      }
    } catch (_) {}

    return DashboardSummaryModel(
      homeName: homeName,
      totalInventoryItems: items.length,
      lowStockCount: lowStock,
      outOfStockCount: outOfStock,
      pendingShoppingCount: pendingShopping,
      expiringSoonCount: expiringSoon,
      needsAttention: needsAttention,
    );
  }

  /// Compute recommendations locally from items.
  Future<WhatDoINeedModel> _computeLocalRecommendations(String homeId) async {
    final items = await _inventoryDao.getAllItems(homeId);

    final urgent = <RecommendationModel>[];
    final soon = <RecommendationModel>[];
    final optional = <RecommendationModel>[];

    for (final item in items) {
      if (item.quantity <= 0 || item.stockStatus == 'OUT_OF_STOCK') {
        urgent.add(RecommendationModel(
          itemId: item.id,
          name: item.name,
          categoryName: item.categoryName,
          currentQuantity: item.quantity,
          recommendedQuantity: item.minimumQuantity > 0 ? item.minimumQuantity * 2 : 1.0,
          unit: item.unit,
          rationale: 'Completely out of stock',
        ));
      } else if (item.quantity <= item.minimumQuantity || item.stockStatus == 'LOW_STOCK') {
        urgent.add(RecommendationModel(
          itemId: item.id,
          name: item.name,
          categoryName: item.categoryName,
          currentQuantity: item.quantity,
          recommendedQuantity: item.minimumQuantity * 2 - item.quantity,
          unit: item.unit,
          rationale: 'Below minimum quantity (${item.minimumQuantity} ${item.unit})',
        ));
      } else if (item.expiryStatus == 'EXPIRING_SOON' || item.expiryStatus == 'EXPIRED') {
        soon.add(RecommendationModel(
          itemId: item.id,
          name: item.name,
          categoryName: item.categoryName,
          currentQuantity: item.quantity,
          recommendedQuantity: item.minimumQuantity,
          unit: item.unit,
          rationale: 'Item nearing or past expiration date',
        ));
      } else if (item.quantity <= item.minimumQuantity * 1.5) {
        optional.add(RecommendationModel(
          itemId: item.id,
          name: item.name,
          categoryName: item.categoryName,
          currentQuantity: item.quantity,
          recommendedQuantity: item.minimumQuantity,
          unit: item.unit,
          rationale: 'Moderate stock level, consider restocking',
        ));
      }
    }

    return WhatDoINeedModel(
      urgent: urgent,
      soon: soon,
      optional: optional,
    );
  }
}
