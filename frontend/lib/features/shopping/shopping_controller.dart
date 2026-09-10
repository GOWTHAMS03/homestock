import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/sync_providers.dart';
import '../auth/auth_controller.dart';
import '../home_switcher/home_controller.dart';
import 'shopping_model.dart';
import 'shopping_repository.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository(
    shoppingDao: ref.watch(shoppingDaoProvider),
    syncDao: ref.watch(syncDaoProvider),
    apiClient: ref.watch(apiClientProvider),
    syncEngine: ref.watch(syncEngineProvider),
    connectivity: ref.watch(connectivityMonitorProvider),
    inventoryDao: ref.watch(inventoryDaoProvider),
    database: ref.watch(databaseProvider),
  );
});

class ShoppingState {
  final bool isLoading;
  final ShoppingListModel? list;
  final String? errorMessage;

  const ShoppingState({
    this.isLoading = false,
    this.list,
    this.errorMessage,
  });

  ShoppingState copyWith({
    bool? isLoading,
    ShoppingListModel? list,
    String? errorMessage,
  }) {
    return ShoppingState(
      isLoading: isLoading ?? this.isLoading,
      list: list ?? this.list,
      errorMessage: errorMessage,
    );
  }
}

final shoppingControllerProvider = StateNotifierProvider<ShoppingController, ShoppingState>((ref) {
  final repo = ref.watch(shoppingRepositoryProvider);
  final homeState = ref.watch(homeControllerProvider);
  final effectiveHomeId = homeState.activeHome?.id ?? homeState.homes.firstOrNull?.id;
  return ShoppingController(repo, effectiveHomeId);
});

class ShoppingController extends StateNotifier<ShoppingState> {
  final ShoppingRepository _repo;
  String? _homeId;
  StreamSubscription? _listSub;

  ShoppingController(this._repo, this._homeId) : super(const ShoppingState()) {
    if (_homeId != null && _homeId!.isNotEmpty && _homeId != 'default_home') {
      _subscribeToLocalData();
      _fetchServerDataInBackground();
    } else {
      _tryResolveHomeAndInitialize();
    }
  }

  Future<void> _tryResolveHomeAndInitialize() async {
    await _repo.cleanupLegacyDefaultHome();
    final resolved = await _repo.resolveFallbackHomeId();
    if (resolved != null && resolved.isNotEmpty && resolved != 'default_home' && mounted) {
      _homeId = resolved;
      _subscribeToLocalData();
      _fetchServerDataInBackground();
    }
  }

  Future<String?> _getOrResolveHomeId() async {
    if (_homeId != null && _homeId!.isNotEmpty && _homeId != 'default_home') {
      return _homeId;
    }
    final resolved = await _repo.resolveFallbackHomeId();
    if (resolved != null && resolved.isNotEmpty && resolved != 'default_home') {
      _homeId = resolved;
      _subscribeToLocalData();
      return _homeId;
    }
    return null;
  }

  /// Subscribe to local DB stream for instant UI updates.
  void _subscribeToLocalData() {
    final homeId = _homeId;
    if (homeId == null || homeId.isEmpty || homeId == 'default_home') return;

    _listSub?.cancel();
    _listSub = _repo.watchDefaultList(homeId).listen(
      (list) {
        if (mounted) {
          state = state.copyWith(list: list, isLoading: false);
        }
      },
      onError: (err) {
        if (mounted) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Error loading shopping list: $err',
          );
        }
      },
    );
  }

  /// Fetch from server in background (non-blocking).
  Future<void> _fetchServerDataInBackground() async {
    final homeId = await _getOrResolveHomeId();
    if (homeId == null) return;
    if (!_repo.isOnline) return;

    try {
      await _repo.fetchAndCacheFromServer(homeId);
    } catch (_) {
      // Server failures are non-fatal
    }
  }

  Future<void> loadShoppingList() async {
    final homeId = await _getOrResolveHomeId();
    if (homeId == null) return;
    await _fetchServerDataInBackground();
  }

  /// Add item: local-first, no network wait.
  Future<bool> addItem({
    String? inventoryItemId,
    required String itemName,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    required double quantity,
    String unit = 'pcs',
    String? notes,
  }) async {
    final activeHomeId = await _getOrResolveHomeId();
    if (activeHomeId == null || activeHomeId.isEmpty) {
      state = state.copyWith(errorMessage: 'No active home selected.');
      return false;
    }

    try {
      final defaultList = await _repo.ensureDefaultList(activeHomeId);
      final listId = state.list?.id ?? defaultList.id;
      await _repo.addItem(
        activeHomeId,
        listId,
        inventoryItemId: inventoryItemId,
        itemName: itemName,
        categoryId: categoryId,
        categoryName: categoryName,
        categoryIcon: categoryIcon,
        categoryColor: categoryColor,
        quantity: quantity,
        unit: unit,
        notes: notes,
      );
      if (state.errorMessage != null) {
        state = state.copyWith(errorMessage: null);
      }
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Toggle item: local-first, no rollback needed.
  Future<void> toggleItem(String itemId) async {
    final activeHomeId = await _getOrResolveHomeId();
    if (activeHomeId == null) return;

    try {
      final defaultList = await _repo.ensureDefaultList(activeHomeId);
      final listId = state.list?.id ?? defaultList.id;
      await _repo.toggleItem(activeHomeId, listId, itemId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Update item quantity: local-first.
  Future<void> updateQuantity(String itemId, double newQuantity) async {
    final activeHomeId = await _getOrResolveHomeId();
    if (activeHomeId == null) return;
    if (newQuantity <= 0) {
      await deleteItem(itemId);
      return;
    }
    try {
      final defaultList = await _repo.ensureDefaultList(activeHomeId);
      final listId = state.list?.id ?? defaultList.id;
      await _repo.updateQuantity(activeHomeId, listId, itemId, newQuantity);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Delete item: local-first.
  Future<void> deleteItem(String itemId) async {
    final activeHomeId = await _getOrResolveHomeId();
    if (activeHomeId == null) return;
    try {
      final defaultList = await _repo.ensureDefaultList(activeHomeId);
      final listId = state.list?.id ?? defaultList.id;
      await _repo.deleteItem(activeHomeId, listId, itemId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Mark batch of items completed: local-first.
  Future<void> markItemsCompleted(List<String> itemIds) async {
    final activeHomeId = await _getOrResolveHomeId();
    if (activeHomeId == null) return;
    try {
      await _repo.markItemsCompleted(activeHomeId, itemIds);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Clear completed: local-first.
  Future<void> clearCompleted() async {
    final activeHomeId = await _getOrResolveHomeId();
    if (activeHomeId == null) return;
    try {
      final defaultList = await _repo.ensureDefaultList(activeHomeId);
      final listId = state.list?.id ?? defaultList.id;
      await _repo.clearCompleted(activeHomeId, listId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  @override
  void dispose() {
    _listSub?.cancel();
    super.dispose();
  }
}

extension CountExtension on Iterable {
  int get count => length;
}
