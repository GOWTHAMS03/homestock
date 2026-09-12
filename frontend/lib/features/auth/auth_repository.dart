import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/storage/secure_storage_service.dart';
import 'auth_state.dart';

class AuthRepository {
  final ApiClient apiClient;
  final SecureStorageService storage;

  AuthRepository({required this.apiClient, required this.storage});

  Future<UserProfile> login(String identifier, String password) async {
    final response = await apiClient.dio.post(
      ApiEndpoints.login,
      data: {'email': identifier.trim(), 'password': password},
    );

    final data = response.data['data'];
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    await storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);

    final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    await storage.saveUser(user);
    return user;
  }

  Future<UserProfile> loginWithGoogle(
    String idToken, {
    String? email,
    String? displayName,
    String? avatarUrl,
  }) async {
    final response = await apiClient.dio.post(
      '/api/v1/auth/google',
      data: {
        'idToken': idToken,
        if (email != null && email.isNotEmpty) 'email': email,
        if (displayName != null && displayName.isNotEmpty) 'displayName': displayName,
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
      },
    );

    final data = response.data['data'];
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    await storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);

    final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    await storage.saveUser(user);
    return user;
  }

  Future<UserProfile> register({
    required String email,
    required String password,
    required String fullName,
    String? username,
    String? confirmPassword,
    String? phoneNumber,
  }) async {
    final response = await apiClient.dio.post(
      ApiEndpoints.register,
      data: {
        'email': email.trim(),
        'password': password,
        'fullName': fullName.trim(),
        if (username != null && username.trim().isNotEmpty) 'username': username.trim(),
        if (confirmPassword != null && confirmPassword.isNotEmpty) 'confirmPassword': confirmPassword,
        'phoneNumber': phoneNumber,
      },
    );

    final data = response.data['data'];
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    await storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);

    final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    await storage.saveUser(user);
    return user;
  }

  Future<UserProfile?> getCurrentUser() async {
    final token = await storage.getAccessToken();
    final refreshToken = await storage.getRefreshToken();
    if ((token == null || token.isEmpty) && (refreshToken == null || refreshToken.isEmpty)) {
      return null;
    }

    // 1. Read cached user for initial local state
    final cachedUser = await storage.getUser();

    // 2. Attempt to verify/refresh user info from backend
    try {
      final response = await apiClient.dio.get(ApiEndpoints.userMe);
      if (response.data != null && response.data['data'] != null) {
        final freshUser = UserProfile.fromJson(response.data['data'] as Map<String, dynamic>);
        await storage.saveUser(freshUser);
        return freshUser;
      }
    } on DioException catch (e) {
      // If user does not exist in DB: NEVER KEEP CACHED USER!
      if (e.error is ApiException) {
        final apiEx = e.error as ApiException;
        if (apiEx.code == 'USER_NOT_FOUND' || (e.response?.statusCode == 401 && apiEx.code == 'USER_NOT_FOUND')) {
          await storage.clearAll();
          throw apiEx;
        }
      }

      // If unauthorized (401/403), attempt token refresh once
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        final refreshed = await apiClient.tryRefreshToken();
        if (refreshed) {
          try {
            final retryResponse = await apiClient.dio.get(ApiEndpoints.userMe);
            if (retryResponse.data != null && retryResponse.data['data'] != null) {
              final freshUser = UserProfile.fromJson(retryResponse.data['data'] as Map<String, dynamic>);
              await storage.saveUser(freshUser);
              return freshUser;
            }
          } catch (_) {}
          // Token was refreshed successfully, keep cached user
          if (cachedUser != null) return cachedUser;
        } else {
          // Refresh token expired or revoked - clear session
          await storage.clearAll();
          return null;
        }
      }
      // For network errors / offline / 500: DO NOT LOG OUT! Return cached user.
      if (cachedUser != null) return cachedUser;
    } catch (_) {
      if (cachedUser != null) return cachedUser;
    }

    return cachedUser;
  }

  Future<void> logout() async {
    final refresh = await storage.getRefreshToken();
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await apiClient.dio.post(ApiEndpoints.logout, data: {'refreshToken': refresh});
      }
    } catch (_) {}
    await storage.clearAll();
  }

  Future<UserProfile> loginWithInviteCode({
    required String inviteCode,
    required String fullName,
  }) async {
    final response = await apiClient.dio.post(
      ApiEndpoints.inviteLogin,
      data: {
        'inviteCode': inviteCode.trim().toUpperCase(),
        'fullName': fullName.trim(),
      },
    );

    final data = response.data['data'];
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    await storage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);

    final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    await storage.saveUser(user);
    return user;
  }
}
