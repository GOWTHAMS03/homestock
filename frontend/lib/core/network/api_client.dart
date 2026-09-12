import 'dart:async';
import 'package:dio/dio.dart';
import '../../features/auth/auth_state.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';
import '../sync/connectivity_monitor.dart';
import 'api_exceptions.dart';

class ApiClient {
  final Dio dio;
  final SecureStorageService secureStorage;
  ConnectivityMonitor? connectivityMonitor;
  void Function()? onUserNotFound;
  void Function()? onAccountDisabled;
  void Function(String roomId)? onMembershipRemoved;

  ApiClient({Dio? customDio, required this.secureStorage, this.connectivityMonitor})
      : dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: ApiEndpoints.baseUrl,
                connectTimeout: const Duration(milliseconds: 3500),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _setupInterceptors();
    connectivityMonitor?.onServerUrlDiscovered = (discoveredUrl) {
      updateBaseUrl(discoveredUrl);
    };
  }

  void updateBaseUrl(String newBaseUrl) {
    dio.options.baseUrl = newBaseUrl;
    ApiEndpoints.setBaseUrl(newBaseUrl);
    secureStorage.saveBaseUrl(newBaseUrl);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      dio.get<T>(path, queryParameters: queryParameters, options: options);

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);

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
        onResponse: (response, handler) {
          // If a request succeeds, the server is definitively reachable and online
          connectivityMonitor?.markOnline();
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          // If connection timed out or host is unreachable, instantly mark offline
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.connectionError) {
            connectivityMonitor?.markOffline();
          }

          // Parse standardized backend error response
          final data = error.response?.data;
          String message = 'An unexpected error occurred. Please try again.';
          String? code;
          Map<String, dynamic>? errors;

          if (data is Map) {
            if (data['message'] != null) message = data['message'].toString();
            if (data['code'] != null) code = data['code'].toString();
            if (data['errors'] != null && data['errors'] is Map) {
              errors = Map<String, dynamic>.from(data['errors'] as Map);
            }
          }

          final apiException = ApiException(
            message: message,
            code: code,
            statusCode: error.response?.statusCode,
            errors: errors,
          );

          // Handle critical user identity & membership revocation signals
          if (error.response?.statusCode == 401 && code == 'USER_NOT_FOUND') {
            onUserNotFound?.call();
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: apiException,
                response: error.response,
                type: error.type,
              ),
            );
          }

          if (code == 'ACCOUNT_DISABLED') {
            onAccountDisabled?.call();
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: apiException,
                response: error.response,
                type: error.type,
              ),
            );
          }

          if (code == 'MEMBERSHIP_REMOVED') {
            final roomId = error.requestOptions.queryParameters['homeId']?.toString() ??
                error.requestOptions.queryParameters['roomId']?.toString() ?? '';
            onMembershipRemoved?.call(roomId);
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: apiException,
                response: error.response,
                type: error.type,
              ),
            );
          }

          // If 401 Unauthorized (and not USER_NOT_FOUND / auth endpoint): attempt refresh once
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

  Completer<bool>? _refreshCompleter;

  Future<bool> tryRefreshToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    _refreshCompleter = Completer<bool>();
    try {
      final result = await _executeRefreshToken();
      _refreshCompleter!.complete(result);
      return result;
    } catch (e) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<bool> _executeRefreshToken() async {
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
