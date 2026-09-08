import 'package:flutter/foundation.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import 'smart_shopping_models.dart';

/// Repository for Smart Shopping price comparison.
///
/// Communicates only with the HomeStock backend — never directly
/// with external shopping providers. All provider logic is server-side.
class SmartShoppingRepository {
  final ApiClient _apiClient;

  SmartShoppingRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch price comparison for a shopping item.
  Future<PriceComparisonResult> fetchOffers(String homeId, String itemId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.itemOffers(homeId, itemId),
      );
      final data = response.data['data'];
      if (data == null) {
        throw Exception('No comparison data returned');
      }
      return PriceComparisonResult.fromJson(data);
    } catch (e) {
      if (kDebugMode) print('[SmartShoppingRepo] fetchOffers failed: $e');
      rethrow;
    }
  }

  /// Fetch price comparison for a multi-item basket.
  Future<BasketComparisonResult> fetchBasketComparison(
    String homeId, {
    List<String>? itemIds,
    String rankingStrategy = 'BEST_PRICE',
    String? preferredStore,
  }) async {
    try {
      final payload = <String, dynamic>{
        'rankingStrategy': rankingStrategy,
      };
      if (itemIds != null && itemIds.isNotEmpty) {
        payload['itemIds'] = itemIds;
      }
      if (preferredStore != null) {
        payload['preferredStore'] = preferredStore;
      }

      final response = await _apiClient.dio.post(
        ApiEndpoints.basketCompare(homeId),
        data: payload,
      );
      final data = response.data['data'];
      if (data == null) {
        throw Exception('No basket comparison data returned');
      }
      return BasketComparisonResult.fromJson(data);
    } catch (e) {
      if (kDebugMode) print('[SmartShoppingRepo] fetchBasketComparison failed: $e');
      rethrow;
    }
  }

  /// Create a shopping session tracking user's decision process.
  Future<ShoppingSessionModel> createSession(
    String homeId, {
    List<String>? itemIds,
    String? selectedProviders,
    double? estimatedTotal,
    String? recommendedOption,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (itemIds != null) payload['itemIds'] = itemIds;
      if (selectedProviders != null) payload['selectedProviders'] = selectedProviders;
      if (estimatedTotal != null) payload['estimatedTotal'] = estimatedTotal;
      if (recommendedOption != null) payload['recommendedOption'] = recommendedOption;

      final response = await _apiClient.dio.post(
        ApiEndpoints.shoppingSessions(homeId),
        data: payload,
      );
      final data = response.data['data'];
      return ShoppingSessionModel.fromJson(data);
    } catch (e) {
      if (kDebugMode) print('[SmartShoppingRepo] createSession failed: $e');
      rethrow;
    }
  }

  /// Complete a shopping session, restock inventory, and update consumption learning.
  Future<Map<String, dynamic>?> completeSession(
    String homeId,
    String sessionId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.completeShoppingSession(homeId, sessionId),
        data: payload,
      );
      return response.data['data'] as Map<String, dynamic>?;
    } catch (e) {
      if (kDebugMode) print('[SmartShoppingRepo] completeSession failed: $e');
      rethrow;
    }
  }

  /// Report user-submitted local store price.
  Future<void> reportLocalPrice(String homeId, Map<String, dynamic> payload) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.reportLocalPrice(homeId),
        data: payload,
      );
    } catch (e) {
      if (kDebugMode) print('[SmartShoppingRepo] reportLocalPrice failed: $e');
      rethrow;
    }
  }

  /// Get list of registered providers and capabilities.
  Future<List<ProviderCapabilityModel>> fetchProviders(String homeId) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.shoppingProviders(homeId),
      );
      final list = response.data['data'] as List? ?? [];
      return list.map((p) => ProviderCapabilityModel.fromJson(p)).toList();
    } catch (e) {
      if (kDebugMode) print('[SmartShoppingRepo] fetchProviders failed: $e');
      return [];
    }
  }

  /// Record an affiliate link click and get the redirect URL.
  Future<String?> recordAffiliateClick({
    required String homeId,
    required String shoppingItemId,
    required String provider,
    required String providerProductId,
    String? sessionId,
    String? sourceScreen,
  }) async {
    try {
      final payload = <String, dynamic>{
        'shoppingItemId': shoppingItemId,
        'provider': provider,
        'providerProductId': providerProductId,
      };
      if (sessionId != null) payload['sessionId'] = sessionId;
      if (sourceScreen != null) payload['sourceScreen'] = sourceScreen;

      final response = await _apiClient.dio.post(
        ApiEndpoints.affiliateClick(homeId),
        data: payload,
      );
      final data = response.data['data'];
      return data?['affiliateUrl'] as String?;
    } catch (e) {
      if (kDebugMode) print('[SmartShoppingRepo] recordAffiliateClick failed: $e');
      return null;
    }
  }
}
