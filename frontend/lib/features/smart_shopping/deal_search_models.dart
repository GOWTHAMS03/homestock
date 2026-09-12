/// Models for Real-World Product Deal Search in HomeStock.
/// Mirrors the backend ProductDealSearchResponse DTO structure.
library;

class ProductSearchIntent {
  final String rawQuery;
  final String normalizedQuery;
  final String searchMode; // GENERIC_DISCOVERY or EXACT_PRODUCT
  final String searchPriority; // BARCODE, EXACT_PRODUCT_NAME, BRAND_AND_TYPE, TYPE_AND_VARIANT, GENERIC_CATEGORY
  final String primaryCategory;
  final String? extractedVariant;
  final String? extractedBrand;
  final String? extractedPackSize;
  final String? extractedUnit;
  final String? targetBarcode;
  final List<String> allowedTypes;

  const ProductSearchIntent({
    required this.rawQuery,
    required this.normalizedQuery,
    required this.searchMode,
    required this.searchPriority,
    required this.primaryCategory,
    this.extractedVariant,
    this.extractedBrand,
    this.extractedPackSize,
    this.extractedUnit,
    this.targetBarcode,
    this.allowedTypes = const [],
  });

  bool get isExactMode => searchMode == 'EXACT_PRODUCT';

  factory ProductSearchIntent.fromJson(Map<String, dynamic> json) {
    return ProductSearchIntent(
      rawQuery: json['rawQuery'] as String? ?? '',
      normalizedQuery: json['normalizedQuery'] as String? ?? '',
      searchMode: json['searchMode'] as String? ?? 'GENERIC_DISCOVERY',
      searchPriority: json['searchPriority'] as String? ?? 'GENERIC_CATEGORY',
      primaryCategory: json['primaryCategory'] as String? ?? 'Grocery',
      extractedVariant: json['extractedVariant'] as String?,
      extractedBrand: json['extractedBrand'] as String?,
      extractedPackSize: json['extractedPackSize'] as String?,
      extractedUnit: json['extractedUnit'] as String?,
      targetBarcode: json['targetBarcode'] as String?,
      allowedTypes: (json['allowedTypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class StoreOffer {
  final String storeName;
  final double price;
  final double? mrp;
  final double? deliveryFee;
  final String? estimatedDelivery;
  final String availability;
  final String? productUrl;
  final String? canonicalProductUrl;
  final String? urlType;
  final bool urlVerified;
  final bool directProductUrlAvailable;
  final String? affiliateUrl;
  final String? deepLink;
  final double? rating;
  final int? reviewCount;
  final double? finalPrice;
  final String? validationStatus;
  final String? freshnessLabel;
  final bool isBestPrice;

  const StoreOffer({
    required this.storeName,
    required this.price,
    this.mrp,
    this.deliveryFee,
    this.estimatedDelivery,
    this.availability = 'IN_STOCK',
    this.productUrl,
    this.canonicalProductUrl,
    this.urlType,
    this.urlVerified = false,
    this.directProductUrlAvailable = true,
    this.affiliateUrl,
    this.deepLink,
    this.rating,
    this.reviewCount,
    this.finalPrice,
    this.validationStatus,
    this.freshnessLabel,
    this.isBestPrice = false,
  });

  factory StoreOffer.fromJson(Map<String, dynamic> json) {
    return StoreOffer(
      storeName: json['storeName'] as String? ?? 'Store',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      mrp: (json['mrp'] as num?)?.toDouble(),
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble(),
      estimatedDelivery: json['estimatedDelivery'] as String?,
      availability: json['availability'] as String? ?? 'IN_STOCK',
      productUrl: json['productUrl'] as String?,
      canonicalProductUrl: json['canonicalProductUrl'] as String?,
      urlType: json['urlType'] as String?,
      urlVerified: json['urlVerified'] as bool? ?? false,
      directProductUrlAvailable: json['directProductUrlAvailable'] as bool? ?? true,
      affiliateUrl: json['affiliateUrl'] as String?,
      deepLink: json['deepLink'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
      finalPrice: (json['finalPrice'] as num?)?.toDouble(),
      validationStatus: json['validationStatus'] as String?,
      freshnessLabel: json['freshnessLabel'] as String?,
      isBestPrice: json['isBestPrice'] as bool? ?? false,
    );
  }
}

class ProductDeal {
  final String id;
  final String productName;
  final String? brand;
  final String? variantType;
  final String? category;
  final String? packageSize;
  final String? unit;
  final double bestPrice;
  final double? mrp;
  final double? discountPercent;
  final String bestProvider;
  final double? unitPrice;
  final String? unitPriceLabel;
  final double? savingsVsHighest;
  final String? comparisonStore;
  final String? imageUrl;
  final String? productUrl;
  final String? canonicalProductUrl;
  final String? urlType;
  final bool urlVerified;
  final bool directProductUrlAvailable;
  final double? displayedPrice;
  final double? verifiedPrice;
  final String? priceVerifiedAt;
  final String? deepLink;
  final double? rating;
  final int? reviewCount;
  final bool isLowestPrice;
  final bool isBestValue;
  final bool isPopular;
  final bool isExactMatch;
  final double? matchConfidence;
  final double? confidenceScore;
  final String? confidenceLevel;
  final String? validationStatus;
  final String? freshnessLabel;
  final String? lastVerifiedAt;
  final double? finalPrice;
  final List<StoreOffer> storeOffers;

  const ProductDeal({
    required this.id,
    required this.productName,
    this.brand,
    this.variantType,
    this.category,
    this.packageSize,
    this.unit,
    required this.bestPrice,
    this.mrp,
    this.discountPercent,
    required this.bestProvider,
    this.unitPrice,
    this.unitPriceLabel,
    this.savingsVsHighest,
    this.comparisonStore,
    this.imageUrl,
    this.productUrl,
    this.canonicalProductUrl,
    this.urlType,
    this.urlVerified = false,
    this.directProductUrlAvailable = true,
    this.displayedPrice,
    this.verifiedPrice,
    this.priceVerifiedAt,
    this.deepLink,
    this.rating,
    this.reviewCount,
    this.isLowestPrice = false,
    this.isBestValue = false,
    this.isPopular = false,
    this.isExactMatch = false,
    this.matchConfidence,
    this.confidenceScore,
    this.confidenceLevel,
    this.validationStatus,
    this.freshnessLabel,
    this.lastVerifiedAt,
    this.finalPrice,
    this.storeOffers = const [],
  });

  bool get isValidated => validationStatus == null || validationStatus == 'VALID' || validationStatus == 'PRICE_CHANGED';
  bool get isStale => validationStatus == 'STALE';
  bool get isOutOfStock => validationStatus == 'OUT_OF_STOCK';

  factory ProductDeal.fromJson(Map<String, dynamic> json) {
    return ProductDeal(
      id: json['id'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      brand: json['brand'] as String?,
      variantType: json['variantType'] as String?,
      category: json['category'] as String?,
      packageSize: json['packageSize'] as String?,
      unit: json['unit'] as String?,
      bestPrice: (json['bestPrice'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble() ?? 0.0,
      mrp: (json['mrp'] as num?)?.toDouble(),
      discountPercent: (json['discountPercent'] as num?)?.toDouble(),
      bestProvider: json['bestProvider'] as String? ?? json['seller'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      unitPriceLabel: json['unitPriceLabel'] as String?,
      savingsVsHighest: (json['savingsVsHighest'] as num?)?.toDouble(),
      comparisonStore: json['comparisonStore'] as String?,
      imageUrl: json['imageUrl'] as String?,
      productUrl: json['productUrl'] as String?,
      canonicalProductUrl: json['canonicalProductUrl'] as String?,
      urlType: json['urlType'] as String?,
      urlVerified: json['urlVerified'] as bool? ?? false,
      directProductUrlAvailable: json['directProductUrlAvailable'] as bool? ?? true,
      displayedPrice: (json['displayedPrice'] as num?)?.toDouble(),
      verifiedPrice: (json['verifiedPrice'] as num?)?.toDouble(),
      priceVerifiedAt: json['priceVerifiedAt'] as String?,
      deepLink: json['deepLink'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
      isLowestPrice: json['lowestPrice'] as bool? ?? json['isLowestPrice'] as bool? ?? false,
      isBestValue: json['bestValue'] as bool? ?? json['isBestValue'] as bool? ?? false,
      isPopular: json['popular'] as bool? ?? json['isPopular'] as bool? ?? false,
      isExactMatch: json['exactMatch'] as bool? ?? json['isExactMatch'] as bool? ?? false,
      matchConfidence: (json['matchConfidence'] as num?)?.toDouble() ?? (json['identityConfidence'] as num?)?.toDouble(),
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble(),
      confidenceLevel: json['confidenceLevel'] as String?,
      validationStatus: json['validationStatus'] as String?,
      freshnessLabel: json['freshnessLabel'] as String?,
      lastVerifiedAt: json['lastVerifiedAt'] as String?,
      finalPrice: (json['finalPrice'] as num?)?.toDouble() ?? (json['bestFinalPrice'] as num?)?.toDouble(),
      storeOffers: (json['storeOffers'] as List<dynamic>?)
              ?.map((e) => StoreOffer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DealSummary {
  final int totalProducts;
  final double? priceRangeMin;
  final double? priceRangeMax;
  final double? lowestPrice;
  final double? bestUnitValue;
  final String? bestUnitValueLabel;
  final String aiRecommendation;

  const DealSummary({
    required this.totalProducts,
    this.priceRangeMin,
    this.priceRangeMax,
    this.lowestPrice,
    this.bestUnitValue,
    this.bestUnitValueLabel,
    required this.aiRecommendation,
  });

  factory DealSummary.fromJson(Map<String, dynamic> json) {
    return DealSummary(
      totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
      priceRangeMin: (json['priceRangeMin'] as num?)?.toDouble(),
      priceRangeMax: (json['priceRangeMax'] as num?)?.toDouble(),
      lowestPrice: (json['lowestPrice'] as num?)?.toDouble(),
      bestUnitValue: (json['bestUnitValue'] as num?)?.toDouble(),
      bestUnitValueLabel: json['bestUnitValueLabel'] as String?,
      aiRecommendation: json['aiRecommendation'] as String? ?? '',
    );
  }
}

class DealHighlights {
  final ProductDeal? lowestPrice;
  final ProductDeal? bestValue;
  final ProductDeal? popular;

  const DealHighlights({
    this.lowestPrice,
    this.bestValue,
    this.popular,
  });

  factory DealHighlights.fromJson(Map<String, dynamic> json) {
    return DealHighlights(
      lowestPrice: json['lowestPrice'] != null
          ? ProductDeal.fromJson(json['lowestPrice'] as Map<String, dynamic>)
          : null,
      bestValue: json['bestValue'] != null
          ? ProductDeal.fromJson(json['bestValue'] as Map<String, dynamic>)
          : null,
      popular: json['popular'] != null
          ? ProductDeal.fromJson(json['popular'] as Map<String, dynamic>)
          : null,
    );
  }
}

class FilterOption {
  final String key;
  final String label;
  final int count;

  const FilterOption({
    required this.key,
    required this.label,
    required this.count,
  });

  factory FilterOption.fromJson(Map<String, dynamic> json) {
    return FilterOption(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class DealFilters {
  final List<FilterOption> availableTypes;
  final List<FilterOption> availableBrands;
  final List<FilterOption> availablePackSizes;
  final List<FilterOption> availableStores;

  const DealFilters({
    this.availableTypes = const [],
    this.availableBrands = const [],
    this.availablePackSizes = const [],
    this.availableStores = const [],
  });

  factory DealFilters.fromJson(Map<String, dynamic> json) {
    return DealFilters(
      availableTypes: (json['availableTypes'] as List<dynamic>?)
              ?.map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      availableBrands: (json['availableBrands'] as List<dynamic>?)
              ?.map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      availablePackSizes: (json['availablePackSizes'] as List<dynamic>?)
              ?.map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      availableStores: (json['availableStores'] as List<dynamic>?)
              ?.map((e) => FilterOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ProductDealSearchResponse {
  final ProductSearchIntent intent;
  final DealSummary summary;
  final DealHighlights highlights;
  final List<ProductDeal> products;
  final DealFilters filters;

  const ProductDealSearchResponse({
    required this.intent,
    required this.summary,
    required this.highlights,
    required this.products,
    required this.filters,
  });

  factory ProductDealSearchResponse.fromJson(Map<String, dynamic> json) {
    return ProductDealSearchResponse(
      intent: ProductSearchIntent.fromJson(
          json['intent'] as Map<String, dynamic>? ?? {}),
      summary: DealSummary.fromJson(
          json['summary'] as Map<String, dynamic>? ?? {}),
      highlights: DealHighlights.fromJson(
          json['highlights'] as Map<String, dynamic>? ?? {}),
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => ProductDeal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      filters: DealFilters.fromJson(
          json['filters'] as Map<String, dynamic>? ?? {}),
    );
  }
}
