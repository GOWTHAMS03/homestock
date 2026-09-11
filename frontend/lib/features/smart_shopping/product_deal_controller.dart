import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_controller.dart';
import 'deal_search_models.dart';
import 'product_deal_repository.dart';

final productDealRepositoryProvider = Provider<ProductDealRepository>((ref) {
  return ProductDealRepository(
    apiClient: ref.watch(apiClientProvider),
  );
});

// ──── State ────

class ProductDealState {
  final bool isLoading;
  final String searchQuery;
  final String? selectedSubtype;
  final String? selectedBrand;
  final String? selectedPackSize;
  final String selectedSort;
  final ProductDealSearchResponse? response;
  final String? errorMessage;
  final String? homeId;
  final String? activeItemId;

  const ProductDealState({
    this.isLoading = false,
    this.searchQuery = '',
    this.selectedSubtype,
    this.selectedBrand,
    this.selectedPackSize,
    this.selectedSort = 'default',
    this.response,
    this.errorMessage,
    this.homeId,
    this.activeItemId,
  });

  ProductDealState copyWith({
    bool? isLoading,
    String? searchQuery,
    String? selectedSubtype,
    bool clearSubtype = false,
    String? selectedBrand,
    bool clearBrand = false,
    String? selectedPackSize,
    bool clearPackSize = false,
    String? selectedSort,
    ProductDealSearchResponse? response,
    String? errorMessage,
    String? homeId,
    String? activeItemId,
  }) {
    return ProductDealState(
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSubtype: clearSubtype ? null : (selectedSubtype ?? this.selectedSubtype),
      selectedBrand: clearBrand ? null : (selectedBrand ?? this.selectedBrand),
      selectedPackSize: clearPackSize ? null : (selectedPackSize ?? this.selectedPackSize),
      selectedSort: selectedSort ?? this.selectedSort,
      response: response ?? this.response,
      errorMessage: errorMessage,
      homeId: homeId ?? this.homeId,
      activeItemId: activeItemId ?? this.activeItemId,
    );
  }
}

// ──── Controller ────

final productDealControllerProvider =
    StateNotifierProvider.autoDispose<ProductDealController, ProductDealState>((ref) {
  final repo = ref.watch(productDealRepositoryProvider);
  return ProductDealController(repo);
});

class ProductDealController extends StateNotifier<ProductDealState> {
  final ProductDealRepository _repo;

  ProductDealController(this._repo) : super(const ProductDealState());

  /// Search deals with current or updated parameters
  Future<void> searchDeals({
    required String homeId,
    String? query,
    String? barcode,
    String? brand,
    String? unit,
    bool resetFilters = false,
  }) async {
    final effectiveQuery = query ?? state.searchQuery;
    final subtype = resetFilters ? null : state.selectedSubtype;
    final fBrand = resetFilters ? null : state.selectedBrand;
    final fPack = resetFilters ? null : state.selectedPackSize;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      searchQuery: effectiveQuery,
      homeId: homeId,
      clearSubtype: resetFilters,
      clearBrand: resetFilters,
      clearPackSize: resetFilters,
    );

    try {
      final res = await _repo.searchDeals(
        homeId: homeId,
        query: effectiveQuery,
        barcode: barcode,
        brand: brand,
        unit: unit,
        subtype: subtype,
        filterBrand: fBrand,
        filterPackSize: fPack,
        sortBy: state.selectedSort,
      );

      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          response: res,
        );
      }
    } catch (e) {
      if (kDebugMode) print('[ProductDealController] searchDeals error: $e');
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to load deals. Please check network connection.',
        );
      }
    }
  }

  /// Load deals for a shopping list item
  Future<void> loadListItemDeals({
    required String homeId,
    required String itemId,
    String? initialItemName,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      homeId: homeId,
      activeItemId: itemId,
      searchQuery: initialItemName ?? state.searchQuery,
    );

    try {
      final res = await _repo.getItemDeals(
        homeId: homeId,
        itemId: itemId,
        sortBy: state.selectedSort,
      );

      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          response: res,
          searchQuery: res.intent.rawQuery,
        );
      }
    } catch (e) {
      if (kDebugMode) print('[ProductDealController] loadListItemDeals error: $e');
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Unable to find item deals. Please try searching directly.',
        );
      }
    }
  }

  /// Filter selection toggles
  void selectSubtype(String? subtype) {
    if (state.selectedSubtype == subtype) {
      state = state.copyWith(clearSubtype: true);
    } else {
      state = state.copyWith(selectedSubtype: subtype);
    }
    _reapplySearch();
  }

  void selectBrand(String? brand) {
    if (state.selectedBrand == brand) {
      state = state.copyWith(clearBrand: true);
    } else {
      state = state.copyWith(selectedBrand: brand);
    }
    _reapplySearch();
  }

  void selectPackSize(String? packSize) {
    if (state.selectedPackSize == packSize) {
      state = state.copyWith(clearPackSize: true);
    } else {
      state = state.copyWith(selectedPackSize: packSize);
    }
    _reapplySearch();
  }

  void setSort(String sort) {
    state = state.copyWith(selectedSort: sort);
    _reapplySearch();
  }

  void clearFilters() {
    state = state.copyWith(
      clearSubtype: true,
      clearBrand: true,
      clearPackSize: true,
      selectedSort: 'default',
    );
    _reapplySearch();
  }

  void _reapplySearch() {
    if (state.homeId != null) {
      searchDeals(homeId: state.homeId!);
    }
  }

  /// Launch external deal URL (store website or deep link)
  Future<bool> launchDealUrl(String? url) async {
    if (url == null || url.trim().isEmpty) return false;
    try {
      final uri = Uri.parse(url.trim());
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (kDebugMode) print('[ProductDealController] launchDealUrl failed: $e');
      return false;
    }
  }
}
