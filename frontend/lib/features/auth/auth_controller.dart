import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/storage/cache_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../core/sync/sync_providers.dart' show connectivityMonitorProvider;
import '../../core/notifications/notification_service.dart';
import '../../core/notifications/notification_providers.dart';
import '../home_switcher/home_controller.dart';
import 'auth_repository.dart';
import 'auth_state.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  return SecureStorageService(cacheService: cache);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final monitor = ref.watch(connectivityMonitorProvider);
  return ApiClient(secureStorage: storage, connectivityMonitor: monitor);
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
    _setupApiClientHooks();
    checkAuthStatus();
  }

  void _setupApiClientHooks() {
    _repo.apiClient.onUserNotFound = () {
      handleUserNotFound();
    };
    _repo.apiClient.onAccountDisabled = () {
      handleAccountDisabled();
    };
    _repo.apiClient.onMembershipRemoved = (roomId) {
      handleMembershipRemoved(roomId);
    };
  }

  static AuthState _computeInitialState(SecureStorageService storage) {
    final cachedUser = storage.getCachedUserSync();
    final hasTokens = storage.hasCachedTokensSync();
    if (cachedUser != null && hasTokens) {
      return AuthState(
        status: AuthStatus.authenticated,
        isLoading: false,
        user: cachedUser,
      );
    }
    return const AuthState(status: AuthStatus.initializing, isLoading: true);
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
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isLoading: false,
        user: localUser,
      );
      _ref.read(homeControllerProvider.notifier).loadHomes();
      await _verifySessionWithServer();
      return;
    }

    if (!hasTokens) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        user: null,
      );
      return;
    }

    // Has tokens but localUser is missing: fetch from backend
    try {
      final user = await _repo.getCurrentUser();
      if (user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          isLoading: false,
          user: user,
        );
        _ref.read(homeControllerProvider.notifier).loadHomes();
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          user: null,
        );
      }
    } on ApiException catch (e) {
      if (e.code == 'USER_NOT_FOUND') {
        handleUserNotFound();
      } else if (e.code == 'ACCOUNT_DISABLED') {
        handleAccountDisabled();
      } else {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          user: null,
        );
      }
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        user: null,
      );
    }
  }

  Future<void> _verifySessionWithServer() async {
    try {
      final freshUser = await _repo.getCurrentUser();
      if (freshUser != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: freshUser,
        );
      } else {
        state = const AuthState(
          status: AuthStatus.sessionExpired,
          verificationNotice: "Your session has expired. Please sign in again.",
        );
      }
    } on ApiException catch (e) {
      if (e.code == 'USER_NOT_FOUND') {
        handleUserNotFound();
      } else if (e.code == 'ACCOUNT_DISABLED') {
        handleAccountDisabled();
      }
    } catch (_) {
      // Network error / offline / timeout: PRESERVE LOGIN SESSION!
    }
  }

  void handleUserNotFound() {
    _repo.storage.clearAll();
    state = const AuthState(
      status: AuthStatus.userNotFound,
      isLoading: false,
      user: null,
      verificationNotice:
          "We couldn't verify your HomeStock account.\n\nYour account may have been removed or your session is no longer valid.\n\nPlease sign in again to continue.",
    );
  }

  void handleAccountDisabled() {
    _repo.storage.clearAll();
    state = const AuthState(
      status: AuthStatus.accountDisabled,
      isLoading: false,
      user: null,
      verificationNotice: "This HomeStock account is disabled. Please contact support.",
    );
  }

  void handleMembershipRemoved(String roomId) {
    state = state.copyWith(
      status: AuthStatus.membershipRemoved,
      activeRoomId: roomId,
      verificationNotice: "You are no longer an active member of this household.",
    );
  }

  Future<bool> login(String identifier, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null, verificationNotice: null);
    try {
      final user = await _repo.login(identifier, password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isLoading: false,
        user: user,
      );
      _ref.read(homeControllerProvider.notifier).loadHomes();
      _registerFcmToken();
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: _formatError(e),
      );
      return false;
    }
  }

  Future<bool> loginWithGoogle(
    String idToken, {
    String? email,
    String? displayName,
    String? avatarUrl,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, verificationNotice: null);
    try {
      final user = await _repo.loginWithGoogle(
        idToken,
        email: email,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isLoading: false,
        user: user,
      );
      _ref.read(homeControllerProvider.notifier).loadHomes();
      _registerFcmToken();
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: _formatError(e),
      );
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? username,
    String? confirmPassword,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, verificationNotice: null);
    try {
      final user = await _repo.register(
        email: email,
        password: password,
        fullName: fullName,
        username: username,
        confirmPassword: confirmPassword,
        phoneNumber: phoneNumber,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isLoading: false,
        user: user,
      );
      _ref.read(homeControllerProvider.notifier).loadHomes();
      _registerFcmToken();
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: _formatError(e),
      );
      return false;
    }
  }

  Future<bool> loginWithInviteCode({
    required String inviteCode,
    required String fullName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, verificationNotice: null);
    try {
      final user = await _repo.loginWithInviteCode(
        inviteCode: inviteCode,
        fullName: fullName,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        isLoading: false,
        user: user,
      );
      await _ref.read(homeControllerProvider.notifier).loadHomes();
      _registerFcmToken();
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: _formatError(e),
      );
      return false;
    }
  }

  String _formatError(dynamic e) {
    if (e is DioException) {
      if (e.error is ApiException) {
        return (e.error as ApiException).message;
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Cannot reach server at ${ApiEndpoints.baseUrl}. Check Wi-Fi or tap Server Settings below.';
      }
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        return e.response!.data['message'].toString();
      }
    }
    final str = e.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring(11);
    }
    return str;
  }

  Future<void> logout() async {
    final token = NotificationService.instance.fcmToken;
    if (token != null) {
      try {
        await _ref.read(notificationRepositoryProvider).deactivateDeviceToken(token);
      } catch (_) {}
    }
    await _repo.logout();
    _ref.read(homeControllerProvider.notifier).reset();
    state = const AuthState(status: AuthStatus.unauthenticated, isLoading: false, user: null);
  }

  /// Ensure FCM device token is registered with the backend.
  Future<void> ensureFcmTokenRegistered() async {
    await _registerFcmToken();
  }

  Future<void> _registerFcmToken() async {
    String? token = NotificationService.instance.fcmToken;
    if (token == null || token.isEmpty) {
      try {
        token = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        // Firebase messaging may be in mock/offline mode
      }
    }
    if (token != null && token.isNotEmpty) {
      try {
        await _ref.read(notificationRepositoryProvider).registerDeviceToken(
          token: token,
          platform: 'ANDROID',
        );
      } catch (_) {}
    }
  }
}
