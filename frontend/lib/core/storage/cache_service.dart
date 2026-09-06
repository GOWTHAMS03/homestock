import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/dashboard/dashboard_model.dart';
import '../../features/inventory/category_model.dart';
import '../../features/inventory/inventory_model.dart';
import '../../features/purchase/purchase_model.dart';
import '../../features/shopping/shopping_model.dart';

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

  // --- Typed Household Offline Cache Helpers ---

  // Dashboard
  Future<void> cacheDashboard(String homeId, DashboardSummaryModel summary) async {
    await set('dashboard_$homeId', jsonEncode(summary.toJson()));
  }

  DashboardSummaryModel? getCachedDashboard(String homeId) {
    try {
      final data = get('dashboard_$homeId');
      if (data is String && data.isNotEmpty) {
        return DashboardSummaryModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<void> cacheRecommendations(String homeId, WhatDoINeedModel recs) async {
    await set('recommendations_$homeId', jsonEncode(recs.toJson()));
  }

  WhatDoINeedModel? getCachedRecommendations(String homeId) {
    try {
      final data = get('recommendations_$homeId');
      if (data is String && data.isNotEmpty) {
        return WhatDoINeedModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  // Inventory
  Future<void> cacheInventory(String homeId, List<InventoryItemModel> items) async {
    await set('inventory_$homeId', jsonEncode(items.map((i) => i.toJson()).toList()));
  }

  List<InventoryItemModel>? getCachedInventory(String homeId) {
    try {
      final data = get('inventory_$homeId');
      if (data is String && data.isNotEmpty) {
        final list = jsonDecode(data) as List;
        return list.map((i) => InventoryItemModel.fromJson(i as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return null;
  }

  // Categories
  Future<void> cacheCategories(String homeId, List<CategoryModel> categories) async {
    await set('categories_$homeId', jsonEncode(categories.map((c) => c.toJson()).toList()));
  }

  List<CategoryModel>? getCachedCategories(String homeId) {
    try {
      final data = get('categories_$homeId');
      if (data is String && data.isNotEmpty) {
        final list = jsonDecode(data) as List;
        return list.map((c) => CategoryModel.fromJson(c as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return null;
  }

  // Shopping List
  Future<void> cacheShoppingList(String homeId, ShoppingListModel list) async {
    await set('shopping_$homeId', jsonEncode(list.toJson()));
  }

  ShoppingListModel? getCachedShoppingList(String homeId) {
    try {
      final data = get('shopping_$homeId');
      if (data is String && data.isNotEmpty) {
        return ShoppingListModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  // Purchases
  Future<void> cachePurchases(String homeId, List<PurchaseModel> purchases) async {
    await set('purchases_$homeId', jsonEncode(purchases.map((p) => p.toJson()).toList()));
  }

  List<PurchaseModel>? getCachedPurchases(String homeId) {
    try {
      final data = get('purchases_$homeId');
      if (data is String && data.isNotEmpty) {
        final list = jsonDecode(data) as List;
        return list.map((p) => PurchaseModel.fromJson(p as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return null;
  }

  Future<void> cacheStores(String homeId, List<StoreModel> stores) async {
    await set('stores_$homeId', jsonEncode(stores.map((s) => s.toJson()).toList()));
  }

  List<StoreModel>? getCachedStores(String homeId) {
    try {
      final data = get('stores_$homeId');
      if (data is String && data.isNotEmpty) {
        final list = jsonDecode(data) as List;
        return list.map((s) => StoreModel.fromJson(s as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return null;
  }
}
