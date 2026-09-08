class ConsumptionProfileModel {
  final String id;
  final String homeId;
  final String inventoryItemId;
  final String? itemName;
  final String unit;
  final double averageDailyConsumption;
  final double weightedDailyConsumption;
  final double minDailyConsumption;
  final double maxDailyConsumption;
  final double consumptionVariability;
  final double averagePurchaseInterval;
  final String? lastPurchaseDate;
  final double? lastPurchaseQuantity;
  final int? estimatedDaysRemaining;
  final String confidence;
  final String? confidenceExplanation;
  final int sampleCount;
  final String? typicalRangeText;
  final String? lastCalculatedAt;

  ConsumptionProfileModel({
    required this.id,
    required this.homeId,
    required this.inventoryItemId,
    this.itemName,
    this.unit = 'pcs',
    this.averageDailyConsumption = 0.0,
    this.weightedDailyConsumption = 0.0,
    this.minDailyConsumption = 0.0,
    this.maxDailyConsumption = 0.0,
    this.consumptionVariability = 0.0,
    this.averagePurchaseInterval = 7.0,
    this.lastPurchaseDate,
    this.lastPurchaseQuantity,
    this.estimatedDaysRemaining,
    this.confidence = 'LOW',
    this.confidenceExplanation,
    this.sampleCount = 0,
    this.typicalRangeText,
    this.lastCalculatedAt,
  });

  factory ConsumptionProfileModel.fromJson(Map<String, dynamic> json) {
    return ConsumptionProfileModel(
      id: json['id'] ?? '',
      homeId: json['homeId'] ?? '',
      inventoryItemId: json['inventoryItemId'] ?? '',
      itemName: json['itemName'],
      unit: json['unit'] ?? 'pcs',
      averageDailyConsumption: (json['averageDailyConsumption'] as num?)?.toDouble() ?? 0.0,
      weightedDailyConsumption: (json['weightedDailyConsumption'] as num?)?.toDouble() ?? 0.0,
      minDailyConsumption: (json['minDailyConsumption'] as num?)?.toDouble() ?? 0.0,
      maxDailyConsumption: (json['maxDailyConsumption'] as num?)?.toDouble() ?? 0.0,
      consumptionVariability: (json['consumptionVariability'] as num?)?.toDouble() ?? 0.0,
      averagePurchaseInterval: (json['averagePurchaseInterval'] as num?)?.toDouble() ?? 7.0,
      lastPurchaseDate: json['lastPurchaseDate'],
      lastPurchaseQuantity: (json['lastPurchaseQuantity'] as num?)?.toDouble(),
      estimatedDaysRemaining: json['estimatedDaysRemaining'] as int?,
      confidence: json['confidence'] ?? 'LOW',
      confidenceExplanation: json['confidenceExplanation'],
      sampleCount: json['sampleCount'] ?? 0,
      typicalRangeText: json['typicalRangeText'],
      lastCalculatedAt: json['lastCalculatedAt'],
    );
  }
}

class PredictionItemModel {
  final String itemId;
  final String itemName;
  final String categoryName;
  final double currentQuantity;
  final String formattedQuantity;
  final String unit;
  final String? quantityStatus;
  final String quantitySource;
  final String predictionStatus; // SAFE, WATCH, LOW, LIKELY_TO_RUN_OUT, OUT_OF_STOCK
  final int? estimatedDaysRemaining;
  final String predictionRangeText;
  final String confidence;
  final String? confidenceText;
  final String suggestedAction; // ADD_TO_SHOPPING, CHECK_STOCK, NONE

  PredictionItemModel({
    required this.itemId,
    required this.itemName,
    this.categoryName = 'General',
    this.currentQuantity = 0.0,
    required this.formattedQuantity,
    this.unit = 'pcs',
    this.quantityStatus,
    this.quantitySource = 'VERIFIED',
    required this.predictionStatus,
    this.estimatedDaysRemaining,
    required this.predictionRangeText,
    this.confidence = 'LOW',
    this.confidenceText,
    this.suggestedAction = 'NONE',
  });

  factory PredictionItemModel.fromJson(Map<String, dynamic> json) {
    return PredictionItemModel(
      itemId: json['itemId'] ?? '',
      itemName: json['itemName'] ?? '',
      categoryName: json['categoryName'] ?? 'General',
      currentQuantity: (json['currentQuantity'] as num?)?.toDouble() ?? 0.0,
      formattedQuantity: json['formattedQuantity'] ?? '${json['currentQuantity'] ?? 0} ${json['unit'] ?? "pcs"}',
      unit: json['unit'] ?? 'pcs',
      quantityStatus: json['quantityStatus'],
      quantitySource: json['quantitySource'] ?? 'VERIFIED',
      predictionStatus: json['predictionStatus'] ?? 'SAFE',
      estimatedDaysRemaining: json['estimatedDaysRemaining'] as int?,
      predictionRangeText: json['predictionRangeText'] ?? '',
      confidence: json['confidence'] ?? 'LOW',
      confidenceText: json['confidenceText'],
      suggestedAction: json['suggestedAction'] ?? 'NONE',
    );
  }
}

class SmartRecommendationItemModel {
  final String itemId;
  final String name;
  final String categoryName;
  final double currentQuantity;
  final String formattedCurrentQuantity;
  final double recommendedQuantity;
  final String unit;
  final String urgency; // URGENT, SOON, OPTIONAL
  final String rationale;
  final String confidence;

  SmartRecommendationItemModel({
    required this.itemId,
    required this.name,
    this.categoryName = 'General',
    this.currentQuantity = 0.0,
    required this.formattedCurrentQuantity,
    this.recommendedQuantity = 1.0,
    this.unit = 'pcs',
    required this.urgency,
    required this.rationale,
    this.confidence = 'LOW',
  });

  factory SmartRecommendationItemModel.fromJson(Map<String, dynamic> json) {
    return SmartRecommendationItemModel(
      itemId: json['itemId'] ?? '',
      name: json['name'] ?? '',
      categoryName: json['categoryName'] ?? 'General',
      currentQuantity: (json['currentQuantity'] as num?)?.toDouble() ?? 0.0,
      formattedCurrentQuantity: json['formattedCurrentQuantity'] ?? '',
      recommendedQuantity: (json['recommendedQuantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] ?? 'pcs',
      urgency: json['urgency'] ?? 'SOON',
      rationale: json['rationale'] ?? '',
      confidence: json['confidence'] ?? 'LOW',
    );
  }
}

class HomeInsightModel {
  final String homeId;
  final String primaryInsight;
  final List<String> bulletInsights;
  final double weeklySpent;
  final int weeklyPurchasesCount;
  final int itemsSavedFromDuplicate;
  final String? topCategory;
  final String? mostFrequentStaple;

  List<String> get insights => [
        if (primaryInsight.isNotEmpty) primaryInsight,
        ...bulletInsights,
      ];

  HomeInsightModel({
    required this.homeId,
    required this.primaryInsight,
    this.bulletInsights = const [],
    this.weeklySpent = 0.0,
    this.weeklyPurchasesCount = 0,
    this.itemsSavedFromDuplicate = 0,
    this.topCategory,
    this.mostFrequentStaple,
  });

  factory HomeInsightModel.fromJson(Map<String, dynamic> json) {
    final rawBullets = json['bulletInsights'] as List? ?? [];
    return HomeInsightModel(
      homeId: json['homeId'] ?? '',
      primaryInsight: json['primaryInsight'] ?? '',
      bulletInsights: rawBullets.map((e) => e.toString()).toList(),
      weeklySpent: (json['weeklySpent'] as num?)?.toDouble() ?? 0.0,
      weeklyPurchasesCount: json['weeklyPurchasesCount'] ?? 0,
      itemsSavedFromDuplicate: json['itemsSavedFromDuplicate'] ?? 0,
      topCategory: json['topCategory'],
      mostFrequentStaple: json['mostFrequentStaple'],
    );
  }
}

class ReturnSummaryModel {
  final String greeting;
  final String subtitle;
  final int itemsLikelyLowCount;
  final List<PredictionItemModel> itemsLikelyLow;
  final int itemsExpiringCount;
  final List<String> expiringItemNames;
  final int pendingShoppingCount;
  final int recentFamilyPurchasesCount;
  final bool booleanHasUpdates;
  final int daysAway;

  bool get hasAbsence => booleanHasUpdates || itemsLikelyLowCount > 0 || itemsExpiringCount > 0;
  String get message => subtitle;
  List<String> get flaggedItems => [
        ...itemsLikelyLow.map((e) => e.itemName),
        ...expiringItemNames,
      ];

  ReturnSummaryModel({
    required this.greeting,
    required this.subtitle,
    required this.itemsLikelyLowCount,
    this.itemsLikelyLow = const [],
    required this.itemsExpiringCount,
    this.expiringItemNames = const [],
    this.pendingShoppingCount = 0,
    this.recentFamilyPurchasesCount = 0,
    this.booleanHasUpdates = false,
    this.daysAway = 3,
  });

  factory ReturnSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawLow = json['itemsLikelyLow'] as List? ?? [];
    final rawExp = json['expiringItemNames'] as List? ?? [];
    return ReturnSummaryModel(
      greeting: json['greeting'] ?? 'Welcome back 👋',
      subtitle: json['subtitle'] ?? "Here's what changed while you were away.",
      itemsLikelyLowCount: json['itemsLikelyLowCount'] ?? 0,
      itemsLikelyLow: rawLow.map((e) => PredictionItemModel.fromJson(e)).toList(),
      itemsExpiringCount: json['itemsExpiringCount'] ?? 0,
      expiringItemNames: rawExp.map((e) => e.toString()).toList(),
      pendingShoppingCount: json['pendingShoppingCount'] ?? 0,
      recentFamilyPurchasesCount: json['recentFamilyPurchasesCount'] ?? 0,
      booleanHasUpdates: json['hasUpdates'] ?? false,
      daysAway: (json['daysAway'] as num?)?.toInt() ?? 3,
    );
  }
}
