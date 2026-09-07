import 'package:flutter/foundation.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/sync/connectivity_monitor.dart';
import 'analytics_model.dart';

class AnalyticsRepository {
  final ApiClient _apiClient;
  final ConnectivityMonitor _connectivity;

  final Map<String, AnalyticsOverviewModel> _cache = {};

  AnalyticsRepository({
    required ApiClient apiClient,
    required ConnectivityMonitor connectivity,
  })  : _apiClient = apiClient,
        _connectivity = connectivity;

  Future<AnalyticsOverviewModel> getAnalytics(String homeId) async {
    if (_connectivity.isOnline) {
      try {
        final response = await _apiClient.dio.get(ApiEndpoints.analytics(homeId));
        final model = AnalyticsOverviewModel.fromJson(response.data['data']);
        _cache[homeId] = model;
        return model;
      } catch (e) {
        if (kDebugMode) print('[AnalyticsRepo] Fetch failed, checking cache: $e');
      }
    }

    if (_cache.containsKey(homeId)) {
      return _cache[homeId]!;
    }

    // Default empty model if completely offline with no prior cache
    return AnalyticsOverviewModel(
      monthlySpending: 0.0,
      currency: 'INR',
      categorySpending: [],
      storeSpending: [],
      mostPurchasedItems: [],
      mostConsumedItems: [],
    );
  }
}
