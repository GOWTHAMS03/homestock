// Customer Demand Intelligence Models

enum DemandPeriod {
  today('TODAY', 'Today'),
  last7Days('LAST_7_DAYS', 'Last 7 Days'),
  last30Days('LAST_30_DAYS', 'Last 30 Days'),
  last90Days('LAST_90_DAYS', 'Last 90 Days');

  final String apiValue;
  final String label;

  const DemandPeriod(this.apiValue, this.label);

  static DemandPeriod fromString(String? val) {
    if (val == null) return DemandPeriod.last7Days;
    return DemandPeriod.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == val.toUpperCase(),
      orElse: () => DemandPeriod.last7Days,
    );
  }
}

enum DemandTrend {
  highDemand('HIGH_DEMAND', 'High Demand'),
  rising('RISING', 'Rising'),
  normal('NORMAL', 'Steady'),
  falling('FALLING', 'Decreasing');

  final String apiValue;
  final String label;

  const DemandTrend(this.apiValue, this.label);

  static DemandTrend fromString(String? val) {
    if (val == null) return DemandTrend.normal;
    return DemandTrend.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == val.toUpperCase(),
      orElse: () => DemandTrend.normal,
    );
  }
}

enum OpportunityType {
  missingProduct('MISSING_PRODUCT', 'Catalog Gap'),
  outOfStock('OUT_OF_STOCK', 'Out of Stock'),
  lowStock('LOW_STOCK', 'Low Stock'),
  priceOpportunity('PRICE_OPPORTUNITY', 'Price Opportunity');

  final String apiValue;
  final String label;

  const OpportunityType(this.apiValue, this.label);

  static OpportunityType fromString(String? val) {
    if (val == null) return OpportunityType.missingProduct;
    return OpportunityType.values.firstWhere(
      (e) => e.apiValue.toUpperCase() == val.toUpperCase(),
      orElse: () => OpportunityType.missingProduct,
    );
  }
}

class ProductDemandItemModel {
  final String productName;
  final String categoryName;
  final String? canonicalProductId;
  final String? shopOfferId;
  final int totalSignals;
  final double demandScore;
  final DemandTrend trend;
  final double? percentageGrowth;
  final bool inShopCatalog;
  final String shopStockStatus;
  final double? shopPrice;
  final double? minCompetitorPrice;
  final double? avgCompetitorPrice;
  final bool lowDataWarning;
  final String topZone;

  const ProductDemandItemModel({
    required this.productName,
    required this.categoryName,
    this.canonicalProductId,
    this.shopOfferId,
    required this.totalSignals,
    required this.demandScore,
    required this.trend,
    this.percentageGrowth,
    required this.inShopCatalog,
    required this.shopStockStatus,
    this.shopPrice,
    this.minCompetitorPrice,
    this.avgCompetitorPrice,
    required this.lowDataWarning,
    required this.topZone,
  });

  factory ProductDemandItemModel.fromJson(Map<String, dynamic> json) {
    return ProductDemandItemModel(
      productName: json['productName'] as String? ?? 'Unknown Product',
      categoryName: json['categoryName'] as String? ?? 'General',
      canonicalProductId: json['canonicalProductId'] as String?,
      shopOfferId: json['shopOfferId'] as String?,
      totalSignals: (json['totalSignals'] as num?)?.toInt() ?? 0,
      demandScore: (json['demandScore'] as num?)?.toDouble() ?? 0.0,
      trend: DemandTrend.fromString(json['trend'] as String?),
      percentageGrowth: (json['percentageGrowth'] as num?)?.toDouble(),
      inShopCatalog: json['inShopCatalog'] as bool? ?? false,
      shopStockStatus: json['shopStockStatus'] as String? ?? 'NOT_IN_CATALOG',
      shopPrice: (json['shopPrice'] as num?)?.toDouble(),
      minCompetitorPrice: (json['minCompetitorPrice'] as num?)?.toDouble(),
      avgCompetitorPrice: (json['avgCompetitorPrice'] as num?)?.toDouble(),
      lowDataWarning: json['lowDataWarning'] as bool? ?? false,
      topZone: json['topZone'] as String? ?? '0 - 1 km',
    );
  }
}

class DemandOpportunityModel {
  final String id;
  final OpportunityType type;
  final String title;
  final String description;
  final String productName;
  final String categoryName;
  final String? productId;
  final String? shopOfferId;
  final double priorityScore;
  final String suggestedAction;
  final double? currentShopPrice;
  final double? competitorPrice;
  final int localDemandCount;

  const DemandOpportunityModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.productName,
    required this.categoryName,
    this.productId,
    this.shopOfferId,
    required this.priorityScore,
    required this.suggestedAction,
    this.currentShopPrice,
    this.competitorPrice,
    required this.localDemandCount,
  });

  factory DemandOpportunityModel.fromJson(Map<String, dynamic> json) {
    return DemandOpportunityModel(
      id: json['id'] as String? ?? '',
      type: OpportunityType.fromString(json['type'] as String?),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      productId: json['productId'] as String?,
      shopOfferId: json['shopOfferId'] as String?,
      priorityScore: (json['priorityScore'] as num?)?.toDouble() ?? 0.0,
      suggestedAction: json['suggestedAction'] as String? ?? 'View',
      currentShopPrice: (json['currentShopPrice'] as num?)?.toDouble(),
      competitorPrice: (json['competitorPrice'] as num?)?.toDouble(),
      localDemandCount: (json['localDemandCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class DemandZoneModel {
  final String zoneLabel;
  final double minRadiusKm;
  final double maxRadiusKm;
  final int totalEvents;
  final double demandSharePercentage;
  final List<String> topSearchTerms;

  const DemandZoneModel({
    required this.zoneLabel,
    required this.minRadiusKm,
    required this.maxRadiusKm,
    required this.totalEvents,
    required this.demandSharePercentage,
    required this.topSearchTerms,
  });

  factory DemandZoneModel.fromJson(Map<String, dynamic> json) {
    return DemandZoneModel(
      zoneLabel: json['zoneLabel'] as String? ?? '',
      minRadiusKm: (json['minRadiusKm'] as num?)?.toDouble() ?? 0.0,
      maxRadiusKm: (json['maxRadiusKm'] as num?)?.toDouble() ?? 0.0,
      totalEvents: (json['totalEvents'] as num?)?.toInt() ?? 0,
      demandSharePercentage: (json['demandSharePercentage'] as num?)?.toDouble() ?? 0.0,
      topSearchTerms: (json['topSearchTerms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class CustomerDemandDashboardModel {
  final String shopId;
  final String shopName;
  final String period;
  final double radiusKm;
  final int totalDemandSignals;
  final int uniqueSearchQueries;
  final int missingProductsCount;
  final int restockOpportunitiesCount;
  final int priceOpportunitiesCount;
  final List<ProductDemandItemModel> topDemandedProducts;
  final List<DemandOpportunityModel> opportunities;
  final List<DemandZoneModel> demandZones;
  final bool isGated;
  final String subscriptionTier;
  final String summaryInsight;

  const CustomerDemandDashboardModel({
    required this.shopId,
    required this.shopName,
    required this.period,
    required this.radiusKm,
    required this.totalDemandSignals,
    required this.uniqueSearchQueries,
    required this.missingProductsCount,
    required this.restockOpportunitiesCount,
    required this.priceOpportunitiesCount,
    required this.topDemandedProducts,
    required this.opportunities,
    required this.demandZones,
    required this.isGated,
    required this.subscriptionTier,
    required this.summaryInsight,
  });

  factory CustomerDemandDashboardModel.fromJson(Map<String, dynamic> json) {
    return CustomerDemandDashboardModel(
      shopId: json['shopId'] as String? ?? '',
      shopName: json['shopName'] as String? ?? '',
      period: json['period'] as String? ?? 'LAST_7_DAYS',
      radiusKm: (json['radiusKm'] as num?)?.toDouble() ?? 5.0,
      totalDemandSignals: (json['totalDemandSignals'] as num?)?.toInt() ?? 0,
      uniqueSearchQueries: (json['uniqueSearchQueries'] as num?)?.toInt() ?? 0,
      missingProductsCount: (json['missingProductsCount'] as num?)?.toInt() ?? 0,
      restockOpportunitiesCount: (json['restockOpportunitiesCount'] as num?)?.toInt() ?? 0,
      priceOpportunitiesCount: (json['priceOpportunitiesCount'] as num?)?.toInt() ?? 0,
      topDemandedProducts: (json['topDemandedProducts'] as List<dynamic>?)
              ?.map((e) => ProductDemandItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      opportunities: (json['opportunities'] as List<dynamic>?)
              ?.map((e) => DemandOpportunityModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      demandZones: (json['demandZones'] as List<dynamic>?)
              ?.map((e) => DemandZoneModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isGated: json['isGated'] as bool? ?? false,
      subscriptionTier: json['subscriptionTier'] as String? ?? 'FREE',
      summaryInsight: json['summaryInsight'] as String? ?? '',
    );
  }
}

class ProductDemandDetailModel {
  final String queryText;
  final String? canonicalProductId;
  final String? categoryName;
  final int totalSignals;
  final double demandScore;
  final DemandTrend trend;
  final Map<String, int> signalsByType;
  final List<DemandZoneModel> breakdownByZone;
  final bool inShopCatalog;
  final String? shopOfferId;
  final String shopStockStatus;
  final double? shopPrice;
  final double? minCompetitorPrice;
  final double? avgCompetitorPrice;

  const ProductDemandDetailModel({
    required this.queryText,
    this.canonicalProductId,
    this.categoryName,
    required this.totalSignals,
    required this.demandScore,
    required this.trend,
    required this.signalsByType,
    required this.breakdownByZone,
    required this.inShopCatalog,
    this.shopOfferId,
    required this.shopStockStatus,
    this.shopPrice,
    this.minCompetitorPrice,
    this.avgCompetitorPrice,
  });

  factory ProductDemandDetailModel.fromJson(Map<String, dynamic> json) {
    final rawSignals = json['signalsByType'] as Map<String, dynamic>? ?? {};
    final signalsMap = rawSignals.map((k, v) => MapEntry(k, (v as num).toInt()));

    return ProductDemandDetailModel(
      queryText: json['queryText'] as String? ?? '',
      canonicalProductId: json['canonicalProductId'] as String?,
      categoryName: json['categoryName'] as String?,
      totalSignals: (json['totalSignals'] as num?)?.toInt() ?? 0,
      demandScore: (json['demandScore'] as num?)?.toDouble() ?? 0.0,
      trend: DemandTrend.fromString(json['trend'] as String?),
      signalsByType: signalsMap,
      breakdownByZone: (json['breakdownByZone'] as List<dynamic>?)
              ?.map((e) => DemandZoneModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      inShopCatalog: json['inShopCatalog'] as bool? ?? false,
      shopOfferId: json['shopOfferId'] as String?,
      shopStockStatus: json['shopStockStatus'] as String? ?? 'NOT_IN_CATALOG',
      shopPrice: (json['shopPrice'] as num?)?.toDouble(),
      minCompetitorPrice: (json['minCompetitorPrice'] as num?)?.toDouble(),
      avgCompetitorPrice: (json['avgCompetitorPrice'] as num?)?.toDouble(),
    );
  }
}
