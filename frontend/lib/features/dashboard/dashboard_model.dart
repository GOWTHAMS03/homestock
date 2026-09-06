class NeedsAttentionModel {
  final String itemId;
  final String name;
  final String categoryName;
  final double quantity;
  final String unit;
  final String stockStatus;
  final String expiryStatus;
  final String? expiryDate;
  final int? daysUntilExpiry;
  final String reasonMessage;

  NeedsAttentionModel({
    required this.itemId,
    required this.name,
    required this.categoryName,
    required this.quantity,
    required this.unit,
    required this.stockStatus,
    required this.expiryStatus,
    this.expiryDate,
    this.daysUntilExpiry,
    required this.reasonMessage,
  });

  factory NeedsAttentionModel.fromJson(Map<String, dynamic> json) {
    return NeedsAttentionModel(
      itemId: json['itemId'] ?? '',
      name: json['name'] ?? '',
      categoryName: json['categoryName'] ?? 'General',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? 'pcs',
      stockStatus: json['stockStatus'] ?? 'IN_STOCK',
      expiryStatus: json['expiryStatus'] ?? 'SAFE',
      expiryDate: json['expiryDate'],
      daysUntilExpiry: json['daysUntilExpiry'] as int?,
      reasonMessage: json['reasonMessage'] ?? '',
    );
  }
}

class DashboardSummaryModel {
  final String homeName;
  final int totalInventoryItems;
  final int lowStockCount;
  final int outOfStockCount;
  final int pendingShoppingCount;
  final int expiringSoonCount;
  final List<NeedsAttentionModel> needsAttention;

  DashboardSummaryModel({
    required this.homeName,
    required this.totalInventoryItems,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.pendingShoppingCount,
    required this.expiringSoonCount,
    required this.needsAttention,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawAttention = json['needsAttention'] as List? ?? [];
    return DashboardSummaryModel(
      homeName: json['homeName'] ?? '',
      totalInventoryItems: json['totalInventoryItems'] ?? 0,
      lowStockCount: json['lowStockCount'] ?? 0,
      outOfStockCount: json['outOfStockCount'] ?? 0,
      pendingShoppingCount: json['pendingShoppingCount'] ?? 0,
      expiringSoonCount: json['expiringSoonCount'] ?? 0,
      needsAttention: rawAttention.map((i) => NeedsAttentionModel.fromJson(i)).toList(),
    );
  }
}

class RecommendationModel {
  final String itemId;
  final String name;
  final String categoryName;
  final double currentQuantity;
  final double recommendedQuantity;
  final String unit;
  final String rationale;

  RecommendationModel({
    required this.itemId,
    required this.name,
    required this.categoryName,
    required this.currentQuantity,
    required this.recommendedQuantity,
    required this.unit,
    required this.rationale,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      itemId: json['itemId'] ?? '',
      name: json['name'] ?? '',
      categoryName: json['categoryName'] ?? 'General',
      currentQuantity: (json['currentQuantity'] as num?)?.toDouble() ?? 0.0,
      recommendedQuantity: (json['recommendedQuantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] ?? 'pcs',
      rationale: json['rationale'] ?? '',
    );
  }
}

class WhatDoINeedModel {
  final List<RecommendationModel> urgent;
  final List<RecommendationModel> soon;
  final List<RecommendationModel> optional;

  WhatDoINeedModel({
    required this.urgent,
    required this.soon,
    required this.optional,
  });

  factory WhatDoINeedModel.fromJson(Map<String, dynamic> json) {
    final rawUrgent = json['urgent'] as List? ?? [];
    final rawSoon = json['soon'] as List? ?? [];
    final rawOptional = json['optional'] as List? ?? [];

    return WhatDoINeedModel(
      urgent: rawUrgent.map((i) => RecommendationModel.fromJson(i)).toList(),
      soon: rawSoon.map((i) => RecommendationModel.fromJson(i)).toList(),
      optional: rawOptional.map((i) => RecommendationModel.fromJson(i)).toList(),
    );
  }
}
