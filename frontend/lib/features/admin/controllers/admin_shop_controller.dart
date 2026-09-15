import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_controller.dart' show apiClientProvider;
import '../../shop_owner/models/shop_models.dart';
import '../repositories/admin_shop_repository.dart';

final adminShopRepositoryProvider = Provider<AdminShopRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AdminShopRepository(apiClient: client);
});

class AdminShopState {
  final List<ShopProfileModel> shops;
  final String activeTab; // PENDING, VERIFIED, REJECTED, SUSPENDED
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const AdminShopState({
    this.shops = const [],
    this.activeTab = 'PENDING',
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  AdminShopState copyWith({
    List<ShopProfileModel>? shops,
    String? activeTab,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AdminShopState(
      shops: shops ?? this.shops,
      activeTab: activeTab ?? this.activeTab,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class AdminShopController extends StateNotifier<AdminShopState> {
  final AdminShopRepository _repository;

  AdminShopController(this._repository) : super(const AdminShopState()) {
    loadShops('PENDING');
  }

  Future<void> loadShops(String status) async {
    state = state.copyWith(
      activeTab: status,
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final shops = await _repository.getShopsByStatus(status);
      state = state.copyWith(shops: shops, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> verifyShop(String shopId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.verifyShop(shopId);
      state = state.copyWith(
        successMessage: 'Shop approved and verified successfully!',
        isLoading: false,
      );
      await loadShops(state.activeTab);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> rejectShop(String shopId, {String? reason}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.rejectShop(shopId, reason: reason);
      state = state.copyWith(
        successMessage: 'Shop rejected.',
        isLoading: false,
      );
      await loadShops(state.activeTab);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> suspendShop(String shopId, {String? reason}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.suspendShop(shopId, reason: reason);
      state = state.copyWith(
        successMessage: 'Shop suspended.',
        isLoading: false,
      );
      await loadShops(state.activeTab);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final adminShopControllerProvider =
    StateNotifierProvider<AdminShopController, AdminShopState>((ref) {
  final repo = ref.watch(adminShopRepositoryProvider);
  return AdminShopController(repo);
});
