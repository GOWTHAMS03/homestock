import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/sync_providers.dart';
import '../auth/auth_controller.dart' show apiClientProvider;
import '../home_switcher/home_controller.dart';
import 'category_model.dart';
import 'inventory_model.dart';
import 'inventory_repository.dart';

export '../../core/sync/sync_providers.dart' show inventoryDaoProvider, syncDaoProvider;

/// Provider for the offline-first InventoryRepository.
final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(
    inventoryDao: ref.watch(inventoryDaoProvider),
    syncDao: ref.watch(syncDaoProvider),
    apiClient: ref.watch(apiClientProvider),
    connectivity: ref.watch(connectivityMonitorProvider),
    syncEngine: ref.watch(syncEngineProvider),
    database: ref.watch(databaseProvider),
  );
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
  StreamSubscription? _itemsSub;
  StreamSubscription? _categoriesSub;

  InventoryController(this._repo, this._homeId)
      : super(InventoryState(
          categories: CategoryModel.defaultCategories(_homeId),
        )) {
    if (_homeId != null) {
      _subscribeToLocalData();
      _fetchServerDataInBackground();
    }
  }

  /// Subscribe to reactive Drift streams for instant local data display.
  void _subscribeToLocalData() {
    if (_homeId == null) return;

    // Watch categories from local DB
    _categoriesSub = _repo.watchCategories(_homeId).listen((categories) {
      if (mounted) {
        final list = categories.isNotEmpty
            ? categories
            : CategoryModel.defaultCategories(_homeId);
        final uniqueMap = <String, CategoryModel>{};
        for (final cat in list) {
          final key = cat.name.trim().toLowerCase();
          if (!uniqueMap.containsKey(key)) {
            uniqueMap[key] = cat;
          } else if (uniqueMap[key]!.id.startsWith('default_') && !cat.id.startsWith('default_')) {
            uniqueMap[key] = cat;
          }
        }
        final deduplicated = uniqueMap.values.toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

        state = state.copyWith(categories: deduplicated);
      }
    });

    // Watch items from local DB (filtered by current search/category)
    _watchItems();
  }

  void _watchItems() {
    _itemsSub?.cancel();
    if (_homeId == null) return;

    final selectedCat = state.categories.cast<CategoryModel?>().firstWhere(
          (c) => c?.id == state.selectedCategoryId,
          orElse: () => null,
        );

    _itemsSub = _repo
        .watchItems(
          _homeId,
          categoryId: state.selectedCategoryId,
          categoryName: selectedCat?.name,
          query: state.searchQuery.isEmpty ? null : state.searchQuery,
        )
        .listen((items) {
      if (mounted) {
        state = state.copyWith(items: items, isLoading: false);
      }
    });
  }

  /// Fetch server data in background (non-blocking).
  /// Pushes local pending changes first, then pulls and reconciles remote changes.
  Future<void> _fetchServerDataInBackground() async {
    if (_homeId == null) return;
    if (!_repo.isOnline) return;

    try {
      await _repo.sync(_homeId);
    } catch (_) {
      try {
        await _repo.fetchAndCacheCategories(_homeId);
        await _repo.fetchAndCacheFromServer(_homeId);
      } catch (_) {}
    }
  }

  /// Manually trigger a refresh (pull-to-refresh).
  Future<void> loadData() async {
    if (_homeId == null) return;
    await _fetchServerDataInBackground();
  }

  void selectCategory(String? categoryId) {
    if (state.selectedCategoryId == categoryId) {
      state = state.copyWith(selectedCategoryId: null);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
    _watchItems(); // Re-subscribe with new filter
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _watchItems(); // Re-subscribe with new search
  }

  void setFilterType(InventoryFilterType type) {
    state = state.copyWith(filterType: type);
  }

  /// Update stock: local-first with sync queue.
  Future<bool> updateStock(String itemId, String transactionType, double quantityChange, [String? reason]) async {
    if (_homeId == null) return false;
    try {
      await _repo.updateStock(
        _homeId,
        itemId,
        transactionType: transactionType,
        quantityChange: quantityChange,
        reason: reason,
      );
      // UI updates automatically via Drift stream subscription
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Create item: local-first with sync queue.
  Future<bool> createItem(Map<String, dynamic> data) async {
    if (_homeId == null) return false;
    try {
      await _repo.createItem(_homeId, data);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Update item: local-first with sync queue.
  Future<bool> updateItem(String itemId, Map<String, dynamic> data) async {
    if (_homeId == null) return false;
    try {
      await _repo.updateItem(_homeId, itemId, data);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  @override
  void dispose() {
    _itemsSub?.cancel();
    _categoriesSub?.cancel();
    super.dispose();
  }
}
