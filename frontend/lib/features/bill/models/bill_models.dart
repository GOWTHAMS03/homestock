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
  final String? categoryName;
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
    this.categoryName,
    this.isNewProductCandidate = true,
    this.suggestedMatches = const [],
  });

  factory BillItemCandidateDto.fromJson(Map<String, dynamic> json) {
    final status = json['matchStatus']?.toString() ?? 'NEW_PRODUCT';
    return BillItemCandidateDto(
      rawItemName: json['rawItemName']?.toString() ?? '',
      normalizedItemName: json['normalizedItemName']?.toString() ??
          json['matchedProductName']?.toString() ??
          json['rawItemName']?.toString() ??
          '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit']?.toString() ?? 'pcs',
      mrp: (json['mrp'] as num?)?.toDouble(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (json['finalPrice'] as num?)?.toDouble() ?? 0.0,
      standardUnitPrice: (json['standardUnitPrice'] as num?)?.toDouble() ?? 0.0,
      matchConfidence: (json['matchConfidence'] as num?)?.toDouble() ?? 0.0,
      matchStatus: status,
      matchedProductId: json['matchedProductId']?.toString(),
      matchedInventoryItemId: json['matchedInventoryItemId']?.toString(),
      matchedShoppingListItemId: json['matchedShoppingListItemId']?.toString(),
      matchedExistingProductName: json['matchedExistingProductName']?.toString() ??
          json['matchedProductName']?.toString(),
      categoryName: json['categoryName']?.toString() ??
          json['category']?.toString() ??
          json['newProductCategory']?.toString(),
      isNewProductCandidate: (json['isNewProductCandidate'] as bool?) ?? (status == 'NEW_PRODUCT'),
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
    String? categoryName,
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
      categoryName: categoryName ?? this.categoryName,
      isNewProductCandidate: isNewProductCandidate ?? this.isNewProductCandidate,
      suggestedMatches: suggestedMatches ?? this.suggestedMatches,
    );
  }
}

@immutable
class BillScanResponseDto {
  final String? billId;
  final String? shopName;
  final String? billNumber;
  final String? billDate;
  final double totalAmount;
  final bool duplicateBillDetected;
  final String? existingBillId;
  final List<BillItemCandidateDto> items;

  const BillScanResponseDto({
    this.billId,
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
      billId: json['billId']?.toString(),
      shopName: json['shopName']?.toString(),
      billNumber: json['billNumber']?.toString(),
      billDate: json['billDate']?.toString(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ??
          (json['total'] as num?)?.toDouble() ??
          0.0,
      duplicateBillDetected: (json['duplicateBillDetected'] as bool?) ??
          (json['isDuplicate'] as bool?) ??
          false,
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
  final String? categoryName;
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
    this.categoryName,
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
        'newProductCategory': newProductCategory ?? categoryName,
        'categoryName': categoryName ?? newProductCategory,
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
  final String? billId;
  final String? shopName;
  final String? billNumber;
  final String? billDate; // YYYY-MM-DD
  final double totalAmount;
  final String? rawOcrText;
  final List<BillConfirmItemDto> items;

  const BillConfirmRequestDto({
    this.billId,
    this.shopName,
    this.billNumber,
    this.billDate,
    required this.totalAmount,
    this.rawOcrText,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        if (billId != null) 'billId': billId,
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
      category: json['category']?.toString() ?? json['categoryName']?.toString() ?? 'General',
      totalSpend: (json['totalSpend'] as num?)?.toDouble() ??
          (json['totalAmount'] as num?)?.toDouble() ??
          0.0,
      percentageOfTotal: (json['percentageOfTotal'] as num?)?.toDouble() ??
          (json['spendingPercentage'] as num?)?.toDouble() ??
          0.0,
      itemCount: json['itemCount'] as int? ??
          (json['purchaseCount'] as num?)?.toInt() ??
          0,
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
      retailerName: json['retailerName']?.toString() ??
          json['shopName']?.toString() ??
          'Retailer',
      totalSpend: (json['totalSpend'] as num?)?.toDouble() ??
          (json['totalAmount'] as num?)?.toDouble() ??
          0.0,
      billCount: json['billCount'] as int? ??
          (json['billsCount'] as num?)?.toInt() ??
          0,
      percentageOfTotal: (json['percentageOfTotal'] as num?)?.toDouble() ??
          (json['spendingPercentage'] as num?)?.toDouble() ??
          0.0,
    );
  }
}

@immutable
class PriceAnomalyDto {
  final String? productId;
  final String? inventoryItemId;
  final String productName;
  final String? category;
  final double currentPrice;
  final double previousPrice;
  final double percentageChange;
  final String unit;
  final String alertType; // PRICE_HIKE, PRICE_DROP
  final String? storeName;
  final String? detectedAt;

  const PriceAnomalyDto({
    this.productId,
    this.inventoryItemId,
    required this.productName,
    this.category,
    required this.currentPrice,
    required this.previousPrice,
    required this.percentageChange,
    required this.unit,
    required this.alertType,
    this.storeName,
    this.detectedAt,
  });

  factory PriceAnomalyDto.fromJson(Map<String, dynamic> json) {
    return PriceAnomalyDto(
      productId: json['productId']?.toString(),
      inventoryItemId: json['inventoryItemId']?.toString(),
      productName: json['productName']?.toString() ?? 'Item',
      category: json['category']?.toString(),
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
      previousPrice: (json['previousPrice'] as num?)?.toDouble() ?? 0.0,
      percentageChange: (json['percentageChange'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit']?.toString() ?? 'pcs',
      alertType: json['alertType']?.toString() ?? 'PRICE_HIKE',
      storeName: json['storeName']?.toString(),
      detectedAt: json['detectedAt']?.toString(),
    );
  }
}

@immutable
class MonthlyExpenseReportDto {
  final int year;
  final int month;
  final String? monthName;
  final double totalSpend;
  final double previousMonthSpend;
  final double momPercentageChange;
  final int totalBills;
  final int totalItemsPurchased;
  final double averageBillAmount;
  final List<CategoryExpenseDto> categoryBreakdown;
  final List<TopRetailerDto> topRetailers;
  final List<PriceAnomalyDto> priceAnomalies;
  final List<BillingPeriodDto> availablePeriods;
  final List<MonthlyBillSummaryDto> bills;

  const MonthlyExpenseReportDto({
    required this.year,
    required this.month,
    this.monthName,
    required this.totalSpend,
    required this.previousMonthSpend,
    required this.momPercentageChange,
    required this.totalBills,
    required this.totalItemsPurchased,
    this.averageBillAmount = 0.0,
    this.categoryBreakdown = const [],
    this.topRetailers = const [],
    this.priceAnomalies = const [],
    this.availablePeriods = const [],
    this.bills = const [],
  });

  factory MonthlyExpenseReportDto.fromJson(Map<String, dynamic> json) {
    final billsCount = json['totalBills'] as int? ??
        (json['billsCount'] as num?)?.toInt() ??
        0;
    final spend = (json['totalSpend'] as num?)?.toDouble() ?? 0.0;
    final avg = (json['averageBillAmount'] as num?)?.toDouble() ??
        (billsCount > 0 ? spend / billsCount : 0.0);

    return MonthlyExpenseReportDto(
      year: json['year'] as int? ?? DateTime.now().year,
      month: json['month'] as int? ?? DateTime.now().month,
      monthName: json['monthName']?.toString(),
      totalSpend: spend,
      previousMonthSpend: (json['previousMonthSpend'] as num?)?.toDouble() ?? 0.0,
      momPercentageChange: (json['momPercentageChange'] as num?)?.toDouble() ??
          (json['spendingTrendPercent'] as num?)?.toDouble() ??
          0.0,
      totalBills: billsCount,
      totalItemsPurchased: json['totalItemsPurchased'] as int? ??
          (json['itemsPurchasedCount'] as num?)?.toInt() ??
          0,
      averageBillAmount: avg,
      categoryBreakdown: ((json['categoryBreakdown'] ?? json['categories']) as List<dynamic>?)
              ?.map((e) => CategoryExpenseDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      topRetailers: ((json['topRetailers'] ?? json['shopBreakdown']) as List<dynamic>?)
              ?.map((e) => TopRetailerDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      priceAnomalies: (json['priceAnomalies'] as List<dynamic>?)
              ?.map((e) => PriceAnomalyDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      availablePeriods: (json['availablePeriods'] as List<dynamic>?)
              ?.map((e) => BillingPeriodDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      bills: (json['bills'] as List<dynamic>?)
              ?.map((e) => MonthlyBillSummaryDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

@immutable
class MonthlyBillSummaryDto {
  final String id;
  final String shopName;
  final String billNumber;
  final String? billDate;
  final DateTime? createdAt;
  final double totalAmount;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final int itemsCount;
  final String status;
  final String source;
  final List<BillItemSummaryDto> items;

  const MonthlyBillSummaryDto({
    required this.id,
    required this.shopName,
    this.billNumber = 'N/A',
    this.billDate,
    this.createdAt,
    required this.totalAmount,
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.itemsCount = 0,
    this.status = 'CONFIRMED',
    this.source = 'AI_SCANNED',
    this.items = const [],
  });

  factory MonthlyBillSummaryDto.fromJson(Map<String, dynamic> json) {
    return MonthlyBillSummaryDto(
      id: json['id']?.toString() ?? '',
      shopName: json['shopName']?.toString() ?? 'Retail Store',
      billNumber: json['billNumber']?.toString() ?? 'N/A',
      billDate: json['billDate']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())?.toLocal()
          : null,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      itemsCount: (json['itemsCount'] as num?)?.toInt() ??
          ((json['items'] as List<dynamic>?)?.length ?? 0),
      status: json['status']?.toString() ?? 'CONFIRMED',
      source: json['source']?.toString() ?? 'AI_SCANNED',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => BillItemSummaryDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

@immutable
class BillItemSummaryDto {
  final String? id;
  final String itemName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double finalPrice;
  final String? category;

  const BillItemSummaryDto({
    this.id,
    required this.itemName,
    this.quantity = 1.0,
    this.unit = 'pcs',
    this.unitPrice = 0.0,
    this.finalPrice = 0.0,
    this.category,
  });

  factory BillItemSummaryDto.fromJson(Map<String, dynamic> json) {
    return BillItemSummaryDto(
      id: json['id']?.toString(),
      itemName: json['itemName']?.toString() ?? 'Item',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit']?.toString() ?? 'pcs',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (json['finalPrice'] as num?)?.toDouble() ?? 0.0,
      category: json['category']?.toString(),
    );
  }
}

@immutable
class BillingPeriodDto {
  final int year;
  final int month;
  final String? monthName;
  final int billsCount;
  final double totalSpend;

  const BillingPeriodDto({
    required this.year,
    required this.month,
    this.monthName,
    required this.billsCount,
    required this.totalSpend,
  });

  factory BillingPeriodDto.fromJson(Map<String, dynamic> json) {
    return BillingPeriodDto(
      year: json['year'] as int? ?? DateTime.now().year,
      month: json['month'] as int? ?? DateTime.now().month,
      monthName: json['monthName']?.toString(),
      billsCount: json['billsCount'] as int? ?? 0,
      totalSpend: (json['totalSpend'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

@immutable
class StoreComparisonDto {
  final String storeName;
  final double totalSpent;
  final int visitCount;
  final double avgSpendPerVisit;
  final double percentageOfTotal;
  final String? firstSeen;
  final String? lastSeen;

  const StoreComparisonDto({
    required this.storeName,
    required this.totalSpent,
    required this.visitCount,
    required this.avgSpendPerVisit,
    this.percentageOfTotal = 0.0,
    this.firstSeen,
    this.lastSeen,
  });

  factory StoreComparisonDto.fromJson(Map<String, dynamic> json) {
    final visits = json['visitCount'] as int? ?? (json['billsCount'] as num?)?.toInt() ?? 0;
    final total = (json['totalSpent'] as num?)?.toDouble() ?? (json['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final avg = (json['avgSpendPerVisit'] as num?)?.toDouble() ?? (visits > 0 ? total / visits : 0.0);
    final pct = (json['percentageOfTotal'] as num?)?.toDouble() ?? (json['spendingPercentage'] as num?)?.toDouble() ?? 0.0;

    return StoreComparisonDto(
      storeName: json['storeName']?.toString() ?? json['shopName']?.toString() ?? 'Retail Store',
      totalSpent: total,
      visitCount: visits,
      avgSpendPerVisit: avg,
      percentageOfTotal: pct,
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
  final bool isHigherThanUsual;

  const PricePointDto({
    required this.purchaseDate,
    required this.storeName,
    required this.unitPrice,
    required this.standardUnitPrice,
    required this.quantity,
    required this.unit,
    this.isHigherThanUsual = false,
  });

  factory PricePointDto.fromJson(Map<String, dynamic> json) {
    return PricePointDto(
      purchaseDate: json['purchaseDate']?.toString() ?? '',
      storeName: json['storeName']?.toString() ?? 'Store',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      standardUnitPrice: (json['standardUnitPrice'] as num?)?.toDouble() ??
          (json['unitPrice'] as num?)?.toDouble() ??
          0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit']?.toString() ?? 'pcs',
      isHigherThanUsual: json['isHigherThanUsual'] as bool? ?? false,
    );
  }
}

@immutable
class StorePriceComparisonItemDto {
  final String storeName;
  final double averagePrice;
  final double minPrice;
  final double maxPrice;
  final int purchaseCount;

  const StorePriceComparisonItemDto({
    required this.storeName,
    required this.averagePrice,
    required this.minPrice,
    required this.maxPrice,
    required this.purchaseCount,
  });

  factory StorePriceComparisonItemDto.fromJson(Map<String, dynamic> json) {
    return StorePriceComparisonItemDto(
      storeName: json['storeName']?.toString() ?? 'Store',
      averagePrice: (json['averagePrice'] as num?)?.toDouble() ?? 0.0,
      minPrice: (json['minPrice'] as num?)?.toDouble() ?? 0.0,
      maxPrice: (json['maxPrice'] as num?)?.toDouble() ?? 0.0,
      purchaseCount: (json['purchaseCount'] as num?)?.toInt() ?? 1,
    );
  }
}

@immutable
class ProductPriceHistoryDto {
  final String productId;
  final String? inventoryItemId;
  final String productName;
  final double lowestPrice;
  final double highestPrice;
  final double currentPrice;
  final double averagePrice;
  final double previousPrice;
  final double priceChangePercent;
  final String unit;
  final String? recommendedStore;
  final bool isHigherThanUsual;
  final List<PricePointDto> pricePoints;
  final List<StorePriceComparisonItemDto> storeComparisons;

  const ProductPriceHistoryDto({
    required this.productId,
    this.inventoryItemId,
    required this.productName,
    required this.lowestPrice,
    required this.highestPrice,
    required this.currentPrice,
    this.averagePrice = 0.0,
    this.previousPrice = 0.0,
    this.priceChangePercent = 0.0,
    this.unit = 'pcs',
    this.recommendedStore,
    this.isHigherThanUsual = false,
    this.pricePoints = const [],
    this.storeComparisons = const [],
  });

  factory ProductPriceHistoryDto.fromJson(Map<String, dynamic> json) {
    final pointsList = (json['pricePoints'] ?? json['recentPurchases']) as List<dynamic>?;
    final storesList = (json['storeComparisons']) as List<dynamic>?;

    return ProductPriceHistoryDto(
      productId: json['productId']?.toString() ?? '',
      inventoryItemId: json['inventoryItemId']?.toString(),
      productName: json['productName']?.toString() ?? 'Product',
      lowestPrice: (json['lowestPrice'] as num?)?.toDouble() ??
          (json['minPrice'] as num?)?.toDouble() ??
          0.0,
      highestPrice: (json['highestPrice'] as num?)?.toDouble() ??
          (json['maxPrice'] as num?)?.toDouble() ??
          0.0,
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
      averagePrice: (json['averagePrice'] as num?)?.toDouble() ?? 0.0,
      previousPrice: (json['previousPrice'] as num?)?.toDouble() ?? 0.0,
      priceChangePercent: (json['priceChangePercent'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit']?.toString() ?? 'pcs',
      recommendedStore: json['recommendedStore']?.toString(),
      isHigherThanUsual: json['isHigherThanUsual'] as bool? ?? false,
      pricePoints: pointsList
              ?.map((e) => PricePointDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      storeComparisons: storesList
              ?.map((e) => StorePriceComparisonItemDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
