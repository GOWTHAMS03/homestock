import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_controller.dart' show apiClientProvider;
import '../models/customer_demand_models.dart';
import '../repositories/customer_demand_repository.dart';
import 'shop_owner_controller.dart';

final customerDemandRepositoryProvider = Provider<CustomerDemandRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return CustomerDemandRepository(apiClient: client);
});

class CustomerDemandState {
  final CustomerDemandDashboardModel? dashboard;
  final DemandPeriod selectedPeriod;
  final double selectedRadiusKm;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final ProductDemandDetailModel? searchDetail;
  final bool isSearching;

  const CustomerDemandState({
    this.dashboard,
    this.selectedPeriod = DemandPeriod.last7Days,
    this.selectedRadiusKm = 5.0,
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.searchDetail,
    this.isSearching = false,
  });

  CustomerDemandState copyWith({
    CustomerDemandDashboardModel? dashboard,
    DemandPeriod? selectedPeriod,
    double? selectedRadiusKm,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? searchQuery,
    ProductDemandDetailModel? searchDetail,
    bool clearSearchDetail = false,
    bool? isSearching,
  }) {
    return CustomerDemandState(
      dashboard: dashboard ?? this.dashboard,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      selectedRadiusKm: selectedRadiusKm ?? this.selectedRadiusKm,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      searchDetail: clearSearchDetail ? null : (searchDetail ?? this.searchDetail),
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

class CustomerDemandNotifier extends StateNotifier<CustomerDemandState> {
  final CustomerDemandRepository _repository;
  final Ref _ref;

  CustomerDemandNotifier(this._repository, this._ref)
      : super(const CustomerDemandState()) {
    // Auto-load if shop is already available
    final shop = _ref.read(shopOwnerControllerProvider).shop;
    if (shop != null) {
      loadDashboard(shopId: shop.id);
    }
  }

  Future<void> loadDashboard({
    String? shopId,
    DemandPeriod? period,
    double? radiusKm,
  }) async {
    final effectiveShopId = shopId ?? _ref.read(shopOwnerControllerProvider).shop?.id;
    if (effectiveShopId == null) return;

    final targetPeriod = period ?? state.selectedPeriod;
    final targetRadius = radiusKm ?? state.selectedRadiusKm;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      selectedPeriod: targetPeriod,
      selectedRadiusKm: targetRadius,
    );

    try {
      final dashboard = await _repository.getDemandDashboard(
        effectiveShopId,
        period: targetPeriod,
        radiusKm: targetRadius,
      );

      state = state.copyWith(
        dashboard: dashboard,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load customer demand: ${e.toString().replaceAll("Exception:", "").trim()}',
      );
    }
  }

  void setPeriod(DemandPeriod period) {
    if (state.selectedPeriod == period) return;
    loadDashboard(period: period);
  }

  void setRadius(double radiusKm) {
    if (state.selectedRadiusKm == radiusKm) return;
    loadDashboard(radiusKm: radiusKm);
  }

  Future<void> searchProduct(String query) async {
    final shopId = _ref.read(shopOwnerControllerProvider).shop?.id;
    if (shopId == null || query.trim().isEmpty) return;

    state = state.copyWith(
      isSearching: true,
      searchQuery: query.trim(),
      clearError: true,
    );

    try {
      final detail = await _repository.searchProductDemand(
        shopId,
        query.trim(),
        radiusKm: state.selectedRadiusKm,
      );

      state = state.copyWith(
        searchDetail: detail,
        isSearching: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        errorMessage: 'No demand data found for "$query"',
      );
    }
  }

  void clearSearch() {
    state = state.copyWith(
      searchQuery: '',
      clearSearchDetail: true,
      isSearching: false,
    );
  }
}

final customerDemandControllerProvider =
    StateNotifierProvider<CustomerDemandNotifier, CustomerDemandState>((ref) {
  final repo = ref.watch(customerDemandRepositoryProvider);
  return CustomerDemandNotifier(repo, ref);
});
