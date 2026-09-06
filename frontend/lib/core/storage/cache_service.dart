import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

class CacheService {
  static const String _boxName = 'homestock_cache';
  Box? _box;

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox(_boxName);
    } catch (_) {}
  }

  Future<void> set(String key, dynamic value) async {
    try {
      await _box?.put(key, value);
    } catch (_) {}
  }

  dynamic get(String key) {
    try {
      return _box?.get(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) async {
    try {
      await _box?.delete(key);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      await _box?.clear();
    } catch (_) {}
  }
}
