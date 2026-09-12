import 'package:flutter/foundation.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import 'deal_search_models.dart';

/// Repository for Real-World Product Deal Search.
class ProductDealRepository {
  final ApiClient _apiClient;

  ProductDealRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Search real-world deals across online platforms.
  Future<ProductDealSearchResponse> searchDeals({
    required String homeId,
    String? query,
    String? barcode,
    String? brand,
    String? unit,
    String? subtype,
    String? filterBrand,
    String? filterPackSize,
    String sortBy = 'default',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'sortBy': sortBy,
      };
      if (query != null && query.trim().isNotEmpty) {
        queryParams['query'] = query.trim();
      }
      if (barcode != null && barcode.trim().isNotEmpty) {
        queryParams['barcode'] = barcode.trim();
      }
      if (brand != null && brand.trim().isNotEmpty) {
        queryParams['brand'] = brand.trim();
      }
      if (unit != null && unit.trim().isNotEmpty) {
        queryParams['unit'] = unit.trim();
      }
      if (subtype != null && subtype.trim().isNotEmpty) {
        queryParams['subtype'] = subtype.trim();
      }
      if (filterBrand != null && filterBrand.trim().isNotEmpty) {
        queryParams['filterBrand'] = filterBrand.trim();
      }
      if (filterPackSize != null && filterPackSize.trim().isNotEmpty) {
        queryParams['filterPackSize'] = filterPackSize.trim();
      }

      final response = await _apiClient.dio.get(
        ApiEndpoints.dealSearch(homeId),
        queryParameters: queryParams,
      );

      final data = response.data['data'];
      if (data == null) {
        throw Exception('No deals data returned');
      }
      return ProductDealSearchResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('[ProductDealRepo] searchDeals error: $e');
      rethrow;
    }
  }

  /// Search deals for an existing shopping list item.
  Future<ProductDealSearchResponse> getItemDeals({
    required String homeId,
    required String itemId,
    String sortBy = 'default',
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.itemDeals(homeId, itemId),
        queryParameters: {'sortBy': sortBy},
      );

      final data = response.data['data'];
      if (data == null) {
        throw Exception('No item deals data returned');
      }
      return ProductDealSearchResponse.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('[ProductDealRepo] getItemDeals error: $e');
      rethrow;
    }
  }

  /// Validate a specific deal before launching external URL (Phase 20)
  Future<bool> validateDeal(String dealId) async {
    try {
      final response = await _apiClient.dio.post('/api/v1/deals/$dealId/validate');
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('[ProductDealRepo] validateDeal error: $e');
      return false;
    }
  }
}
