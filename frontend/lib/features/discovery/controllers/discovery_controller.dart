import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_controller.dart' show apiClientProvider;
import '../../shop_owner/models/shop_models.dart';
import '../repositories/discovery_repository.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return DiscoveryRepository(apiClient: client);
});

class DiscoveryState {
  final List<ShopProfileModel> nearbyShops;
  final List<ShopProductModel> searchResults;
  final ShopProfileModel? selectedShop;
  final List<ShopProductModel> selectedShopProducts;
  final List<ShopDealModel> selectedShopDeals;
  final bool isLoading;
  final String? errorMessage;
  final String currentQuery;
  final String sortBy;

  const DiscoveryState({
    this.nearbyShops = const [],
    this.searchResults = const [],
    this.selectedShop,
    this.selectedShopProducts = const [],
    this.selectedShopDeals = const [],
    this.isLoading = false,
    this.errorMessage,
    this.currentQuery = '',
    this.sortBy = 'NEAREST',
  });

  DiscoveryState copyWith({
    List<ShopProfileModel>? nearbyShops,
    List<ShopProductModel>? searchResults,
    ShopProfileModel? selectedShop,
    bool clearSelectedShop = false,
    List<ShopProductModel>? selectedShopProducts,
    List<ShopDealModel>? selectedShopDeals,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? currentQuery,
    String? sortBy,
  }) {
    return DiscoveryState(
      nearbyShops: nearbyShops ?? this.nearbyShops,
      searchResults: searchResults ?? this.searchResults,
      selectedShop: clearSelectedShop ? null : (selectedShop ?? this.selectedShop),
      selectedShopProducts: selectedShopProducts ?? this.selectedShopProducts,
      selectedShopDeals: selectedShopDeals ?? this.selectedShopDeals,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentQuery: currentQuery ?? this.currentQuery,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class DiscoveryController extends StateNotifier<DiscoveryState> {
  final DiscoveryRepository _repository;

  DiscoveryController(this._repository) : super(const DiscoveryState());

  Future<void> loadNearbyShops({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final shops = await _repository.getNearbyVerifiedShops(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      state = state.copyWith(nearbyShops: shops, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> searchProducts(
    String query, {
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String? sortBy,
  }) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: const [], currentQuery: '');
      return;
    }

    final effectiveSort = sortBy ?? state.sortBy;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      currentQuery: query.trim(),
      sortBy: effectiveSort,
    );

    try {
      final results = await _repository.searchProductsNearby(
        query: query.trim(),
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        sortBy: effectiveSort,
      );
      state = state.copyWith(searchResults: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadShopDetails(String shopId, {double? lat, double? lon}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final shop = await _repository.getShopProfile(shopId, lat: lat, lon: lon);
      final products = await _repository.getShopProducts(shopId);
      final deals = await _repository.getShopDeals(shopId);
      state = state.copyWith(
        selectedShop: shop,
        selectedShopProducts: products,
        selectedShopDeals: deals,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final discoveryControllerProvider =
    StateNotifierProvider<DiscoveryController, DiscoveryState>((ref) {
  final repo = ref.watch(discoveryRepositoryProvider);
  return DiscoveryController(repo);
});
