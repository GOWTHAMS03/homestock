import 'package:dio/dio.dart';
import '../../features/auth/auth_state.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';
import 'api_exceptions.dart';

class ApiClient {
  final Dio dio;
  final SecureStorageService secureStorage;

  ApiClient({Dio? customDio, required this.secureStorage})
      : dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: ApiEndpoints.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _setupInterceptors();
  }

  void updateBaseUrl(String newBaseUrl) {
    dio.options.baseUrl = newBaseUrl;
    ApiEndpoints.setBaseUrl(newBaseUrl);
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // If 401 Unauthorized and not already refreshing: try token refresh
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/')) {
            final refreshed = await tryRefreshToken();
            if (refreshed) {
              final token = await secureStorage.getAccessToken();
              final opts = Options(
                method: error.requestOptions.method,
                headers: {
                  ...error.requestOptions.headers,
                  'Authorization': 'Bearer $token',
                },
              );
              try {
                final cloneReq = await dio.request(
                  error.requestOptions.path,
                  options: opts,
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                );
                return handler.resolve(cloneReq);
              } catch (e) {
                return handler.next(error);
              }
            }
          }

          // Parse standardized backend error response
          final data = error.response?.data;
          String message = 'An unexpected error occurred. Please try again.';
          String? code;
          Map<String, dynamic>? errors;

          if (data is Map<String, dynamic>) {
            if (data['message'] != null) message = data['message'].toString();
            if (data['code'] != null) code = data['code'].toString();
            if (data['errors'] != null && data['errors'] is Map<String, dynamic>) {
              errors = data['errors'] as Map<String, dynamic>;
            }
          }

          final apiException = ApiException(
            message: message,
            code: code,
            statusCode: error.response?.statusCode,
            errors: errors,
          );

          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: apiException,
              response: error.response,
              type: error.type,
            ),
          );
        },
      ),
    );
  }

  Future<bool> tryRefreshToken() async {
    final refreshToken = await secureStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      ).post(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        final newAccess = data['accessToken'] as String?;
        final newRefresh = data['refreshToken'] as String?;
        if (newAccess != null && newRefresh != null) {
          await secureStorage.saveTokens(accessToken: newAccess, refreshToken: newRefresh);
          if (data['user'] != null) {
            try {
              final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
              await secureStorage.saveUser(user);
            } catch (_) {}
          }
          return true;
        }
      }
    } on DioException catch (e) {
      // ONLY clear storage if refresh token is explicitly rejected (401/403/400)
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403 || e.response?.statusCode == 400) {
        await secureStorage.clearAll();
      }
      // If it's a network timeout, connection error, or 500 error: DO NOT CLEAR STORAGE!
    } catch (_) {
      // Unknown error, preserve storage
    }
    return false;
  }
}
