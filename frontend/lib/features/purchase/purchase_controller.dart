import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/sync/sync_providers.dart';
import '../auth/auth_controller.dart';
import '../home_switcher/home_controller.dart';
import 'purchase_model.dart';
import 'purchase_repository.dart';

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  return PurchaseRepository(
    purchaseDao: ref.watch(purchaseDaoProvider),
    inventoryDao: ref.watch(inventoryDaoProvider),
    syncDao: ref.watch(syncDaoProvider),
    apiClient: ref.watch(apiClientProvider),
    syncEngine: ref.watch(syncEngineProvider),
    connectivity: ref.watch(connectivityMonitorProvider),
    database: ref.watch(databaseProvider),
  );
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
  StreamSubscription? _purchasesSub;
  StreamSubscription? _storesSub;

  PurchaseController(this._repo, this._homeId) : super(const PurchaseState()) {
    if (_homeId != null) {
      _subscribeToLocalData();
      _fetchServerDataInBackground();
    }
  }

  /// Subscribe to local DB streams.
  void _subscribeToLocalData() {
    if (_homeId == null) return;

    _purchasesSub = _repo.watchPurchases(_homeId).listen((purchases) {
      if (mounted) {
        state = state.copyWith(purchases: purchases, isLoading: false);
      }
    });

    _storesSub = _repo.watchStores(_homeId).listen((stores) {
      if (mounted) {
        state = state.copyWith(stores: stores);
      }
    });
  }

  Future<void> _fetchServerDataInBackground() async {
    if (_homeId == null) return;
    if (!_repo.isOnline) return;

    try {
      await _repo.sync(_homeId);
    } catch (_) {
      try {
        await _repo.fetchAndCacheFromServer(_homeId);
      } catch (_) {}
    }
  }

  Future<void> loadPurchases() async {
    if (_homeId == null) return;
    await _fetchServerDataInBackground();
  }

  /// Record purchase: local-first with atomic local transaction.
  Future<PurchaseModel?> recordPurchase(Map<String, dynamic> data) async {
    if (_homeId == null) return null;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final purchase = await _repo.recordPurchase(_homeId, data);
      state = state.copyWith(isLoading: false);
      // UI updates automatically via Drift stream
      return purchase;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<StoreModel?> addStore(String name, String? location) async {
    if (_homeId == null) return null;
    try {
      final newStore = await _repo.createStore(_homeId, name, location);
      // Store list updates via Drift stream
      return newStore;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  @override
  void dispose() {
    _purchasesSub?.cancel();
    _storesSub?.cancel();
    super.dispose();
  }
}
