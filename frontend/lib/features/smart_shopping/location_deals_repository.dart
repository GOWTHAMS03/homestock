import '../../core/network/api_client.dart';
import '../../core/storage/cache_service.dart';
import 'location_deals_models.dart';

/// Repository communicating with Spring Boot Location-Aware Deals & Nearby Shop endpoints.
class LocationDealsRepository {
  final ApiClient _apiClient;
  final CacheService _cacheService;

  LocationDealsRepository({
    required ApiClient apiClient,
    CacheService? cacheService,
  })  : _apiClient = apiClient,
        _cacheService = cacheService ?? CacheService();

  /// Fetch nearby grocery stores within radius with spatial caching and offline fallback
  Future<List<NearbyShop>> getNearbyShops({
    required double latitude,
    required double longitude,
    double radiusKm = 2.0,
    bool forceRefresh = false,
  }) async {
    final spatialKey = '${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}_${(radiusKm * 1000).toInt()}';

    // 1. Check local offline cache if not forcing refresh
    if (!forceRefresh) {
      final cachedJson = _cacheService.getCachedNearbyShops(spatialKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        return cachedJson.map((e) => NearbyShop.fromJson(e).copyWith(isOfflineCache: false)).toList();
      }
    }

    try {
      final response = await _apiClient.dio.get(
        '/shops/nearby',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'radius': radiusKm <= 50 ? radiusKm : radiusKm / 1000.0,
          'forceRefresh': forceRefresh,
        },
      );

      final data = response.data['data'] as List<dynamic>? ?? [];
      final shops = data.map((e) => NearbyShop.fromJson(e as Map<String, dynamic>)).toList();

      if (shops.isNotEmpty) {
        await _cacheService.cacheNearbyShops(spatialKey, shops.map((s) => s.toJson()).toList());
      }

      return shops;
    } catch (_) {
      // 2. Offline Fallback: If network failed, attempt loading cached results and mark isOfflineCache: true
      final cachedJson = _cacheService.getCachedNearbyShops(spatialKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        return cachedJson.map((e) => NearbyShop.fromJson(e).copyWith(isOfflineCache: true)).toList();
      }
      return [];
    }
  }

  /// Get details and confirmed catalog offers for a specific shop
  Future<Map<String, dynamic>> getShopDetailsAndDeals(String shopId) async {
    try {
      final response = await _apiClient.dio.get('/shops/$shopId/deals');
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
        '/deals/nearby',
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
        '/deals/basket',
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
        '/location/search-areas',
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
        '/deals/voice-search',
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
        '/deals/click',
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
