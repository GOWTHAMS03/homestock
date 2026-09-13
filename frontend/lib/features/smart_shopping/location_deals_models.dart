// Data models for Location-Aware Smart Deals & Nearby Shop Intelligence.

class NearbyShop {
  final String id;
  final String name;
  final String shopType;
  final String address;
  final String area;
  final String city;
  final String postalCode;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final String distanceLabel;
  final double rating;
  final int reviewCount;
  final String openingHours;
  final bool isOpen;
  final bool isVerified;
  final int availableDealsCount;
  final double? estimatedBasketTotal;

  const NearbyShop({
    required this.id,
    required this.name,
    required this.shopType,
    required this.address,
    required this.area,
    required this.city,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.distanceLabel,
    required this.rating,
    required this.reviewCount,
    required this.openingHours,
    required this.isOpen,
    required this.isVerified,
    required this.availableDealsCount,
    this.estimatedBasketTotal,
  });

  factory NearbyShop.fromJson(Map<String, dynamic> json) {
    return NearbyShop(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Nearby Store',
      shopType: json['shopType'] as String? ?? 'SUPERMARKET',
      address: json['address'] as String? ?? '',
      area: json['area'] as String? ?? '',
      city: json['city'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      distanceLabel: json['distanceLabel'] as String? ?? 'Nearby',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.2,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      openingHours: json['openingHours'] as String? ?? '8:00 AM - 10:00 PM',
      isOpen: json['isOpen'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? true,
      availableDealsCount: (json['availableDealsCount'] as num?)?.toInt() ?? 0,
      estimatedBasketTotal: (json['estimatedBasketTotal'] as num?)?.toDouble(),
    );
  }
}

class ShopDeal {
  final String id;
  final String shopId;
  final String shopName;
  final String shopType;
  final double distanceKm;
  final String? distanceLabel;
  final String? productId;
  final String productName;
  final String? rawProductName;
  final String? brand;
  final double? packageSize;
  final String? unit;
  final double price;
  final double? mrp;
  final double effectivePrice;
  final double? pricePerUnit;
  final String? pricePerUnitLabel;
  final String stockStatus;
  final String source;
  final String confidence;
  final String freshnessStatus;
  final String freshnessLabel;
  final bool isAvailable;
  final double? userPreviousPrice;
  final String? priceComparisonNote;

  const ShopDeal({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.shopType,
    required this.distanceKm,
    this.distanceLabel,
    this.productId,
    required this.productName,
    this.rawProductName,
    this.brand,
    this.packageSize,
    this.unit,
    required this.price,
    this.mrp,
    required this.effectivePrice,
    this.pricePerUnit,
    this.pricePerUnitLabel,
    required this.stockStatus,
    required this.source,
    required this.confidence,
    required this.freshnessStatus,
    required this.freshnessLabel,
    required this.isAvailable,
    this.userPreviousPrice,
    this.priceComparisonNote,
  });

  factory ShopDeal.fromJson(Map<String, dynamic> json) {
    return ShopDeal(
      id: json['id'] as String? ?? '',
      shopId: json['shopId'] as String? ?? '',
      shopName: json['shopName'] as String? ?? 'Local Store',
      shopType: json['shopType'] as String? ?? 'SUPERMARKET',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      distanceLabel: json['distanceLabel'] as String?,
      productId: json['productId'] as String?,
      productName: json['productName'] as String? ?? '',
      rawProductName: json['rawProductName'] as String?,
      brand: json['brand'] as String?,
      packageSize: (json['packageSize'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      mrp: (json['mrp'] as num?)?.toDouble(),
      effectivePrice: (json['effectivePrice'] as num?)?.toDouble() ?? 0.0,
      pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble(),
      pricePerUnitLabel: json['pricePerUnitLabel'] as String?,
      stockStatus: json['stockStatus'] as String? ?? 'IN_STOCK',
      source: json['source'] as String? ?? 'SHOP_CATALOG',
      confidence: json['confidence'] as String? ?? 'HIGH',
      freshnessStatus: json['freshnessStatus'] as String? ?? 'LIVE',
      freshnessLabel: json['freshnessLabel'] as String? ?? 'Verified',
      isAvailable: json['isAvailable'] as bool? ?? true,
      userPreviousPrice: (json['userPreviousPrice'] as num?)?.toDouble(),
      priceComparisonNote: json['priceComparisonNote'] as String?,
    );
  }
}

class AreaSearchResult {
  final String area;
  final String city;
  final String state;
  final String postalCode;
  final double latitude;
  final double longitude;
  final String displayName;

  const AreaSearchResult({
    required this.area,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });

  factory AreaSearchResult.fromJson(Map<String, dynamic> json) {
    return AreaSearchResult(
      area: json['area'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? 'Tamil Nadu',
      postalCode: json['postalCode'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      displayName: json['displayName'] as String? ?? '',
    );
  }
}

class BasketOptimizationResult {
  final int totalItems;
  final int availableItems;
  final BasketOption? bestSingleStoreOption;
  final BasketOption? maximumSavingsOption;
  final String tradeOffExplanation;
  final String geminiAiRecommendation;
  final List<ItemDealComparison> itemComparisons;

  const BasketOptimizationResult({
    required this.totalItems,
    required this.availableItems,
    this.bestSingleStoreOption,
    this.maximumSavingsOption,
    required this.tradeOffExplanation,
    required this.geminiAiRecommendation,
    required this.itemComparisons,
  });

  factory BasketOptimizationResult.fromJson(Map<String, dynamic> json) {
    return BasketOptimizationResult(
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      availableItems: (json['availableItems'] as num?)?.toInt() ?? 0,
      bestSingleStoreOption: json['bestSingleStoreOption'] != null
          ? BasketOption.fromJson(json['bestSingleStoreOption'] as Map<String, dynamic>)
          : null,
      maximumSavingsOption: json['maximumSavingsOption'] != null
          ? BasketOption.fromJson(json['maximumSavingsOption'] as Map<String, dynamic>)
          : null,
      tradeOffExplanation: json['tradeOffExplanation'] as String? ?? '',
      geminiAiRecommendation: json['geminiAiRecommendation'] as String? ?? '',
      itemComparisons: (json['itemComparisons'] as List<dynamic>?)
              ?.map((e) => ItemDealComparison.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class BasketOption {
  final String optionType;
  final String title;
  final String subtitle;
  final List<String> storeNames;
  final int storeCount;
  final double basketItemsTotal;
  final double estimatedDeliveryOrTravelCost;
  final double effectiveGrandTotal;
  final double potentialSavings;
  final double totalTravelDistanceKm;
  final List<BasketItemAssignment> assignments;

  const BasketOption({
    required this.optionType,
    required this.title,
    required this.subtitle,
    required this.storeNames,
    required this.storeCount,
    required this.basketItemsTotal,
    required this.estimatedDeliveryOrTravelCost,
    required this.effectiveGrandTotal,
    required this.potentialSavings,
    required this.totalTravelDistanceKm,
    required this.assignments,
  });

  factory BasketOption.fromJson(Map<String, dynamic> json) {
    return BasketOption(
      optionType: json['optionType'] as String? ?? 'SINGLE_STORE',
      title: json['title'] as String? ?? 'Best Option',
      subtitle: json['subtitle'] as String? ?? '',
      storeNames: (json['storeNames'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      storeCount: (json['storeCount'] as num?)?.toInt() ?? 1,
      basketItemsTotal: (json['basketItemsTotal'] as num?)?.toDouble() ?? 0.0,
      estimatedDeliveryOrTravelCost: (json['estimatedDeliveryOrTravelCost'] as num?)?.toDouble() ?? 0.0,
      effectiveGrandTotal: (json['effectiveGrandTotal'] as num?)?.toDouble() ?? 0.0,
      potentialSavings: (json['potentialSavings'] as num?)?.toDouble() ?? 0.0,
      totalTravelDistanceKm: (json['totalTravelDistanceKm'] as num?)?.toDouble() ?? 0.0,
      assignments: (json['assignments'] as List<dynamic>?)
              ?.map((e) => BasketItemAssignment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class BasketItemAssignment {
  final String itemName;
  final String storeName;
  final String storeType;
  final double quantity;
  final String unit;
  final double price;
  final double? unitPrice;
  final String? unitPriceLabel;
  final String availability;

  const BasketItemAssignment({
    required this.itemName,
    required this.storeName,
    required this.storeType,
    required this.quantity,
    required this.unit,
    required this.price,
    this.unitPrice,
    this.unitPriceLabel,
    required this.availability,
  });

  factory BasketItemAssignment.fromJson(Map<String, dynamic> json) {
    return BasketItemAssignment(
      itemName: json['itemName'] as String? ?? '',
      storeName: json['storeName'] as String? ?? '',
      storeType: json['storeType'] as String? ?? 'LOCAL_SHOP',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] as String? ?? 'pcs',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      unitPriceLabel: json['unitPriceLabel'] as String?,
      availability: json['availability'] as String? ?? 'IN_STOCK',
    );
  }
}

class ItemDealComparison {
  final String itemName;
  final double requestedQuantity;
  final String requestedUnit;
  final ShopDeal? bestNearbyDeal;
  final List<OnlineDealOffer> onlineOffers;
  final List<ShopDeal> alternativeLocalDeals;
  final String? billHistoryBenchmark;

  const ItemDealComparison({
    required this.itemName,
    required this.requestedQuantity,
    required this.requestedUnit,
    this.bestNearbyDeal,
    required this.onlineOffers,
    required this.alternativeLocalDeals,
    this.billHistoryBenchmark,
  });

  factory ItemDealComparison.fromJson(Map<String, dynamic> json) {
    return ItemDealComparison(
      itemName: json['itemName'] as String? ?? '',
      requestedQuantity: (json['requestedQuantity'] as num?)?.toDouble() ?? 1.0,
      requestedUnit: json['requestedUnit'] as String? ?? 'pcs',
      bestNearbyDeal: json['bestNearbyDeal'] != null
          ? ShopDeal.fromJson(json['bestNearbyDeal'] as Map<String, dynamic>)
          : null,
      onlineOffers: (json['onlineOffers'] as List<dynamic>?)
              ?.map((e) => OnlineDealOffer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      alternativeLocalDeals: (json['alternativeLocalDeals'] as List<dynamic>?)
              ?.map((e) => ShopDeal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      billHistoryBenchmark: json['billHistoryBenchmark'] as String?,
    );
  }
}

class OnlineDealOffer {
  final String provider;
  final String title;
  final double price;
  final double deliveryCharge;
  final double effectivePrice;
  final double? pricePerUnit;
  final String? pricePerUnitLabel;
  final String? productUrl;
  final String stockStatus;
  final String estimatedDelivery;

  const OnlineDealOffer({
    required this.provider,
    required this.title,
    required this.price,
    required this.deliveryCharge,
    required this.effectivePrice,
    this.pricePerUnit,
    this.pricePerUnitLabel,
    this.productUrl,
    required this.stockStatus,
    required this.estimatedDelivery,
  });

  factory OnlineDealOffer.fromJson(Map<String, dynamic> json) {
    return OnlineDealOffer(
      provider: json['provider'] as String? ?? 'Online',
      title: json['title'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      deliveryCharge: (json['deliveryCharge'] as num?)?.toDouble() ?? 0.0,
      effectivePrice: (json['effectivePrice'] as num?)?.toDouble() ?? 0.0,
      pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble(),
      pricePerUnitLabel: json['pricePerUnitLabel'] as String?,
      productUrl: json['productUrl'] as String?,
      stockStatus: json['stockStatus'] as String? ?? 'IN_STOCK',
      estimatedDelivery: json['estimatedDelivery'] as String? ?? '',
    );
  }
}

class VoiceDealResult {
  final String transcript;
  final String detectedLanguage;
  final String intent;
  final String? parsedProduct;
  final double? parsedQuantity;
  final String? parsedUnit;
  final String conversationalReply;
  final ShopDeal? bestNearbyDeal;
  final List<ShopDeal> otherDeals;

  const VoiceDealResult({
    required this.transcript,
    required this.detectedLanguage,
    required this.intent,
    this.parsedProduct,
    this.parsedQuantity,
    this.parsedUnit,
    required this.conversationalReply,
    this.bestNearbyDeal,
    required this.otherDeals,
  });

  factory VoiceDealResult.fromJson(Map<String, dynamic> json) {
    return VoiceDealResult(
      transcript: json['transcript'] as String? ?? '',
      detectedLanguage: json['detectedLanguage'] as String? ?? 'MIXED',
      intent: json['intent'] as String? ?? 'SEARCH_DEAL',
      parsedProduct: json['parsedProduct'] as String?,
      parsedQuantity: (json['parsedQuantity'] as num?)?.toDouble(),
      parsedUnit: json['parsedUnit'] as String?,
      conversationalReply: json['conversationalReply'] as String? ?? '',
      bestNearbyDeal: json['bestNearbyDeal'] != null
          ? ShopDeal.fromJson(json['bestNearbyDeal'] as Map<String, dynamic>)
          : null,
      otherDeals: (json['otherDeals'] as List<dynamic>?)
              ?.map((e) => ShopDeal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
