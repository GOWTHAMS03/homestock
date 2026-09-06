import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';
import '../home_switcher/home_controller.dart';
import 'shopping_model.dart';
import 'shopping_repository.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ShoppingRepository(apiClient: client);
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

  ShoppingController(this._repo, this._homeId) : super(const ShoppingState()) {
    if (_homeId != null) {
      loadShoppingList();
    }
  }

  Future<void> loadShoppingList() async {
    if (_homeId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final list = await _repo.getDefaultList(_homeId);
      state = state.copyWith(isLoading: false, list: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> addItem({
    String? inventoryItemId,
    required String itemName,
    String? categoryId,
    required double quantity,
    String unit = 'pcs',
    String? notes,
  }) async {
    if (_homeId == null || state.list == null) return false;

    try {
      final newItem = await _repo.addItem(
        _homeId,
        state.list!.id,
        inventoryItemId: inventoryItemId,
        itemName: itemName,
        categoryId: categoryId,
        quantity: quantity,
        unit: unit,
        notes: notes,
      );

      final updatedItems = [newItem, ...state.list!.items];
      final updatedList = ShoppingListModel(
        id: state.list!.id,
        homeId: state.list!.homeId,
        name: state.list!.name,
        isDefault: state.list!.isDefault,
        pendingCount: state.list!.pendingCount + 1,
        completedCount: state.list!.completedCount,
        items: updatedItems,
      );

      state = state.copyWith(list: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<void> toggleItem(String itemId) async {
    if (_homeId == null || state.list == null) return;

    // 1. Optimistic UI update
    final currentItems = state.list!.items;
    final targetIndex = currentItems.indexWhere((i) => i.id == itemId);
    if (targetIndex == -1) return;

    final target = currentItems[targetIndex];
    final willBeCompleted = !target.isCompleted;

    final optimisticItem = target.copyWith(
      isCompleted: willBeCompleted,
      completedByName: willBeCompleted ? 'You' : null,
    );

    final updatedItems = List<ShoppingItemModel>.from(currentItems);
    updatedItems[targetIndex] = optimisticItem;

    final updatedList = ShoppingListModel(
      id: state.list!.id,
      homeId: state.list!.homeId,
      name: state.list!.name,
      isDefault: state.list!.isDefault,
      pendingCount: state.list!.pendingCount + (willBeCompleted ? -1 : 1),
      completedCount: state.list!.completedCount + (willBeCompleted ? 1 : -1),
      items: updatedItems,
    );

    state = state.copyWith(list: updatedList);

    // 2. Network sync
    try {
      final serverItem = await _repo.toggleItem(_homeId, state.list!.id, itemId);
      final syncedItems = state.list!.items.map((i) => i.id == itemId ? serverItem : i).toList();
      state = state.copyWith(
        list: ShoppingListModel(
          id: state.list!.id,
          homeId: state.list!.homeId,
          name: state.list!.name,
          isDefault: state.list!.isDefault,
          pendingCount: syncedItems.where((i) => !i.isCompleted).count,
          completedCount: syncedItems.where((i) => i.isCompleted).count,
          items: syncedItems,
        ),
      );
    } catch (e) {
      // Rollback on network failure
      loadShoppingList();
    }
  }

  Future<void> deleteItem(String itemId) async {
    if (_homeId == null || state.list == null) return;
    try {
      await _repo.deleteItem(_homeId, state.list!.id, itemId);
      final updatedItems = state.list!.items.where((i) => i.id != itemId).toList();
      state = state.copyWith(
        list: ShoppingListModel(
          id: state.list!.id,
          homeId: state.list!.homeId,
          name: state.list!.name,
          isDefault: state.list!.isDefault,
          pendingCount: updatedItems.where((i) => !i.isCompleted).length,
          completedCount: updatedItems.where((i) => i.isCompleted).length,
          items: updatedItems,
        ),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> clearCompleted() async {
    if (_homeId == null || state.list == null) return;
    try {
      await _repo.clearCompleted(_homeId, state.list!.id);
      final pendingOnly = state.list!.items.where((i) => !i.isCompleted).toList();
      state = state.copyWith(
        list: ShoppingListModel(
          id: state.list!.id,
          homeId: state.list!.homeId,
          name: state.list!.name,
          isDefault: state.list!.isDefault,
          pendingCount: pendingOnly.length,
          completedCount: 0,
          items: pendingOnly,
        ),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

extension CountExtension on Iterable {
  int get count => length;
}
