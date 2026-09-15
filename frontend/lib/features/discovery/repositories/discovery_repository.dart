import '../../../core/network/api_client.dart';
import '../../shop_owner/models/shop_models.dart';

class DiscoveryRepository {
  final ApiClient _apiClient;

  DiscoveryRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<ShopProfileModel>> getNearbyVerifiedShops({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    final response = await _apiClient.dio.get(
      '/discovery/shops',
      queryParameters: {
        'lat': latitude,
        'lon': longitude,
        'radius': radiusKm,
      },
    );
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => ShopProfileModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ShopProductModel>> searchProductsNearby({
    required String query,
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String sortBy = 'NEAREST',
  }) async {
    final response = await _apiClient.dio.get(
      '/discovery/products',
      queryParameters: {
        'query': query,
        'lat': latitude,
        'lon': longitude,
        'radius': radiusKm,
        'sortBy': sortBy,
      },
    );
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => ShopProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ShopProfileModel> getShopProfile(String shopId, {double? lat, double? lon}) async {
    final queryParams = <String, dynamic>{};
    if (lat != null) queryParams['lat'] = lat;
    if (lon != null) queryParams['lon'] = lon;

    final response = await _apiClient.dio.get(
      '/discovery/shops/$shopId',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final body = response.data['data'] as Map<String, dynamic>;
    return ShopProfileModel.fromJson(body);
  }

  Future<List<ShopProductModel>> getShopProducts(String shopId) async {
    final response = await _apiClient.dio.get('/discovery/shops/$shopId/products');
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => ShopProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ShopDealModel>> getShopDeals(String shopId) async {
    final response = await _apiClient.dio.get('/discovery/shops/$shopId/deals');
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => ShopDealModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
