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
  return ShoppingController(repo, homeState.activeHome?.id);
});

class ShoppingController extends StateNotifier<ShoppingState> {
  final ShoppingRepository _repo;
  final String? _homeId;
  StreamSubscription? _listSub;

  ShoppingController(this._repo, this._homeId) : super(const ShoppingState()) {
    if (_homeId != null) {
      _subscribeToLocalData();
      _fetchServerDataInBackground();
    }
  }

  /// Subscribe to local DB stream for instant UI updates.
  void _subscribeToLocalData() {
    if (_homeId == null) return;

    _listSub = _repo.watchDefaultList(_homeId).listen((list) {
      if (mounted) {
        state = state.copyWith(list: list, isLoading: false);
      }
    });
  }

  /// Fetch from server in background (non-blocking).
  Future<void> _fetchServerDataInBackground() async {
    if (_homeId == null) return;
    state = state.copyWith(isLoading: state.list == null);

    try {
      await _repo.fetchAndCacheFromServer(_homeId);
    } catch (_) {
      // Server failures are non-fatal
    }
  }

  Future<void> loadShoppingList() async {
    if (_homeId == null) return;
    state = state.copyWith(isLoading: state.list == null, errorMessage: null);
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
    if (_homeId == null) return false;

    try {
      final listId = state.list?.id ?? (await _repo.ensureDefaultList(_homeId)).id;
      await _repo.addItem(
        _homeId,
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
      // UI updates automatically via Drift stream
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Toggle item: local-first, no rollback needed.
  Future<void> toggleItem(String itemId) async {
    if (_homeId == null) return;

    try {
      final listId = state.list?.id ?? (await _repo.ensureDefaultList(_homeId)).id;
      await _repo.toggleItem(_homeId, listId, itemId);
      // UI updates automatically via Drift stream
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Delete item: local-first.
  Future<void> deleteItem(String itemId) async {
    if (_homeId == null) return;
    try {
      final listId = state.list?.id ?? (await _repo.ensureDefaultList(_homeId)).id;
      await _repo.deleteItem(_homeId, listId, itemId);
      // UI updates automatically via Drift stream
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Clear completed: local-first.
  Future<void> clearCompleted() async {
    if (_homeId == null) return;
    try {
      final listId = state.list?.id ?? (await _repo.ensureDefaultList(_homeId)).id;
      await _repo.clearCompleted(_homeId, listId);
      // UI updates automatically via Drift stream
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
