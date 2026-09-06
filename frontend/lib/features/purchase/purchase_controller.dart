import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_controller.dart';
import '../home_switcher/home_controller.dart';
import 'purchase_model.dart';
import 'purchase_repository.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return PurchaseRepository(apiClient: client);
});

class PurchaseState {
  final bool isLoading;
  final List<PurchaseModel> purchases;
  final List<StoreModel> stores;
  final String? errorMessage;

  const PurchaseState({
    this.isLoading = false,
    this.purchases = const [],
    this.stores = const [],
    this.errorMessage,
  });

  PurchaseState copyWith({
    bool? isLoading,
    List<PurchaseModel>? purchases,
    List<StoreModel>? stores,
    String? errorMessage,
  }) {
    return PurchaseState(
      isLoading: isLoading ?? this.isLoading,
      purchases: purchases ?? this.purchases,
      stores: stores ?? this.stores,
      errorMessage: errorMessage,
    );
  }
}

final purchaseControllerProvider = StateNotifierProvider<PurchaseController, PurchaseState>((ref) {
  final repo = ref.watch(purchaseRepositoryProvider);
  final homeState = ref.watch(homeControllerProvider);
  return PurchaseController(repo, homeState.activeHome?.id);
});

class PurchaseController extends StateNotifier<PurchaseState> {
  final PurchaseRepository _repo;
  final String? _homeId;

  PurchaseController(this._repo, this._homeId) : super(const PurchaseState()) {
    if (_homeId != null) {
      loadPurchases();
    }
  }

  Future<void> loadPurchases() async {
    if (_homeId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final stores = await _repo.getStores(_homeId);
      final purchases = await _repo.getPurchases(_homeId);
      state = state.copyWith(isLoading: false, purchases: purchases, stores: stores);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> recordPurchase(Map<String, dynamic> data) async {
    if (_homeId == null) return false;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final newPurchase = await _repo.recordPurchase(_homeId, data);
      state = state.copyWith(
        isLoading: false,
        purchases: [newPurchase, ...state.purchases],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<StoreModel?> addStore(String name, String? location) async {
    if (_homeId == null) return null;
    try {
      final newStore = await _repo.createStore(_homeId, name, location);
      state = state.copyWith(stores: [...state.stores, newStore]);
      return newStore;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }
}
