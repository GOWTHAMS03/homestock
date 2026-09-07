/// Models for the Smart Shopping price comparison feature.
/// These mirror the backend DTOs and are the only models Flutter uses
/// for product offers — no provider-specific logic reaches the UI.
library;

class ProductOfferModel {
  final String provider;
  final String providerProductId;
  final String productName;
  final String? brand;
  final String? description;
  final String? imageUrl;
  final String? productUrl;
  final String? affiliateUrl;
  final double price;
  final String currency;
  final double? deliveryCharge;
  final double effectivePrice;
  final String? availability;
  final String? estimatedDelivery;
  final String? packageSize;
  final String? unit;
  final double? rating;
  final int? reviewCount;
  final double? matchConfidence;
  final String? matchType; // EXACT, SIMILAR, NO_MATCH
  final double? pricePerUnit;
  final String? pricePerUnitLabel;
  final String? lastCheckedAt;
  final bool fromCache;

  const ProductOfferModel({
    required this.provider,
    required this.providerProductId,
    required this.productName,
    this.brand,
    this.description,
    this.imageUrl,
    this.productUrl,
    this.affiliateUrl,
    required this.price,
    this.currency = 'INR',
    this.deliveryCharge,
    required this.effectivePrice,
    this.availability,
    this.estimatedDelivery,
    this.packageSize,
    this.unit,
    this.rating,
    this.reviewCount,
    this.matchConfidence,
    this.matchType,
    this.pricePerUnit,
    this.pricePerUnitLabel,
    this.lastCheckedAt,
    this.fromCache = false,
  });

  factory ProductOfferModel.fromJson(Map<String, dynamic> json) {
    return ProductOfferModel(
      provider: json['provider'] ?? '',
      providerProductId: json['providerProductId'] ?? '',
      productName: json['productName'] ?? '',
      brand: json['brand'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      productUrl: json['productUrl'],
      affiliateUrl: json['affiliateUrl'],
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] ?? 'INR',
      deliveryCharge: (json['deliveryCharge'] as num?)?.toDouble(),
      effectivePrice: (json['effectivePrice'] as num?)?.toDouble() ?? 0,
      availability: json['availability'],
      estimatedDelivery: json['estimatedDelivery'],
      packageSize: json['packageSize'],
      unit: json['unit'],
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int?,
      matchConfidence: (json['matchConfidence'] as num?)?.toDouble(),
      matchType: json['matchType'],
      pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble(),
      pricePerUnitLabel: json['pricePerUnitLabel'],
      lastCheckedAt: json['lastCheckedAt'],
      fromCache: json['fromCache'] ?? false,
    );
  }

  /// Whether delivery is free
  bool get isFreeDelivery => deliveryCharge == null || deliveryCharge == 0;

  /// Display-friendly delivery text
  String get deliveryText {
    if (isFreeDelivery) return 'Free delivery';
    if (deliveryCharge != null) return '₹${deliveryCharge!.toStringAsFixed(0)} delivery';
    return 'Delivery charges may apply';
  }

  /// How long ago the price was checked
  String get freshnessLabel {
    if (lastCheckedAt == null) return '';
    try {
      final checked = DateTime.parse(lastCheckedAt!);
      final diff = DateTime.now().difference(checked);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}

class ShoppingItemSummary {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final String? brand;
  final String? categoryName;

  const ShoppingItemSummary({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.brand,
    this.categoryName,
  });

  factory ShoppingItemSummary.fromJson(Map<String, dynamic> json) {
    return ShoppingItemSummary(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1,
      unit: json['unit'] ?? 'pcs',
      brand: json['brand'],
      categoryName: json['categoryName'],
    );
  }
}

class ProviderStatusModel {
  final String provider;
  final String status; // SUCCESS, FAILED, TIMEOUT, DISABLED
  final String? message;
  final int offerCount;
  final int responseTimeMs;

  const ProviderStatusModel({
    required this.provider,
    required this.status,
    this.message,
    this.offerCount = 0,
    this.responseTimeMs = 0,
  });

  factory ProviderStatusModel.fromJson(Map<String, dynamic> json) {
    return ProviderStatusModel(
      provider: json['provider'] ?? '',
      status: json['status'] ?? 'FAILED',
      message: json['message'],
      offerCount: json['offerCount'] ?? 0,
      responseTimeMs: json['responseTimeMs'] ?? 0,
    );
  }

  bool get isSuccess => status == 'SUCCESS';
  bool get isFailed => status == 'FAILED';
  bool get isTimeout => status == 'TIMEOUT';
}

class LocalEstimateModel {
  final double? minPrice;
  final double? maxPrice;
  final double? averagePrice;
  final String? source;

  const LocalEstimateModel({
    this.minPrice,
    this.maxPrice,
    this.averagePrice,
    this.source,
  });

  factory LocalEstimateModel.fromJson(Map<String, dynamic> json) {
    return LocalEstimateModel(
      minPrice: (json['minPrice'] as num?)?.toDouble(),
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      averagePrice: (json['averagePrice'] as num?)?.toDouble(),
      source: json['source'],
    );
  }

  String get priceRangeLabel {
    if (minPrice != null && maxPrice != null) {
      return '₹${minPrice!.toStringAsFixed(0)}–₹${maxPrice!.toStringAsFixed(0)}';
    }
    if (averagePrice != null) {
      return '~₹${averagePrice!.toStringAsFixed(0)}';
    }
    return 'Price varies';
  }
}

class PriceComparisonResult {
  final ShoppingItemSummary shoppingItem;
  final List<ProductOfferModel> offers;
  final ProductOfferModel? bestOffer;
  final Map<String, ProviderStatusModel> providerStatuses;
  final LocalEstimateModel? localEstimate;
  final String? lastUpdated;

  const PriceComparisonResult({
    required this.shoppingItem,
    required this.offers,
    this.bestOffer,
    this.providerStatuses = const {},
    this.localEstimate,
    this.lastUpdated,
  });

  factory PriceComparisonResult.fromJson(Map<String, dynamic> json) {
    final rawOffers = json['offers'] as List? ?? [];
    final offers = rawOffers.map((o) => ProductOfferModel.fromJson(o)).toList();

    final rawStatuses = json['providerStatuses'] as Map<String, dynamic>? ?? {};
    final statuses = rawStatuses.map(
      (key, value) => MapEntry(key, ProviderStatusModel.fromJson(value as Map<String, dynamic>)),
    );

    return PriceComparisonResult(
      shoppingItem: ShoppingItemSummary.fromJson(json['shoppingItem'] ?? {}),
      offers: offers,
      bestOffer: json['bestOffer'] != null ? ProductOfferModel.fromJson(json['bestOffer']) : null,
      providerStatuses: statuses,
      localEstimate: json['localEstimate'] != null
          ? LocalEstimateModel.fromJson(json['localEstimate'])
          : null,
      lastUpdated: json['lastUpdated'],
    );
  }

  /// Number of providers that returned results successfully
  int get successfulProviderCount =>
      providerStatuses.values.where((s) => s.isSuccess).length;

  /// Number of providers that failed
  int get failedProviderCount =>
      providerStatuses.values.where((s) => s.isFailed || s.isTimeout).length;

  /// Whether there's a meaningful price difference between offers
  String? get savingsLabel {
    if (offers.length < 2) return null;
    final diff = offers.last.effectivePrice - offers.first.effectivePrice;
    if (diff < 2) return null;
    return '₹${diff.toStringAsFixed(0)} cheaper than the next option';
  }
}
