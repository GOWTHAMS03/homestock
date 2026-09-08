import 'package:flutter/material.dart';

class InventoryItemModel {
  final String id;
  final String homeId;
  final String? categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final String name;
  final String? brand;
  final double quantity;
  final String unit;
  final double minimumQuantity;
  final double? maximumQuantity;
  final String? storageLocation;
  final double? purchasePrice;
  final String? purchaseDate;
  final String? expiryDate;
  final String? imageUrl;
  final String? notes;
  final String? barcode;
  final String? productId;
  final String stockStatus; // IN_STOCK, LOW_STOCK, OUT_OF_STOCK
  final String expiryStatus; // SAFE, EXPIRING_SOON, EXPIRED
  final int? daysUntilExpiry;
  final String? quantityStatus; // ALMOST_FULL, MORE_THAN_HALF, ABOUT_HALF, LESS_THAN_HALF, ALMOST_EMPTY, EMPTY
  final String quantitySource; // VERIFIED, ESTIMATED, UNKNOWN
  final String confidence; // HIGH, MEDIUM, LOW
  final int? estimatedDaysRemaining;
  final double? estimatedDailyConsumption;
  final String? lastVerifiedAt;

  InventoryItemModel({
    required this.id,
    required this.homeId,
    this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.name,
    this.brand,
    required this.quantity,
    required this.unit,
    required this.minimumQuantity,
    this.maximumQuantity,
    this.storageLocation,
    this.purchasePrice,
    this.purchaseDate,
    this.expiryDate,
    this.imageUrl,
    this.notes,
    this.barcode,
    this.productId,
    required this.stockStatus,
    required this.expiryStatus,
    this.daysUntilExpiry,
    this.quantityStatus,
    this.quantitySource = 'VERIFIED',
    this.confidence = 'HIGH',
    this.estimatedDaysRemaining,
    this.estimatedDailyConsumption,
    this.lastVerifiedAt,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'] ?? '',
      homeId: json['homeId'] ?? '',
      categoryId: json['categoryId'],
      categoryName: json['categoryName'] ?? 'General',
      categoryIcon: json['categoryIcon'] ?? 'category',
      categoryColor: json['categoryColor'] ?? '#6366F1',
      name: json['name'] ?? '',
      brand: json['brand'],
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? 'pcs',
      minimumQuantity: (json['minimumQuantity'] as num?)?.toDouble() ?? 1.0,
      maximumQuantity: (json['maximumQuantity'] as num?)?.toDouble(),
      storageLocation: json['storageLocation'],
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble(),
      purchaseDate: json['purchaseDate'],
      expiryDate: json['expiryDate'],
      imageUrl: json['imageUrl'],
      notes: json['notes'],
      barcode: json['barcode'] as String?,
      productId: json['productId'] as String?,
      stockStatus: json['stockStatus'] ?? 'IN_STOCK',
      expiryStatus: json['expiryStatus'] ?? 'SAFE',
      daysUntilExpiry: json['daysUntilExpiry'] as int?,
      quantityStatus: json['quantityStatus'],
      quantitySource: json['quantitySource'] ?? 'VERIFIED',
      confidence: json['confidence'] ?? 'HIGH',
      estimatedDaysRemaining: json['estimatedDaysRemaining'] as int?,
      estimatedDailyConsumption: (json['estimatedDailyConsumption'] as num?)?.toDouble(),
      lastVerifiedAt: json['lastVerifiedAt'],
    );
  }

  bool get isOutOfStock => stockStatus == 'OUT_OF_STOCK' || quantity == 0;
  bool get isLowStock => stockStatus == 'LOW_STOCK';
  bool get isExpiringSoon => expiryStatus == 'EXPIRING_SOON';
  bool get isExpired => expiryStatus == 'EXPIRED';
  bool get isEstimated => quantitySource == 'ESTIMATED';

  String get humanQuantityDisplay {
    if (isOutOfStock) return 'Out of stock';
    if (quantityStatus != null && quantityStatus!.isNotEmpty && quantitySource == 'VERIFIED') {
      switch (quantityStatus) {
        case 'ALMOST_FULL': return 'Almost full';
        case 'MORE_THAN_HALF': return 'More than half';
        case 'ABOUT_HALF': return 'About half';
        case 'LESS_THAN_HALF': return 'Less than half';
        case 'ALMOST_EMPTY': return 'Almost empty';
        case 'EMPTY': return 'Empty';
      }
    }
    final numStr = (quantity % 1 == 0) ? quantity.toInt().toString() : quantity.toStringAsFixed(1);
    if (isEstimated) {
      if (estimatedDaysRemaining != null && estimatedDaysRemaining! > 0 && estimatedDaysRemaining! <= 7) {
        final minD = (estimatedDaysRemaining! - 1).clamp(1, 7);
        final maxD = estimatedDaysRemaining! + 1;
        return 'Likely enough for $minD–$maxD days';
      }
      return '~$numStr $unit left';
    }
    return '$numStr $unit';
  }

  Color get categoryColorParsed {
    try {
      final hex = categoryColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }

  IconData get categoryIconData {
    switch (categoryIcon) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'cleaning_services':
        return Icons.cleaning_services_rounded;
      case 'bathtub':
        return Icons.bathtub_rounded;
      case 'face':
        return Icons.face_rounded;
      case 'fastfood':
        return Icons.fastfood_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'homeId': homeId,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'categoryIcon': categoryIcon,
    'categoryColor': categoryColor,
    'name': name,
    'brand': brand,
    'quantity': quantity,
    'unit': unit,
    'minimumQuantity': minimumQuantity,
    'maximumQuantity': maximumQuantity,
    'storageLocation': storageLocation,
    'purchasePrice': purchasePrice,
    'purchaseDate': purchaseDate,
    'expiryDate': expiryDate,
    'imageUrl': imageUrl,
    'notes': notes,
    'barcode': barcode,
    'productId': productId,
    'stockStatus': stockStatus,
    'expiryStatus': expiryStatus,
    'daysUntilExpiry': daysUntilExpiry,
  };
}

class StockTransactionModel {
  final String id;
  final String itemId;
  final String itemName;
  final String userName;
  final String transactionType;
  final double quantityChange;
  final double previousQuantity;
  final double newQuantity;
  final String unit;
  final String? reason;
  final String createdAt;

  StockTransactionModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.userName,
    required this.transactionType,
    required this.quantityChange,
    required this.previousQuantity,
    required this.newQuantity,
    required this.unit,
    this.reason,
    required this.createdAt,
  });

  factory StockTransactionModel.fromJson(Map<String, dynamic> json) {
    return StockTransactionModel(
      id: json['id'] ?? '',
      itemId: json['itemId'] ?? '',
      itemName: json['itemName'] ?? '',
      userName: json['userName'] ?? '',
      transactionType: json['transactionType'] ?? 'ADJUSTMENT',
      quantityChange: (json['quantityChange'] as num?)?.toDouble() ?? 0.0,
      previousQuantity: (json['previousQuantity'] as num?)?.toDouble() ?? 0.0,
      newQuantity: (json['newQuantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? 'pcs',
      reason: json['reason'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemId': itemId,
    'itemName': itemName,
    'userName': userName,
    'transactionType': transactionType,
    'quantityChange': quantityChange,
    'previousQuantity': previousQuantity,
    'newQuantity': newQuantity,
    'unit': unit,
    'reason': reason,
    'createdAt': createdAt,
  };
}
