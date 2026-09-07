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

  /// Record an affiliate link click and get the redirect URL.
  Future<String?> recordAffiliateClick({
    required String homeId,
    required String shoppingItemId,
    required String provider,
    required String providerProductId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.affiliateClick(homeId),
        data: {
          'shoppingItemId': shoppingItemId,
          'provider': provider,
          'providerProductId': providerProductId,
        },
      );
      final data = response.data['data'];
      return data?['affiliateUrl'] as String?;
    } catch (e) {
      if (kDebugMode) print('[SmartShoppingRepo] recordAffiliateClick failed: $e');
      return null;
    }
  }
}
