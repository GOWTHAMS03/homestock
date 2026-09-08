import 'dart:math' as math;
import '../../../../core/voice/vocabulary/grocery_vocabulary.dart';
import '../../models/voice_models.dart' show DisambiguationOption;

/// Candidate product from local DB or catalog
class ProductCandidate {
  final String id;
  final String name;
  final String category;
  final String unit;
  final String source; // 'INVENTORY', 'SHOPPING', 'CATALOG', 'VOCABULARY'

  const ProductCandidate({
    required this.id,
    required this.name,
    this.category = 'General',
    this.unit = 'pcs',
    this.source = 'VOCABULARY',
  });
}

/// Outcome of resolving a raw product query
class ProductResolutionResult {
  final String? resolvedId;
  final String resolvedName;
  final String category;
  final String defaultUnit;
  final double confidence;
  final bool isAmbiguous;
  final List<DisambiguationOption> disambiguationOptions;

  const ProductResolutionResult({
    this.resolvedId,
    required this.resolvedName,
    required this.category,
    required this.defaultUnit,
    this.confidence = 1.0,
    this.isAmbiguous = false,
    this.disambiguationOptions = const [],
  });

  factory ProductResolutionResult.exact({
    String? id,
    required String name,
    required String category,
    required String unit,
    double confidence = 1.0,
  }) {
    return ProductResolutionResult(
      resolvedId: id,
      resolvedName: name,
      category: category,
      defaultUnit: unit,
      confidence: confidence,
    );
  }

  factory ProductResolutionResult.ambiguous({
    required String query,
    required List<ProductCandidate> candidates,
  }) {
    return ProductResolutionResult(
      resolvedId: candidates.first.id,
      resolvedName: candidates.first.name,
      category: candidates.first.category,
      defaultUnit: candidates.first.unit,
      confidence: 0.70,
      isAmbiguous: true,
      disambiguationOptions: candidates.map((c) {
        return DisambiguationOption(
          id: c.id,
          label: c.name,
          subLabel: '${c.category} • ${c.unit}',
          action: 'SELECT_PRODUCT',
        );
      }).toList(),
    );
  }
}

/// Resolves raw product query strings into canonical HomeStock products
class ProductResolver {
  /// Resolves [query] using user inventory context and vocabulary catalog
  static ProductResolutionResult resolve(
    String rawQuery, {
    List<ProductCandidate> userInventory = const [],
    List<ProductCandidate> userShoppingList = const [],
  }) {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return const ProductResolutionResult(
        resolvedName: 'Item',
        category: 'General',
        defaultUnit: 'pcs',
        confidence: 0.5,
      );
    }

    final lowerQuery = query.toLowerCase();

    // 1. Look up in GroceryVocabulary dictionary
    final vocabDef = GroceryVocabulary.findMatch(lowerQuery);
    final vocabName = vocabDef?.canonicalName;

    // 2. Check User Inventory for exact match
    for (final item in userInventory) {
      if (item.name.toLowerCase() == lowerQuery ||
          (vocabName != null && item.name.toLowerCase() == vocabName.toLowerCase())) {
        return ProductResolutionResult.exact(
          id: item.id,
          name: item.name,
          category: item.category,
          unit: item.unit,
          confidence: 1.0,
        );
      }
    }

    // 3. Check User Shopping List for exact match
    for (final item in userShoppingList) {
      if (item.name.toLowerCase() == lowerQuery ||
          (vocabName != null && item.name.toLowerCase() == vocabName.toLowerCase())) {
        return ProductResolutionResult.exact(
          id: item.id,
          name: item.name,
          category: item.category,
          unit: item.unit,
          confidence: 0.98,
        );
      }
    }

    // 4. Check for multiple matching items in inventory (Ambiguity Detection)
    // E.g. User has "Basmati Rice" and "Brown Rice" and query is "rice"
    final matchingInventory = <ProductCandidate>[];
    for (final item in userInventory) {
      final itemLower = item.name.toLowerCase();
      if (itemLower.contains(lowerQuery) || (vocabName != null && itemLower.contains(vocabName.toLowerCase()))) {
        matchingInventory.add(item);
      }
    }

    if (matchingInventory.length > 1) {
      // Ambiguous! Return options to let user pick
      return ProductResolutionResult.ambiguous(
        query: query,
        candidates: matchingInventory,
      );
    } else if (matchingInventory.length == 1) {
      // Exactly one matching item in inventory! Prefer it
      final item = matchingInventory.first;
      return ProductResolutionResult.exact(
        id: item.id,
        name: item.name,
        category: item.category,
        unit: item.unit,
        confidence: 0.95,
      );
    }

    // 5. If found in GroceryVocabulary, return canonical definition
    if (vocabDef != null) {
      return ProductResolutionResult.exact(
        name: vocabDef.canonicalName,
        category: vocabDef.category,
        unit: vocabDef.defaultUnit,
        confidence: 0.95,
      );
    }

    // 6. Fuzzy match across known catalog for ASR typos (e.g. 'rais' -> 'Rice', 'arisi' -> 'Rice')
    ProductCandidate? bestFuzzy;
    double bestScore = 0.0;

    for (final def in GroceryVocabulary.allCatalog) {
      for (final v in def.variations) {
        final score = _calculateJaroWinkler(lowerQuery, v.toLowerCase());
        if (score > bestScore && score >= 0.82) {
          bestScore = score;
          bestFuzzy = ProductCandidate(
            id: def.canonicalName,
            name: def.canonicalName,
            category: def.category,
            unit: def.defaultUnit,
          );
        }
      }
    }

    if (bestFuzzy != null) {
      return ProductResolutionResult.exact(
        name: bestFuzzy.name,
        category: bestFuzzy.category,
        unit: bestFuzzy.unit,
        confidence: bestScore,
      );
    }

    // 7. Fallback: Capitalized original query
    final capitalized = query.split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');

    return ProductResolutionResult.exact(
      name: capitalized,
      category: 'General',
      unit: 'pcs',
      confidence: 0.80,
    );
  }

  /// Computes Jaro-Winkler string similarity (0.0 to 1.0)
  static double _calculateJaroWinkler(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final matchWindow = (math.max(s1.length, s2.length) ~/ 2) - 1;
    final s1Matches = List<bool>.filled(s1.length, false);
    final s2Matches = List<bool>.filled(s2.length, false);

    int matches = 0;
    int transpositions = 0;

    for (int i = 0; i < s1.length; i++) {
      final start = math.max(0, i - matchWindow);
      final end = math.min(i + matchWindow + 1, s2.length);

      for (int j = start; j < end; j++) {
        if (s2Matches[j]) continue;
        if (s1[i] != s2[j]) continue;
        s1Matches[i] = true;
        s2Matches[j] = true;
        matches++;
        break;
      }
    }

    if (matches == 0) return 0.0;

    int k = 0;
    for (int i = 0; i < s1.length; i++) {
      if (!s1Matches[i]) continue;
      while (!s2Matches[k]) {
        k++;
      }
      if (s1[i] != s2[k]) transpositions++;
      k++;
    }

    final jaro = ((matches / s1.length) +
            (matches / s2.length) +
            ((matches - transpositions / 2) / matches)) /
        3.0;

    // Common prefix up to 4 chars
    int prefix = 0;
    for (int i = 0; i < math.min(4, math.min(s1.length, s2.length)); i++) {
      if (s1[i] == s2[i]) {
        prefix++;
      } else {
        break;
      }
    }

    return jaro + (prefix * 0.1 * (1.0 - jaro));
  }
}
