import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/auth_state.dart';
import '../../features/home_switcher/home_model.dart';
import 'cache_service.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;
  final CacheService? _cache;

  SecureStorageService({FlutterSecureStorage? storage, CacheService? cacheService})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ),
        _cache = cacheService;

  String? _memoryAccessToken;
  String? _memoryRefreshToken;

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyActiveHomeId = 'active_home_id';
  static const _keyBaseUrl = 'api_base_url';
  static const _keyUser = 'user_profile_json';
  static const _keyHomes = 'homes_json';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _memoryAccessToken = accessToken;
    _memoryRefreshToken = refreshToken;
    try {
      await _storage.write(key: _keyAccessToken, value: accessToken);
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    } catch (_) {}
    // Remove from unencrypted Hive cache if previously present (CWE-312 prevention)
    await _cache?.remove(_keyAccessToken);
    await _cache?.remove(_keyRefreshToken);
  }

  Future<String?> getAccessToken() async {
    if (_memoryAccessToken != null && _memoryAccessToken!.isNotEmpty) return _memoryAccessToken;
    try {
      final token = await _storage.read(key: _keyAccessToken);
      if (token != null && token.isNotEmpty) {
        _memoryAccessToken = token;
        return token;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> getRefreshToken() async {
    if (_memoryRefreshToken != null && _memoryRefreshToken!.isNotEmpty) return _memoryRefreshToken;
    try {
      final token = await _storage.read(key: _keyRefreshToken);
      if (token != null && token.isNotEmpty) {
        _memoryRefreshToken = token;
        return token;
      }
    } catch (_) {}
    return null;
  }

  bool hasCachedTokensSync() {
    return (_memoryAccessToken != null && _memoryAccessToken!.isNotEmpty) ||
        (_memoryRefreshToken != null && _memoryRefreshToken!.isNotEmpty);
  }

  Future<void> saveUser(UserProfile user) async {
    final jsonStr = jsonEncode(user.toJson());
    try {
      await _storage.write(key: _keyUser, value: jsonStr);
    } catch (_) {}
    await _cache?.set(_keyUser, jsonStr);
  }

  UserProfile? getCachedUserSync() {
    try {
      final cached = _cache?.get(_keyUser);
      if (cached is String && cached.isNotEmpty) {
        return UserProfile.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<UserProfile?> getUser() async {
    final cachedUser = getCachedUserSync();
    if (cachedUser != null) return cachedUser;

    try {
      final jsonStr = await _storage.read(key: _keyUser);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        await _cache?.set(_keyUser, jsonStr);
        return UserProfile.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveActiveHomeId(String homeId) async {
    try {
      await _storage.write(key: _keyActiveHomeId, value: homeId);
    } catch (_) {}
    await _cache?.set(_keyActiveHomeId, homeId);
  }

  Future<String?> getActiveHomeId() async {
    final cached = _cache?.get(_keyActiveHomeId);
    if (cached is String && cached.isNotEmpty) return cached;
    try {
      final id = await _storage.read(key: _keyActiveHomeId);
      if (id != null && id.isNotEmpty) {
        await _cache?.set(_keyActiveHomeId, id);
        return id;
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveHomes(List<HomeModel> homes) async {
    final jsonStr = jsonEncode(homes.map((h) => h.toJson()).toList());
    try {
      await _storage.write(key: _keyHomes, value: jsonStr);
    } catch (_) {}
    await _cache?.set(_keyHomes, jsonStr);
  }

  List<HomeModel>? getCachedHomesSync() {
    try {
      final cached = _cache?.get(_keyHomes);
      if (cached is String && cached.isNotEmpty) {
        final list = jsonDecode(cached) as List;
        return list.map((item) => HomeModel.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveBaseUrl(String url) async {
    try {
      await _storage.write(key: _keyBaseUrl, value: url);
    } catch (_) {}
    await _cache?.set(_keyBaseUrl, url);
  }

  Future<String?> getBaseUrl() async {
    final cached = _cache?.get(_keyBaseUrl);
    if (cached is String && cached.isNotEmpty) return cached;
    try {
      final url = await _storage.read(key: _keyBaseUrl);
      if (url != null && url.isNotEmpty) {
        await _cache?.set(_keyBaseUrl, url);
        return url;
      }
    } catch (_) {}
    return null;
  }

  Future<void> clearAll() async {
    _memoryAccessToken = null;
    _memoryRefreshToken = null;
    final savedUrl = await getBaseUrl();
    try {
      await _storage.deleteAll();
    } catch (_) {}
    await _cache?.clear();
    if (savedUrl != null && savedUrl.isNotEmpty) {
      await saveBaseUrl(savedUrl);
    }
  }
}
