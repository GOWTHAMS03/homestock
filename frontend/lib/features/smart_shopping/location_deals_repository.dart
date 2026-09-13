import '../../core/network/api_client.dart';
import 'location_deals_models.dart';

/// Repository communicating with Spring Boot Location-Aware Deals & Nearby Shop endpoints.
class LocationDealsRepository {
  final ApiClient _apiClient;

  LocationDealsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch nearby grocery stores within radius
  Future<List<NearbyShop>> getNearbyShops({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/shops/nearby',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'radius': radiusKm,
        },
      );

      final data = response.data['data'] as List<dynamic>? ?? [];
      return data.map((e) => NearbyShop.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get details and confirmed catalog offers for a specific shop
  Future<Map<String, dynamic>> getShopDetailsAndDeals(String shopId) async {
    try {
      final response = await _apiClient.dio.get('/api/v1/shops/$shopId/deals');
      final data = response.data['data'] as Map<String, dynamic>? ?? {};

      final shopJson = data['shop'] as Map<String, dynamic>? ?? {};
      final dealsJson = data['confirmedDeals'] as List<dynamic>? ?? [];

      return {
        'shop': NearbyShop.fromJson(shopJson),
        'confirmedDeals': dealsJson.map((e) => ShopDeal.fromJson(e as Map<String, dynamic>)).toList(),
      };
    } catch (_) {
      return {
        'shop': null,
        'confirmedDeals': <ShopDeal>[],
      };
    }
  }

  /// Search location-aware deals for a product query
  Future<Map<String, dynamic>> searchNearbyDeals({
    required String query,
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String? homeId,
    String? productId,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/deals/nearby',
        queryParameters: {
          'q': query,
          'lat': latitude,
          'lon': longitude,
          'radius': radiusKm,
          if (homeId != null) 'homeId': homeId,
          if (productId != null) 'productId': productId,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      final localJson = data['nearbyDeals'] as List<dynamic>? ?? [];
      final bestJson = data['bestNearbyDeal'] as Map<String, dynamic>?;

      return {
        'nearbyDeals': localJson.map((e) => ShopDeal.fromJson(e as Map<String, dynamic>)).toList(),
        'bestNearbyDeal': bestJson != null ? ShopDeal.fromJson(bestJson) : null,
      };
    } catch (_) {
      return {
        'nearbyDeals': <ShopDeal>[],
        'bestNearbyDeal': null,
      };
    }
  }

  /// Optimize complete multi-item basket
  Future<BasketOptimizationResult?> optimizeBasket({
    required String homeId,
    required List<Map<String, dynamic>> items,
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    bool includeTravelCost = false,
    String sortPreference = 'BEST_VALUE',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/deals/basket',
        data: {
          'homeId': homeId,
          'items': items,
          'latitude': latitude,
          'longitude': longitude,
          'radiusKm': radiusKm,
          'includeTravelCost': includeTravelCost,
          'sortPreference': sortPreference,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>?;
      if (data != null) {
        return BasketOptimizationResult.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// Search areas/cities for manual location fallback
  Future<List<AreaSearchResult>> searchAreas(String query) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/v1/location/search-areas',
        queryParameters: {'q': query},
      );

      final data = response.data['data'] as List<dynamic>? ?? [];
      return data.map((e) => AreaSearchResult.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Search deals with natural language or voice transcript (Tamil, Tanglish, English)
  Future<VoiceDealResult?> voiceSearch({
    required String query,
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/deals/voice-search',
        data: {
          'query': query,
          'latitude': latitude,
          'longitude': longitude,
          'radiusKm': radiusKm,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>?;
      if (data != null) {
        return VoiceDealResult.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// Track deal click and get target deep link
  Future<String> trackDealClick({
    String? dealId,
    String? shopId,
    required String provider,
    required String targetUrl,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/deals/click',
        queryParameters: {
          if (dealId != null) 'dealId': dealId,
          if (shopId != null) 'shopId': shopId,
          'provider': provider,
          'targetUrl': targetUrl,
        },
      );

      return response.data['data']?['targetUrl'] as String? ?? targetUrl;
    } catch (_) {
      return targetUrl;
    }
  }
}
