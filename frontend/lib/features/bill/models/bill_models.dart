import 'package:flutter/foundation.dart';

@immutable
class ExistingProductMatchDto {
  final String? productId;
  final String? inventoryItemId;
  final String productName;
  final String? category;
  final double currentStock;
  final String unit;
  final double matchScore;

  const ExistingProductMatchDto({
    this.productId,
    this.inventoryItemId,
    required this.productName,
    this.category,
    this.currentStock = 0.0,
    this.unit = 'pcs',
    this.matchScore = 0.0,
  });

  factory ExistingProductMatchDto.fromJson(Map<String, dynamic> json) {
    return ExistingProductMatchDto(
      productId: json['productId']?.toString(),
      inventoryItemId: json['inventoryItemId']?.toString(),
      productName: json['productName']?.toString() ?? '',
      category: json['category']?.toString(),
      currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit']?.toString() ?? 'pcs',
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'inventoryItemId': inventoryItemId,
        'productName': productName,
        'category': category,
        'currentStock': currentStock,
        'unit': unit,
        'matchScore': matchScore,
      };
}

@immutable
class BillItemCandidateDto {
  final String rawItemName;
  final String normalizedItemName;
  final double quantity;
  final String unit;
  final double? mrp;
  final double unitPrice;
  final double discount;
  final double tax;
  final double finalPrice;
  final double standardUnitPrice;
  final double matchConfidence;
  final String matchStatus; // AUTO_MATCHED, SUGGESTED_MATCH, NEW_PRODUCT
  final String? matchedProductId;
  final String? matchedInventoryItemId;
  final String? matchedShoppingListItemId;
  final String? matchedExistingProductName;
  final bool isNewProductCandidate;
  final List<ExistingProductMatchDto> suggestedMatches;

  const BillItemCandidateDto({
    required this.rawItemName,
    required this.normalizedItemName,
    required this.quantity,
    this.unit = 'pcs',
    this.mrp,
    required this.unitPrice,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.finalPrice,
    this.standardUnitPrice = 0.0,
    this.matchConfidence = 0.0,
    this.matchStatus = 'NEW_PRODUCT',
    this.matchedProductId,
    this.matchedInventoryItemId,
    this.matchedShoppingListItemId,
    this.matchedExistingProductName,
    this.isNewProductCandidate = true,
    this.suggestedMatches = const [],
  });

  factory BillItemCandidateDto.fromJson(Map<String, dynamic> json) {
    return BillItemCandidateDto(
      rawItemName: json['rawItemName']?.toString() ?? '',
      normalizedItemName: json['normalizedItemName']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit']?.toString() ?? 'pcs',
      mrp: (json['mrp'] as num?)?.toDouble(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (json['finalPrice'] as num?)?.toDouble() ?? 0.0,
      standardUnitPrice: (json['standardUnitPrice'] as num?)?.toDouble() ?? 0.0,
      matchConfidence: (json['matchConfidence'] as num?)?.toDouble() ?? 0.0,
      matchStatus: json['matchStatus']?.toString() ?? 'NEW_PRODUCT',
      matchedProductId: json['matchedProductId']?.toString(),
      matchedInventoryItemId: json['matchedInventoryItemId']?.toString(),
      matchedShoppingListItemId: json['matchedShoppingListItemId']?.toString(),
      matchedExistingProductName: json['matchedExistingProductName']?.toString(),
      isNewProductCandidate: json['isNewProductCandidate'] as bool? ?? false,
      suggestedMatches: (json['suggestedMatches'] as List<dynamic>?)
              ?.map((e) => ExistingProductMatchDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  BillItemCandidateDto copyWith({
    String? rawItemName,
    String? normalizedItemName,
    double? quantity,
    String? unit,
    double? mrp,
    double? unitPrice,
    double? discount,
    double? tax,
    double? finalPrice,
    double? standardUnitPrice,
    double? matchConfidence,
    String? matchStatus,
    String? matchedProductId,
    String? matchedInventoryItemId,
    String? matchedShoppingListItemId,
    String? matchedExistingProductName,
    bool? isNewProductCandidate,
    List<ExistingProductMatchDto>? suggestedMatches,
  }) {
    return BillItemCandidateDto(
      rawItemName: rawItemName ?? this.rawItemName,
      normalizedItemName: normalizedItemName ?? this.normalizedItemName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      mrp: mrp ?? this.mrp,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      finalPrice: finalPrice ?? this.finalPrice,
      standardUnitPrice: standardUnitPrice ?? this.standardUnitPrice,
      matchConfidence: matchConfidence ?? this.matchConfidence,
      matchStatus: matchStatus ?? this.matchStatus,
      matchedProductId: matchedProductId ?? this.matchedProductId,
      matchedInventoryItemId: matchedInventoryItemId ?? this.matchedInventoryItemId,
      matchedShoppingListItemId: matchedShoppingListItemId ?? this.matchedShoppingListItemId,
      matchedExistingProductName: matchedExistingProductName ?? this.matchedExistingProductName,
      isNewProductCandidate: isNewProductCandidate ?? this.isNewProductCandidate,
      suggestedMatches: suggestedMatches ?? this.suggestedMatches,
    );
  }
}

@immutable
class BillScanResponseDto {
  final String? shopName;
  final String? billNumber;
  final String? billDate;
  final double totalAmount;
  final bool duplicateBillDetected;
  final String? existingBillId;
  final List<BillItemCandidateDto> items;

  const BillScanResponseDto({
    this.shopName,
    this.billNumber,
    this.billDate,
    this.totalAmount = 0.0,
    this.duplicateBillDetected = false,
    this.existingBillId,
    this.items = const [],
  });

  factory BillScanResponseDto.fromJson(Map<String, dynamic> json) {
    return BillScanResponseDto(
      shopName: json['shopName']?.toString(),
      billNumber: json['billNumber']?.toString(),
      billDate: json['billDate']?.toString(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      duplicateBillDetected: json['duplicateBillDetected'] as bool? ?? false,
      existingBillId: json['existingBillId']?.toString(),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => BillItemCandidateDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

@immutable
class BillConfirmItemDto {
  final String rawItemName;
  final String? productId;
  final String? inventoryItemId;
  final String? shoppingListItemId;
  final bool createNewProduct;
  final String? newProductName;
  final String? newProductCategory;
  final double quantity;
  final String unit;
  final double? mrp;
  final double unitPrice;
  final double discount;
  final double tax;
  final double finalPrice;

  const BillConfirmItemDto({
    required this.rawItemName,
    this.productId,
    this.inventoryItemId,
    this.shoppingListItemId,
    this.createNewProduct = false,
    this.newProductName,
    this.newProductCategory,
    required this.quantity,
    this.unit = 'pcs',
    this.mrp,
    required this.unitPrice,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.finalPrice,
  });

  Map<String, dynamic> toJson() => {
        'rawItemName': rawItemName,
        'productId': productId,
        'inventoryItemId': inventoryItemId,
        'shoppingListItemId': shoppingListItemId,
        'createNewProduct': createNewProduct,
        'newProductName': newProductName,
        'newProductCategory': newProductCategory,
        'quantity': quantity,
        'unit': unit,
        'mrp': mrp,
        'unitPrice': unitPrice,
        'discount': discount,
        'tax': tax,
        'finalPrice': finalPrice,
      };
}

@immutable
class BillConfirmRequestDto {
  final String? shopName;
  final String? billNumber;
  final String? billDate; // YYYY-MM-DD
  final double totalAmount;
  final String? rawOcrText;
  final List<BillConfirmItemDto> items;

  const BillConfirmRequestDto({
    this.shopName,
    this.billNumber,
    this.billDate,
    required this.totalAmount,
    this.rawOcrText,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'shopName': shopName,
        'billNumber': billNumber,
        'billDate': billDate,
        'totalAmount': totalAmount,
        'rawOcrText': rawOcrText,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

@immutable
class BillItemResponseDto {
  final String id;
  final String? productId;
  final String? inventoryItemId;
  final String? shoppingListItemId;
  final String rawItemName;
  final String normalizedItemName;
  final double quantity;
  final String unit;
  final double? mrp;
  final double unitPrice;
  final double discount;
  final double tax;
  final double finalPrice;
  final double standardUnitPrice;
  final double matchConfidence;
  final String matchStatus;

  const BillItemResponseDto({
    required this.id,
    this.productId,
    this.inventoryItemId,
    this.shoppingListItemId,
    required this.rawItemName,
    required this.normalizedItemName,
    required this.quantity,
    required this.unit,
    this.mrp,
    required this.unitPrice,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.finalPrice,
    this.standardUnitPrice = 0.0,
    this.matchConfidence = 100.0,
    this.matchStatus = 'AUTO_MATCHED',
  });

  factory BillItemResponseDto.fromJson(Map<String, dynamic> json) {
    return BillItemResponseDto(
      id: json['id']?.toString() ?? '',
      productId: json['productId']?.toString(),
      inventoryItemId: json['inventoryItemId']?.toString(),
      shoppingListItemId: json['shoppingListItemId']?.toString(),
      rawItemName: json['rawItemName']?.toString() ?? '',
      normalizedItemName: json['normalizedItemName']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit']?.toString() ?? 'pcs',
      mrp: (json['mrp'] as num?)?.toDouble(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (json['finalPrice'] as num?)?.toDouble() ?? 0.0,
      standardUnitPrice: (json['standardUnitPrice'] as num?)?.toDouble() ?? 0.0,
      matchConfidence: (json['matchConfidence'] as num?)?.toDouble() ?? 100.0,
      matchStatus: json['matchStatus']?.toString() ?? 'AUTO_MATCHED',
    );
  }
}

@immutable
class BillResponseDto {
  final String id;
  final String shopName;
  final String? billNumber;
  final String billDate;
  final double totalAmount;
  final int itemCount;
  final String? rawOcrText;
  final String? createdAt;
  final List<BillItemResponseDto> items;

  const BillResponseDto({
    required this.id,
    required this.shopName,
    this.billNumber,
    required this.billDate,
    required this.totalAmount,
    this.itemCount = 0,
    this.rawOcrText,
    this.createdAt,
    this.items = const [],
  });

  factory BillResponseDto.fromJson(Map<String, dynamic> json) {
    return BillResponseDto(
      id: json['id']?.toString() ?? '',
      shopName: json['shopName']?.toString() ?? 'Retail Store',
      billNumber: json['billNumber']?.toString(),
      billDate: json['billDate']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      itemCount: json['itemCount'] as int? ?? 0,
      rawOcrText: json['rawOcrText']?.toString(),
      createdAt: json['createdAt']?.toString(),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => BillItemResponseDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

// ──────────────── Expense Intelligence Models ────────────────

@immutable
class CategoryExpenseDto {
  final String category;
  final double totalSpend;
  final double percentageOfTotal;
  final int itemCount;

  const CategoryExpenseDto({
    required this.category,
    required this.totalSpend,
    required this.percentageOfTotal,
    required this.itemCount,
  });

  factory CategoryExpenseDto.fromJson(Map<String, dynamic> json) {
    return CategoryExpenseDto(
      category: json['category']?.toString() ?? 'General',
      totalSpend: (json['totalSpend'] as num?)?.toDouble() ?? 0.0,
      percentageOfTotal: (json['percentageOfTotal'] as num?)?.toDouble() ?? 0.0,
      itemCount: json['itemCount'] as int? ?? 0,
    );
  }
}

@immutable
class TopRetailerDto {
  final String retailerName;
  final double totalSpend;
  final int billCount;
  final double percentageOfTotal;

  const TopRetailerDto({
    required this.retailerName,
    required this.totalSpend,
    required this.billCount,
    required this.percentageOfTotal,
  });

  factory TopRetailerDto.fromJson(Map<String, dynamic> json) {
    return TopRetailerDto(
      retailerName: json['retailerName']?.toString() ?? 'Retailer',
      totalSpend: (json['totalSpend'] as num?)?.toDouble() ?? 0.0,
      billCount: json['billCount'] as int? ?? 0,
      percentageOfTotal: (json['percentageOfTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

@immutable
class PriceAnomalyDto {
  final String productName;
  final String? category;
  final double currentPrice;
  final double previousPrice;
  final double percentageChange;
  final String unit;
  final String alertType; // PRICE_HIKE, PRICE_DROP
  final String? detectedAt;

  const PriceAnomalyDto({
    required this.productName,
    this.category,
    required this.currentPrice,
    required this.previousPrice,
    required this.percentageChange,
    required this.unit,
    required this.alertType,
    this.detectedAt,
  });

  factory PriceAnomalyDto.fromJson(Map<String, dynamic> json) {
    return PriceAnomalyDto(
      productName: json['productName']?.toString() ?? '',
      category: json['category']?.toString(),
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
      previousPrice: (json['previousPrice'] as num?)?.toDouble() ?? 0.0,
      percentageChange: (json['percentageChange'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit']?.toString() ?? 'pcs',
      alertType: json['alertType']?.toString() ?? 'PRICE_HIKE',
      detectedAt: json['detectedAt']?.toString(),
    );
  }
}

@immutable
class MonthlyExpenseReportDto {
  final int year;
  final int month;
  final double totalSpend;
  final double previousMonthSpend;
  final double momPercentageChange;
  final int totalBills;
  final int totalItemsPurchased;
  final List<CategoryExpenseDto> categoryBreakdown;
  final List<TopRetailerDto> topRetailers;
  final List<PriceAnomalyDto> priceAnomalies;

  const MonthlyExpenseReportDto({
    required this.year,
    required this.month,
    required this.totalSpend,
    required this.previousMonthSpend,
    required this.momPercentageChange,
    required this.totalBills,
    required this.totalItemsPurchased,
    this.categoryBreakdown = const [],
    this.topRetailers = const [],
    this.priceAnomalies = const [],
  });

  factory MonthlyExpenseReportDto.fromJson(Map<String, dynamic> json) {
    return MonthlyExpenseReportDto(
      year: json['year'] as int? ?? DateTime.now().year,
      month: json['month'] as int? ?? DateTime.now().month,
      totalSpend: (json['totalSpend'] as num?)?.toDouble() ?? 0.0,
      previousMonthSpend: (json['previousMonthSpend'] as num?)?.toDouble() ?? 0.0,
      momPercentageChange: (json['momPercentageChange'] as num?)?.toDouble() ?? 0.0,
      totalBills: json['totalBills'] as int? ?? 0,
      totalItemsPurchased: json['totalItemsPurchased'] as int? ?? 0,
      categoryBreakdown: (json['categoryBreakdown'] as List<dynamic>?)
              ?.map((e) => CategoryExpenseDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      topRetailers: (json['topRetailers'] as List<dynamic>?)
              ?.map((e) => TopRetailerDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      priceAnomalies: (json['priceAnomalies'] as List<dynamic>?)
              ?.map((e) => PriceAnomalyDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

@immutable
class StoreComparisonDto {
  final String storeName;
  final double totalSpent;
  final int visitCount;
  final double avgSpendPerVisit;
  final String? firstSeen;
  final String? lastSeen;

  const StoreComparisonDto({
    required this.storeName,
    required this.totalSpent,
    required this.visitCount,
    required this.avgSpendPerVisit,
    this.firstSeen,
    this.lastSeen,
  });

  factory StoreComparisonDto.fromJson(Map<String, dynamic> json) {
    return StoreComparisonDto(
      storeName: json['storeName']?.toString() ?? 'Retail Store',
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      visitCount: json['visitCount'] as int? ?? 0,
      avgSpendPerVisit: (json['avgSpendPerVisit'] as num?)?.toDouble() ?? 0.0,
      firstSeen: json['firstSeen']?.toString(),
      lastSeen: json['lastSeen']?.toString(),
    );
  }
}

@immutable
class PricePointDto {
  final String purchaseDate;
  final String storeName;
  final double unitPrice;
  final double standardUnitPrice;
  final double quantity;
  final String unit;

  const PricePointDto({
    required this.purchaseDate,
    required this.storeName,
    required this.unitPrice,
    required this.standardUnitPrice,
    required this.quantity,
    required this.unit,
  });

  factory PricePointDto.fromJson(Map<String, dynamic> json) {
    return PricePointDto(
      purchaseDate: json['purchaseDate']?.toString() ?? '',
      storeName: json['storeName']?.toString() ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      standardUnitPrice: (json['standardUnitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit']?.toString() ?? 'pcs',
    );
  }
}

@immutable
class ProductPriceHistoryDto {
  final String productId;
  final String productName;
  final double lowestPrice;
  final double highestPrice;
  final double currentPrice;
  final List<PricePointDto> pricePoints;

  const ProductPriceHistoryDto({
    required this.productId,
    required this.productName,
    required this.lowestPrice,
    required this.highestPrice,
    required this.currentPrice,
    this.pricePoints = const [],
  });

  factory ProductPriceHistoryDto.fromJson(Map<String, dynamic> json) {
    return ProductPriceHistoryDto(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      lowestPrice: (json['lowestPrice'] as num?)?.toDouble() ?? 0.0,
      highestPrice: (json['highestPrice'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
      pricePoints: (json['pricePoints'] as List<dynamic>?)
              ?.map((e) => PricePointDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
