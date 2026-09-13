import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../auth/auth_controller.dart' show apiClientProvider;
import 'location_deals_models.dart';
import 'location_deals_repository.dart';
import 'location_service.dart';

final locationDealsRepositoryProvider = Provider<LocationDealsRepository>((ref) {
  try {
    final apiClient = ref.watch(apiClientProvider);
    return LocationDealsRepository(apiClient: apiClient);
  } catch (_) {
    return LocationDealsRepository(
      apiClient: ApiClient(secureStorage: SecureStorageService()),
    );
  }
});

enum DealsViewMode { list, map }

class LocationDealsState {
  final UserLocationContext location;
  final double radiusKm;
  final bool includeTravelCost;
  final String sortPreference;
  final DealsViewMode viewMode;
  final List<NearbyShop> nearbyShops;
  final BasketOptimizationResult? basketResult;
  final VoiceDealResult? voiceResult;
  final bool isLoading;
  final bool isBasketLoading;
  final bool isVoiceSearching;
  final String? errorMessage;

  const LocationDealsState({
    required this.location,
    this.radiusKm = 5.0,
    this.includeTravelCost = false,
    this.sortPreference = 'BEST_VALUE',
    this.viewMode = DealsViewMode.list,
    this.nearbyShops = const [],
    this.basketResult,
    this.voiceResult,
    this.isLoading = false,
    this.isBasketLoading = false,
    this.isVoiceSearching = false,
    this.errorMessage,
  });

  LocationDealsState copyWith({
    UserLocationContext? location,
    double? radiusKm,
    bool? includeTravelCost,
    String? sortPreference,
    DealsViewMode? viewMode,
    List<NearbyShop>? nearbyShops,
    BasketOptimizationResult? basketResult,
    bool clearBasketResult = false,
    VoiceDealResult? voiceResult,
    bool clearVoiceResult = false,
    bool? isLoading,
    bool? isBasketLoading,
    bool? isVoiceSearching,
    String? errorMessage,
  }) {
    return LocationDealsState(
      location: location ?? this.location,
      radiusKm: radiusKm ?? this.radiusKm,
      includeTravelCost: includeTravelCost ?? this.includeTravelCost,
      sortPreference: sortPreference ?? this.sortPreference,
      viewMode: viewMode ?? this.viewMode,
      nearbyShops: nearbyShops ?? this.nearbyShops,
      basketResult: clearBasketResult ? null : (basketResult ?? this.basketResult),
      voiceResult: clearVoiceResult ? null : (voiceResult ?? this.voiceResult),
      isLoading: isLoading ?? this.isLoading,
      isBasketLoading: isBasketLoading ?? this.isBasketLoading,
      isVoiceSearching: isVoiceSearching ?? this.isVoiceSearching,
      errorMessage: errorMessage,
    );
  }
}

class LocationDealsController extends StateNotifier<LocationDealsState> {
  final LocationDealsRepository _repository;
  final LocationService _locationService;

  LocationDealsController(
    this._repository, {
    LocationService? locationService,
    UserLocationContext? initialLocation,
  })  : _locationService = locationService ?? LocationService(),
        super(LocationDealsState(
          location: initialLocation ?? UserLocationContext.detecting,
        )) {
    if (initialLocation != null) {
      loadNearbyShops();
    } else {
      initLiveLocation();
    }
  }

  /// Automatically acquire user's REAL LIVE LOCATION and load local shops
  Future<void> initLiveLocation() async {
    state = state.copyWith(isLoading: true);
    try {
      final liveLocation = await _locationService.getRealLiveLocation();
      if (liveLocation != null) {
        state = state.copyWith(location: liveLocation);
      } else if (!state.location.isResolved) {
        state = state.copyWith(location: UserLocationContext.unresolved);
      }
    } catch (_) {
      if (!state.location.isResolved) {
        state = state.copyWith(location: UserLocationContext.unresolved);
      }
    }
    await loadNearbyShops();
  }

  /// Toggle between List view and Map radar view
  void setViewMode(DealsViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  /// Update radius filter (1km, 3km, 5km, 10km, 15km)
  void setRadius(double radiusKm) {
    state = state.copyWith(radiusKm: radiusKm);
    loadNearbyShops();
  }

  /// Toggle travel cost calculation
  void toggleTravelCost(bool include) {
    state = state.copyWith(includeTravelCost: include);
  }

  /// Set user sort preference
  void setSortPreference(String preference) {
    state = state.copyWith(sortPreference: preference);
  }

  /// Manually update location context (Requirement 33: invalidates previous cache)
  void setLocation(UserLocationContext newContext) {
    // Invalidate previous basket/shop results on location shift
    state = state.copyWith(
      location: newContext,
      clearBasketResult: true,
      clearVoiceResult: true,
    );
    loadNearbyShops();
  }

  /// Request GPS location on-demand
  Future<void> requestGpsLocation(BuildContext context) async {
    final gpsContext = await _locationService.requestGpsLocation(context: context);
    if (gpsContext != null) {
      setLocation(gpsContext);
    }
  }

  /// Load physical grocery shops near current location
  Future<void> loadNearbyShops() async {
    if (!state.location.isResolved) {
      state = state.copyWith(nearbyShops: const [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final shops = await _repository.getNearbyShops(
        latitude: state.location.latitude,
        longitude: state.location.longitude,
        radiusKm: state.radiusKm,
      );

      state = state.copyWith(
        nearbyShops: shops,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load nearby shops: $e',
      );
    }
  }

  /// Optimize full shopping list basket
  Future<void> optimizeBasket({
    required String homeId,
    required List<Map<String, dynamic>> items,
  }) async {
    if (items.isEmpty) return;

    state = state.copyWith(isBasketLoading: true);
    try {
      final result = await _repository.optimizeBasket(
        homeId: homeId,
        items: items,
        latitude: state.location.latitude,
        longitude: state.location.longitude,
        radiusKm: state.radiusKm,
        includeTravelCost: state.includeTravelCost,
        sortPreference: state.sortPreference,
      );

      state = state.copyWith(
        basketResult: result,
        isBasketLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isBasketLoading: false);
    }
  }

  /// Update radius filter alias
  void updateRadius(double radiusKm) => setRadius(radiusKm);

  /// Request GPS or real live location
  Future<void> detectDeviceLocation({BuildContext? context}) async {
    if (context != null) {
      await requestGpsLocation(context);
    } else {
      await initLiveLocation();
    }
  }

  /// Voice search using Gemini
  Future<void> searchVoice(String query) async {
    if (query.trim().isEmpty) return;
    state = state.copyWith(isVoiceSearching: true);
    try {
      final result = await _repository.voiceSearch(
        query: query.trim(),
        latitude: state.location.latitude,
        longitude: state.location.longitude,
        radiusKm: state.radiusKm,
      );
      state = state.copyWith(
        voiceResult: result,
        isVoiceSearching: false,
      );
    } catch (_) {
      state = state.copyWith(isVoiceSearching: false);
    }
  }

  void clearVoiceResult() {
    state = state.copyWith(clearVoiceResult: true);
  }

  void clearBasketOptimization() {
    state = state.copyWith(clearBasketResult: true);
  }

  /// Search areas for manual location dialog
  Future<List<AreaSearchResult>> searchAreas(String query) {
    return _repository.searchAreas(query);
  }
}

final locationDealsControllerProvider =
    StateNotifierProvider<LocationDealsController, LocationDealsState>((ref) {
  final repository = ref.watch(locationDealsRepositoryProvider);
  return LocationDealsController(repository);
});
