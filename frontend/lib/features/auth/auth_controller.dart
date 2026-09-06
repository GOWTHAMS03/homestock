import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/cache_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../home_switcher/home_controller.dart';
import 'auth_repository.dart';
import 'auth_state.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  return SecureStorageService(cacheService: cache);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(secureStorage: storage);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(apiClient: client, storage: storage);
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo, ref);
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthController(this._repo, this._ref)
      : super(_computeInitialState(_repo.storage)) {
    checkAuthStatus();
  }

  static AuthState _computeInitialState(SecureStorageService storage) {
    final cachedUser = storage.getCachedUserSync();
    final hasTokens = storage.hasCachedTokensSync();
    if (cachedUser != null && hasTokens) {
      return AuthState(
        isLoading: false,
        isAuthenticated: true,
        user: cachedUser,
      );
    }
    return const AuthState(isLoading: true);
  }

  Future<void> checkAuthStatus() async {
    // 1. If already hydrated from synchronous cache in constructor,
    // trigger home loading and verify session in background.
    if (state.isAuthenticated && state.user != null) {
      _ref.read(homeControllerProvider.notifier).loadHomes();
      await _verifySessionWithServer();
      return;
    }

    // 2. Check async persistent storage (KeyStore / SecureStorage)
    final localUser = await _repo.storage.getUser();
    final accessToken = await _repo.storage.getAccessToken();
    final refreshToken = await _repo.storage.getRefreshToken();
    final hasTokens = (accessToken != null && accessToken.isNotEmpty) ||
        (refreshToken != null && refreshToken.isNotEmpty);

    if (localUser != null && hasTokens) {
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: localUser);
      _ref.read(homeControllerProvider.notifier).loadHomes();
      await _verifySessionWithServer();
      return;
    }

    if (!hasTokens) {
      state = state.copyWith(isLoading: false, isAuthenticated: false, user: null);
      return;
    }

    // Has tokens but localUser is missing: fetch from backend
    final user = await _repo.getCurrentUser();
    if (user != null) {
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
      _ref.read(homeControllerProvider.notifier).loadHomes();
    } else {
      state = state.copyWith(isLoading: false, isAuthenticated: false, user: null);
    }
  }

  Future<void> _verifySessionWithServer() async {
    try {
      final freshUser = await _repo.getCurrentUser();
      if (freshUser != null) {
        state = state.copyWith(user: freshUser);
      } else {
        // Refresh token was explicitly rejected / expired
        state = const AuthState(isAuthenticated: false);
      }
    } catch (_) {
      // Network error / offline / timeout: PRESERVE LOGIN SESSION!
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repo.login(email, password);
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
      _ref.read(homeControllerProvider.notifier).loadHomes();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repo.register(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
      state = state.copyWith(isLoading: false, isAuthenticated: true, user: user);
      _ref.read(homeControllerProvider.notifier).loadHomes();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _ref.read(homeControllerProvider.notifier).reset();
    state = const AuthState(isAuthenticated: false);
  }
}
