import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';
import '../home_switcher/home_controller.dart';
import 'category_model.dart';
import 'inventory_model.dart';
import 'inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return InventoryRepository(apiClient: client);
});

enum InventoryFilterType { all, lowStock, expiringSoon, outOfStock }

class InventoryState {
  final bool isLoading;
  final List<InventoryItemModel> items;
  final List<CategoryModel> categories;
  final String? selectedCategoryId;
  final String searchQuery;
  final InventoryFilterType filterType;
  final String? errorMessage;

  const InventoryState({
    this.isLoading = false,
    this.items = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.searchQuery = '',
    this.filterType = InventoryFilterType.all,
    this.errorMessage,
  });

  List<InventoryItemModel> get filteredItems {
    var list = items;
    switch (filterType) {
      case InventoryFilterType.all:
        break;
      case InventoryFilterType.lowStock:
        list = list.where((i) => i.stockStatus == 'LOW_STOCK' || i.stockStatus == 'OUT_OF_STOCK').toList();
        break;
      case InventoryFilterType.expiringSoon:
        list = list.where((i) => i.expiryStatus == 'EXPIRING_SOON' || i.expiryStatus == 'EXPIRED').toList();
        break;
      case InventoryFilterType.outOfStock:
        list = list.where((i) => i.stockStatus == 'OUT_OF_STOCK').toList();
        break;
    }
    return list;
  }

  InventoryState copyWith({
    bool? isLoading,
    List<InventoryItemModel>? items,
    List<CategoryModel>? categories,
    String? selectedCategoryId,
    String? searchQuery,
    InventoryFilterType? filterType,
    String? errorMessage,
  }) {
    return InventoryState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      filterType: filterType ?? this.filterType,
      errorMessage: errorMessage,
    );
  }
}

final inventoryControllerProvider = StateNotifierProvider<InventoryController, InventoryState>((ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  final homeState = ref.watch(homeControllerProvider);
  return InventoryController(repo, homeState.activeHome?.id);
});

class InventoryController extends StateNotifier<InventoryState> {
  final InventoryRepository _repo;
  final String? _homeId;

  InventoryController(this._repo, this._homeId) : super(const InventoryState()) {
    if (_homeId != null) {
      loadData();
    }
  }

  Future<void> loadData() async {
    if (_homeId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final categories = await _repo.getCategories(_homeId);
      final items = await _repo.getItems(
        _homeId,
        categoryId: state.selectedCategoryId,
        query: state.searchQuery,
      );

      state = state.copyWith(
        isLoading: false,
        categories: categories,
        items: items,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void selectCategory(String? categoryId) {
    if (state.selectedCategoryId == categoryId) {
      state = state.copyWith(selectedCategoryId: null);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
    loadData();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadData();
  }

  void setFilterType(InventoryFilterType type) {
    state = state.copyWith(filterType: type);
  }

  Future<bool> updateStock(String itemId, String transactionType, double quantityChange, [String? reason]) async {
    if (_homeId == null) return false;
    try {
      final updated = await _repo.updateStock(
        _homeId,
        itemId,
        transactionType: transactionType,
        quantityChange: quantityChange,
        reason: reason,
      );

      final updatedList = state.items.map((i) => i.id == itemId ? updated : i).toList();
      state = state.copyWith(items: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}
