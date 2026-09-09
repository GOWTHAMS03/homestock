import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getAllProducts();
});

final productCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getCategories();
});

/// Repository for managing and querying the master product catalog.
class ProductRepository {
  final AssetBundle? _assetBundle;
  List<Product>? _cachedProducts;
  Map<String, Product>? _idIndex;
  Map<String, List<Product>>? _categoryIndex;
  List<String>? _cachedCategories;

  ProductRepository({
    AssetBundle? assetBundle,
    List<Product>? preloadProducts,
  }) : _assetBundle = assetBundle {
    if (preloadProducts != null) {
      _initIndices(preloadProducts);
    }
  }

  AssetBundle get _bundle => _assetBundle ?? rootBundle;

  /// Synchronous access if catalog is already loaded
  List<Product>? get productsSync => _cachedProducts;

  void _initIndices(List<Product> products) {
    _cachedProducts = products;
    _idIndex = {for (final p in products) p.id: p};
    final catMap = <String, List<Product>>{};
    for (final p in products) {
      catMap.putIfAbsent(p.category, () => []).add(p);
    }
    _categoryIndex = catMap;
    final cats = catMap.keys.toList()..sort();
    _cachedCategories = cats;
  }

  /// Loads all products from assets/data/products.json or returns cached list
  Future<List<Product>> getAllProducts() async {
    if (_cachedProducts != null) {
      return _cachedProducts!;
    }
    final jsonStr = await _bundle.loadString('assets/data/products.json');
    final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
    final products = list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
    _initIndices(products);
    return products;
  }

  /// Get product by unique snake_case slug ID
  Future<Product?> getProductById(String id) async {
    if (_idIndex == null) {
      await getAllProducts();
    }
    return _idIndex?[id];
  }

  /// Get all products belonging to a specific category
  Future<List<Product>> getProductsByCategory(String category) async {
    if (_categoryIndex == null) {
      await getAllProducts();
    }
    return _categoryIndex?[category] ?? [];
  }

  /// Get list of all distinct product categories sorted alphabetically
  Future<List<String>> getCategories() async {
    if (_cachedCategories == null) {
      await getAllProducts();
    }
    return _cachedCategories ?? [];
  }

  /// Search products with support for English & Tamil script matching,
  /// token matching, brand, alias, and category search.
  Future<List<Product>> searchProducts(String query) async {
    final products = await getAllProducts();
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return products;
    }

    final lowerQuery = cleanQuery.toLowerCase();
    final tokens = lowerQuery
        .split(RegExp(r'[\s/,\-\(\)]+'))
        .where((t) => t.length > 1)
        .toList();

    // Scoring mechanism for relevance ranking
    final scoredList = <MapEntry<Product, int>>[];

    for (final p in products) {
      int score = 0;
      final nameLower = p.name.toLowerCase();
      final tamilName = p.tamilName ?? '';

      // Exact matches (Highest Priority)
      if (nameLower == lowerQuery) {
        score += 100;
      } else if (nameLower.startsWith(lowerQuery)) {
        score += 60;
      } else if (nameLower.contains(lowerQuery)) {
        score += 40;
      }

      // Tamil script match
      if (tamilName.isNotEmpty) {
        if (tamilName == cleanQuery) {
          score += 100;
        } else if (tamilName.startsWith(cleanQuery)) {
          score += 60;
        } else if (tamilName.contains(cleanQuery)) {
          score += 40;
        }
      }

      // Common names / Aliases
      for (final alias in p.commonNames) {
        final aLower = alias.toLowerCase();
        if (aLower == lowerQuery) {
          score += 50;
        } else if (aLower.contains(lowerQuery)) {
          score += 25;
        }
      }
      for (final alias in p.aliases) {
        final aLower = alias.toLowerCase();
        if (aLower == lowerQuery) {
          score += 50;
        } else if (aLower.contains(lowerQuery)) {
          score += 25;
        }
      }

      // Brands match
      for (final brand in p.brands) {
        final bLower = brand.toLowerCase();
        if (bLower == lowerQuery) {
          score += 40;
        } else if (bLower.contains(lowerQuery)) {
          score += 20;
        }
      }

      // Category / Subcategory match
      if (p.category.toLowerCase().contains(lowerQuery)) {
        score += 15;
      }
      if (p.subCategory != null &&
          p.subCategory!.toLowerCase().contains(lowerQuery)) {
        score += 15;
      }

      // Multi-token match if score is still low and tokens > 1
      if (tokens.length > 1) {
        int tokenMatches = 0;
        for (final token in tokens) {
          if (nameLower.contains(token) ||
              tamilName.contains(token) ||
              p.aliases.any((a) => a.toLowerCase().contains(token)) ||
              p.commonNames.any((c) => c.toLowerCase().contains(token)) ||
              p.brands.any((b) => b.toLowerCase().contains(token))) {
            tokenMatches++;
          }
        }
        if (tokenMatches == tokens.length) {
          score += 30;
        } else if (tokenMatches > 0) {
          score += tokenMatches * 5;
        }
      }

      if (score > 0) {
        scoredList.add(MapEntry(p, score));
      }
    }

    // Sort descending by score
    scoredList.sort((a, b) => b.value.compareTo(a.value));
    return scoredList.map((e) => e.key).toList();
  }
}

