// Shop Owner & Local Commerce domain models

class ShopProfileModel {
  final String id;
  final String name;
  final String? ownerName;
  final String? ownerId;
  final String verificationStatus; // PENDING, VERIFIED, REJECTED, SUSPENDED
  final String shopType;
  final String address;
  final String area;
  final String city;
  final String? state;
  final String postalCode;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? email;
  final String? whatsappNumber;
  final String? openingTime;
  final String? closingTime;
  final String? shopImageUrl;
  final String? gstNumber;
  final String? category;
  final int confidenceScore;
  final bool isOpen;
  final bool isVerified;
  final bool active;
  final int productCount;
  final double? distanceKm;
  final int activeDealCount;
  final String? subscriptionPlan;
  final String? subscriptionStatus;
  final int maxProducts;
  final String? lastInventoryUpdate;
  final String? lastVerifiedAt;

  const ShopProfileModel({
    required this.id,
    required this.name,
    this.ownerName,
    this.ownerId,
    required this.verificationStatus,
    required this.shopType,
    required this.address,
    required this.area,
    required this.city,
    this.state,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.email,
    this.whatsappNumber,
    this.openingTime,
    this.closingTime,
    this.shopImageUrl,
    this.gstNumber,
    this.category,
    this.confidenceScore = 50,
    this.isOpen = true,
    this.isVerified = false,
    this.active = true,
    this.productCount = 0,
    this.distanceKm,
    this.activeDealCount = 0,
    this.subscriptionPlan = 'FREE',
    this.subscriptionStatus = 'ACTIVE',
    this.maxProducts = 50,
    this.lastInventoryUpdate,
    this.lastVerifiedAt,
  });

  bool get isPending => verificationStatus == 'PENDING';
  bool get isApproved => verificationStatus == 'VERIFIED';
  bool get isRejected => verificationStatus == 'REJECTED';
  bool get isSuspended => verificationStatus == 'SUSPENDED';

  factory ShopProfileModel.fromJson(Map<String, dynamic> json) {
    return ShopProfileModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      ownerName: json['ownerName'] as String?,
      ownerId: json['ownerId'] as String?,
      verificationStatus: json['verificationStatus'] as String? ?? 'PENDING',
      shopType: json['shopType'] as String? ?? 'GROCERY',
      address: json['address'] as String? ?? '',
      area: json['area'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String?,
      postalCode: json['postalCode'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      whatsappNumber: json['whatsappNumber'] as String?,
      openingTime: json['openingTime'] as String?,
      closingTime: json['closingTime'] as String?,
      shopImageUrl: json['shopImageUrl'] as String?,
      gstNumber: json['gstNumber'] as String?,
      category: json['category'] as String?,
      confidenceScore: json['confidenceScore'] as int? ?? 50,
      isOpen: json['isOpen'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
      productCount: json['productCount'] as int? ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      activeDealCount: (json['activeDealCount'] as num?)?.toInt() ?? 0,
      subscriptionPlan: json['subscriptionPlan'] as String? ?? 'FREE',
      subscriptionStatus: json['subscriptionStatus'] as String? ?? 'ACTIVE',
      maxProducts: json['maxProducts'] as int? ?? 50,
      lastInventoryUpdate: json['lastInventoryUpdate'] as String?,
      lastVerifiedAt: json['lastVerifiedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shopName': name,
      'ownerName': ownerName,
      'shopType': shopType,
      'address': address,
      'area': area,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'whatsappNumber': whatsappNumber,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'shopImageUrl': shopImageUrl,
      'gstNumber': gstNumber,
      'shopCategory': category,
    };
  }
}

class ShopProductModel {
  final String id;
  final String rawProductName;
  final String? brand;
  final String? packageSize;
  final String unit;
  final double price;
  final double? mrp;
  final double effectivePrice;
  final double? offerPrice;
  final String? offerStart;
  final String? offerEnd;
  final String availabilityStatus; // AVAILABLE, LIMITED, OUT_OF_STOCK
  final double? stockQuantity;
  final String stockVisibility; // STATUS_ONLY, QUANTITY
  final String stockStatus; // IN_STOCK, LOW_STOCK, OUT_OF_STOCK
  final bool hasActiveOffer;
  final double? distanceKm;
  final String? shopName;
  final String? shopId;

  const ShopProductModel({
    required this.id,
    required this.rawProductName,
    this.brand,
    this.packageSize,
    this.unit = 'pcs',
    required this.price,
    this.mrp,
    required this.effectivePrice,
    this.offerPrice,
    this.offerStart,
    this.offerEnd,
    this.availabilityStatus = 'AVAILABLE',
    this.stockQuantity,
    this.stockVisibility = 'STATUS_ONLY',
    this.stockStatus = 'IN_STOCK',
    this.hasActiveOffer = false,
    this.distanceKm,
    this.shopName,
    this.shopId,
  });

  bool get isOutOfStock => availabilityStatus == 'OUT_OF_STOCK' || stockStatus == 'OUT_OF_STOCK';
  bool get isLimited => availabilityStatus == 'LIMITED' || stockStatus == 'LOW_STOCK';

  factory ShopProductModel.fromJson(Map<String, dynamic> json) {
    return ShopProductModel(
      id: json['id'] as String? ?? '',
      rawProductName: json['rawProductName'] as String? ?? '',
      brand: json['brand'] as String?,
      packageSize: json['packageSize'] as String?,
      unit: json['unit'] as String? ?? 'pcs',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      mrp: (json['mrp'] as num?)?.toDouble(),
      effectivePrice: (json['effectivePrice'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble() ?? 0.0,
      offerPrice: (json['offerPrice'] as num?)?.toDouble(),
      offerStart: json['offerStart'] as String?,
      offerEnd: json['offerEnd'] as String?,
      availabilityStatus: json['availabilityStatus'] as String? ?? 'AVAILABLE',
      stockQuantity: (json['stockQuantity'] as num?)?.toDouble(),
      stockVisibility: json['stockVisibility'] as String? ?? 'STATUS_ONLY',
      stockStatus: json['stockStatus'] as String? ?? 'IN_STOCK',
      hasActiveOffer: json['hasActiveOffer'] as bool? ?? false,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      shopName: json['shopName'] as String?,
      shopId: json['shopId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productName': rawProductName,
      'brand': brand,
      'packageSize': packageSize,
      'unit': unit,
      'price': price,
      'mrp': mrp,
      'offerPrice': offerPrice,
      'offerStart': offerStart,
      'offerEnd': offerEnd,
      'availabilityStatus': availabilityStatus,
      'stockQuantity': stockQuantity,
      'stockVisibility': stockVisibility,
    };
  }
}

class ShopDealModel {
  final String id;
  final String? shopId;
  final String? shopProductId;
  final String? productName;
  final String title;
  final String? description;
  final String dealType;
  final double originalPrice;
  final double offerPrice;
  final int discountPercent;
  final String startDate;
  final String endDate;
  final bool isActive;

  const ShopDealModel({
    required this.id,
    this.shopId,
    this.shopProductId,
    this.productName,
    required this.title,
    this.description,
    this.dealType = 'DISCOUNT',
    required this.originalPrice,
    required this.offerPrice,
    required this.discountPercent,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });

  factory ShopDealModel.fromJson(Map<String, dynamic> json) {
    return ShopDealModel(
      id: json['id'] as String? ?? '',
      shopId: json['shopId'] as String?,
      shopProductId: json['shopProductId'] as String?,
      productName: json['productName'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      dealType: json['dealType'] as String? ?? 'DISCOUNT',
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0.0,
      offerPrice: (json['offerPrice'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shopProductId': shopProductId,
      'title': title,
      'description': description,
      'dealType': dealType,
      'originalPrice': originalPrice,
      'offerPrice': offerPrice,
      'discountPercent': discountPercent,
      'startDate': startDate,
      'endDate': endDate,
    };
  }
}

class ShopDashboardModel {
  final int todayViews;
  final int productViews;
  final int activeDeals;
  final int totalProducts;
  final String subscriptionPlan;
  final int maxProducts;
  final List<PopularProductItem> popularProducts;
  final List<DemandItem> nearbyDemand;
  final List<AttentionItem> productsNeedingAttention;

  const ShopDashboardModel({
    this.todayViews = 0,
    this.productViews = 0,
    this.activeDeals = 0,
    this.totalProducts = 0,
    this.subscriptionPlan = 'FREE',
    this.maxProducts = 50,
    this.popularProducts = const [],
    this.nearbyDemand = const [],
    this.productsNeedingAttention = const [],
  });

  factory ShopDashboardModel.fromJson(Map<String, dynamic> json) {
    return ShopDashboardModel(
      todayViews: (json['todayViews'] as num?)?.toInt() ?? 0,
      productViews: (json['productViews'] as num?)?.toInt() ?? 0,
      activeDeals: (json['activeDeals'] as num?)?.toInt() ?? 0,
      totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
      subscriptionPlan: json['subscriptionPlan'] as String? ?? 'FREE',
      maxProducts: (json['maxProducts'] as num?)?.toInt() ?? 50,
      popularProducts: (json['popularProducts'] as List<dynamic>?)
              ?.map((e) => PopularProductItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nearbyDemand: (json['nearbyDemand'] as List<dynamic>?)
              ?.map((e) => DemandItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      productsNeedingAttention: (json['productsNeedingAttention'] as List<dynamic>?)
              ?.map((e) => AttentionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PopularProductItem {
  final String productName;
  final int viewCount;

  const PopularProductItem({required this.productName, required this.viewCount});

  factory PopularProductItem.fromJson(Map<String, dynamic> json) {
    return PopularProductItem(
      productName: json['productName'] as String? ?? '',
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class DemandItem {
  final String searchTerm;
  final int searchCount;

  const DemandItem({required this.searchTerm, required this.searchCount});

  factory DemandItem.fromJson(Map<String, dynamic> json) {
    return DemandItem(
      searchTerm: json['searchTerm'] as String? ?? '',
      searchCount: (json['searchCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class AttentionItem {
  final String productId;
  final String productName;
  final String reason;
  final String severity; // WARNING, CRITICAL, INFO

  const AttentionItem({
    required this.productId,
    required this.productName,
    required this.reason,
    this.severity = 'WARNING',
  });

  factory AttentionItem.fromJson(Map<String, dynamic> json) {
    return AttentionItem(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      severity: json['severity'] as String? ?? 'WARNING',
    );
  }
}

class SubscriptionPlanModel {
  final String id;
  final String name;
  final String displayName;
  final String? description;
  final int maxProducts;
  final bool analyticsEnabled;
  final bool featuredEnabled;
  final double priceMonthly;
  final double priceYearly;
  final String currency;
  final int sortOrder;

  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    required this.maxProducts,
    required this.analyticsEnabled,
    required this.featuredEnabled,
    required this.priceMonthly,
    required this.priceYearly,
    this.currency = 'INR',
    this.sortOrder = 0,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      description: json['description'] as String?,
      maxProducts: (json['maxProducts'] as num?)?.toInt() ?? 50,
      analyticsEnabled: json['analyticsEnabled'] as bool? ?? false,
      featuredEnabled: json['featuredEnabled'] as bool? ?? false,
      priceMonthly: (json['priceMonthly'] as num?)?.toDouble() ?? 0.0,
      priceYearly: (json['priceYearly'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class ShopSubscriptionModel {
  final String? subscriptionId;
  final String? shopId;
  final String planName;
  final String planDisplayName;
  final String? description;
  final int maxProducts;
  final bool analyticsEnabled;
  final bool featuredEnabled;
  final double priceMonthly;
  final String currency;
  final String status;
  final String? startedAt;
  final String? expiresAt;
  final int currentProductCount;
  final bool canAddMoreProducts;

  const ShopSubscriptionModel({
    this.subscriptionId,
    this.shopId,
    required this.planName,
    required this.planDisplayName,
    this.description,
    required this.maxProducts,
    required this.analyticsEnabled,
    required this.featuredEnabled,
    required this.priceMonthly,
    this.currency = 'INR',
    required this.status,
    this.startedAt,
    this.expiresAt,
    required this.currentProductCount,
    required this.canAddMoreProducts,
  });

  factory ShopSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return ShopSubscriptionModel(
      subscriptionId: json['subscriptionId'] as String?,
      shopId: json['shopId'] as String?,
      planName: json['planName'] as String? ?? 'FREE',
      planDisplayName: json['planDisplayName'] as String? ?? 'Free Plan',
      description: json['description'] as String?,
      maxProducts: (json['maxProducts'] as num?)?.toInt() ?? 50,
      analyticsEnabled: json['analyticsEnabled'] as bool? ?? false,
      featuredEnabled: json['featuredEnabled'] as bool? ?? false,
      priceMonthly: (json['priceMonthly'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      status: json['status'] as String? ?? 'ACTIVE',
      startedAt: json['startedAt'] as String?,
      expiresAt: json['expiresAt'] as String?,
      currentProductCount: (json['currentProductCount'] as num?)?.toInt() ?? 0,
      canAddMoreProducts: json['canAddMoreProducts'] as bool? ?? true,
    );
  }
}
