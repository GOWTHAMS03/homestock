import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_controller.dart' show apiClientProvider;
import '../models/shop_models.dart';
import '../repositories/shop_owner_repository.dart';

final shopOwnerRepositoryProvider = Provider<ShopOwnerRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ShopOwnerRepository(apiClient: client);
});

class ShopOwnerState {
  final ShopProfileModel? shop;
  final ShopDashboardModel? dashboard;
  final ShopSubscriptionModel? subscription;
  final List<SubscriptionPlanModel> availablePlans;
  final List<ShopProductModel> products;
  final List<ShopDealModel> deals;
  final bool isLoading;
  final String? errorMessage;

  const ShopOwnerState({
    this.shop,
    this.dashboard,
    this.subscription,
    this.availablePlans = const [],
    this.products = const [],
    this.deals = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  bool get hasShop => shop != null;
  bool get isVerified => shop?.isVerified ?? false;
  bool get isPending => shop?.isPending ?? false;
  bool get isRejected => shop?.isRejected ?? false;
  bool get isSuspended => shop?.isSuspended ?? false;

  ShopOwnerState copyWith({
    ShopProfileModel? shop,
    bool clearShop = false,
    ShopDashboardModel? dashboard,
    ShopSubscriptionModel? subscription,
    List<SubscriptionPlanModel>? availablePlans,
    List<ShopProductModel>? products,
    List<ShopDealModel>? deals,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ShopOwnerState(
      shop: clearShop ? null : (shop ?? this.shop),
      dashboard: dashboard ?? this.dashboard,
      subscription: subscription ?? this.subscription,
      availablePlans: availablePlans ?? this.availablePlans,
      products: products ?? this.products,
      deals: deals ?? this.deals,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ShopOwnerController extends StateNotifier<ShopOwnerState> {
  final ShopOwnerRepository _repository;

  ShopOwnerController(this._repository) : super(const ShopOwnerState()) {
    loadMyShop();
  }

  Future<void> loadMyShop() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final shop = await _repository.getMyShop();
      state = state.copyWith(shop: shop, isLoading: false);
      if (shop != null) {
        await Future.wait([
          loadDashboard(),
          loadProducts(),
          loadDeals(),
          loadSubscription(),
        ]);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> registerShop(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final shop = await _repository.registerShop(data);
      state = state.copyWith(shop: shop, isLoading: false);
      await loadSubscription();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateShopProfile(Map<String, dynamic> data) async {
    if (state.shop == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repository.updateShopProfile(state.shop!.id, data);
      state = state.copyWith(shop: updated, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> loadDashboard() async {
    if (state.shop == null) return;
    try {
      final dashboard = await _repository.getDashboard(state.shop!.id);
      state = state.copyWith(dashboard: dashboard);
    } catch (e) {
      // Keep existing state if dashboard fails
    }
  }

  Future<void> loadProducts() async {
    if (state.shop == null) return;
    try {
      final products = await _repository.getShopProducts(state.shop!.id);
      state = state.copyWith(products: products);
    } catch (e) {
      // Error handled quietly or reported
    }
  }

  Future<bool> addProduct(Map<String, dynamic> data) async {
    if (state.shop == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final product = await _repository.addProduct(state.shop!.id, data);
      final updatedProducts = [product, ...state.products];
      state = state.copyWith(products: updatedProducts, isLoading: false);
      await loadSubscription();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateProduct(String productId, Map<String, dynamic> data) async {
    if (state.shop == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repository.updateProduct(state.shop!.id, productId, data);
      final list = state.products.map((p) => p.id == productId ? updated : p).toList();
      state = state.copyWith(products: list, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    if (state.shop == null) return false;
    try {
      await _repository.deleteProduct(state.shop!.id, productId);
      final list = state.products.where((p) => p.id != productId).toList();
      state = state.copyWith(products: list);
      await loadSubscription();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<void> loadDeals() async {
    if (state.shop == null) return;
    try {
      final deals = await _repository.getShopDeals(state.shop!.id);
      state = state.copyWith(deals: deals);
    } catch (e) {
      // Error handled quietly
    }
  }

  Future<bool> createDeal(Map<String, dynamic> data) async {
    if (state.shop == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final deal = await _repository.createDeal(state.shop!.id, data);
      state = state.copyWith(deals: [deal, ...state.deals], isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateDeal(String dealId, Map<String, dynamic> data) async {
    if (state.shop == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _repository.updateDeal(state.shop!.id, dealId, data);
      final list = state.deals.map((d) => d.id == dealId ? updated : d).toList();
      state = state.copyWith(deals: list, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteDeal(String dealId) async {
    if (state.shop == null) return false;
    try {
      await _repository.deleteDeal(state.shop!.id, dealId);
      final list = state.deals.where((d) => d.id != dealId).toList();
      state = state.copyWith(deals: list);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<void> loadSubscription() async {
    if (state.shop == null) return;
    try {
      final sub = await _repository.getShopSubscription(state.shop!.id);
      final plans = await _repository.getSubscriptionPlans();
      state = state.copyWith(subscription: sub, availablePlans: plans);
    } catch (e) {
      // Handled quietly
    }
  }

  Future<bool> upgradePlan(String planName) async {
    if (state.shop == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sub = await _repository.upgradePlan(state.shop!.id, planName);
      state = state.copyWith(subscription: sub, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final shopOwnerControllerProvider =
    StateNotifierProvider<ShopOwnerController, ShopOwnerState>((ref) {
  final repo = ref.watch(shopOwnerRepositoryProvider);
  return ShopOwnerController(repo);
});
