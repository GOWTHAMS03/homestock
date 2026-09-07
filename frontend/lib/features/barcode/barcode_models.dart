import 'package:flutter/foundation.dart';

enum BarcodeFormatType {
  ean13,
  ean8,
  upcA,
  upcE,
  code128,
  code39,
  itf,
  qrCode,
  unknown;

  static BarcodeFormatType fromString(String? type) {
    if (type == null) return BarcodeFormatType.unknown;
    switch (type.toUpperCase().replaceAll('-', '_')) {
      case 'EAN_13':
      case 'EAN13':
        return BarcodeFormatType.ean13;
      case 'EAN_8':
      case 'EAN8':
        return BarcodeFormatType.ean8;
      case 'UPC_A':
      case 'UPCA':
        return BarcodeFormatType.upcA;
      case 'UPC_E':
      case 'UPCE':
        return BarcodeFormatType.upcE;
      case 'CODE_128':
      case 'CODE128':
        return BarcodeFormatType.code128;
      case 'CODE_39':
      case 'CODE39':
        return BarcodeFormatType.code39;
      case 'ITF':
      case 'ITF_14':
        return BarcodeFormatType.itf;
      case 'QR_CODE':
      case 'QRCODE':
        return BarcodeFormatType.qrCode;
      default:
        return BarcodeFormatType.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case BarcodeFormatType.ean13:
        return 'EAN-13';
      case BarcodeFormatType.ean8:
        return 'EAN-8';
      case BarcodeFormatType.upcA:
        return 'UPC-A';
      case BarcodeFormatType.upcE:
        return 'UPC-E';
      case BarcodeFormatType.code128:
        return 'Code 128';
      case BarcodeFormatType.code39:
        return 'Code 39';
      case BarcodeFormatType.itf:
        return 'ITF';
      case BarcodeFormatType.qrCode:
        return 'QR Code';
      case BarcodeFormatType.unknown:
        return 'Barcode';
    }
  }
}

@immutable
class ProductCatalogModel {
  final String? id;
  final String barcode;
  final String barcodeType;
  final String name;
  final String normalizedName;
  final String? brand;
  final String? categoryId;
  final String categoryName;
  final double? packageSize;
  final String unit;
  final String? imageUrl;
  final String source;

  const ProductCatalogModel({
    this.id,
    required this.barcode,
    this.barcodeType = 'EAN_13',
    required this.name,
    required this.normalizedName,
    this.brand,
    this.categoryId,
    this.categoryName = 'General',
    this.packageSize,
    this.unit = 'pcs',
    this.imageUrl,
    this.source = 'LOCAL',
  });

  factory ProductCatalogModel.fromJson(Map<String, dynamic> json) {
    return ProductCatalogModel(
      id: json['id'] as String?,
      barcode: json['barcode'] as String? ?? '',
      barcodeType: json['barcodeType'] as String? ?? 'EAN_13',
      name: json['name'] as String? ?? '',
      normalizedName: json['normalizedName'] as String? ?? '',
      brand: json['brand'] as String?,
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String? ?? 'General',
      packageSize: (json['packageSize'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? 'pcs',
      imageUrl: json['imageUrl'] as String?,
      source: json['source'] as String? ?? 'ONLINE',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'barcode': barcode,
        'barcodeType': barcodeType,
        'name': name,
        'normalizedName': normalizedName,
        'brand': brand,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'packageSize': packageSize,
        'unit': unit,
        'imageUrl': imageUrl,
        'source': source,
      };
}

@immutable
class ExistingInventoryContext {
  final String id;
  final String name;
  final double currentQuantity;
  final double minimumQuantity;
  final String unit;
  final String? storageLocation;
  final String? expiryDate;

  const ExistingInventoryContext({
    required this.id,
    required this.name,
    required this.currentQuantity,
    required this.minimumQuantity,
    required this.unit,
    this.storageLocation,
    this.expiryDate,
  });

  factory ExistingInventoryContext.fromJson(Map<String, dynamic> json) {
    return ExistingInventoryContext(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      currentQuantity: (json['currentQuantity'] as num?)?.toDouble() ?? 0.0,
      minimumQuantity: (json['minimumQuantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] as String? ?? 'pcs',
      storageLocation: json['storageLocation'] as String?,
      expiryDate: json['expiryDate'] as String?,
    );
  }
}

@immutable
class ExistingShoppingContext {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final bool isCompleted;

  const ExistingShoppingContext({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.isCompleted = false,
  });

  factory ExistingShoppingContext.fromJson(Map<String, dynamic> json) {
    return ExistingShoppingContext(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] as String? ?? 'pcs',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

@immutable
class BarcodeLookupResult {
  final bool found;
  final String barcode;
  final String barcodeType;
  final ProductCatalogModel? product;
  final ExistingInventoryContext? existingInventory;
  final ExistingShoppingContext? existingShopping;
  final bool isFromLocalCache;

  const BarcodeLookupResult({
    required this.found,
    required this.barcode,
    required this.barcodeType,
    this.product,
    this.existingInventory,
    this.existingShopping,
    this.isFromLocalCache = false,
  });

  factory BarcodeLookupResult.fromJson(Map<String, dynamic> json, {bool isFromCache = false}) {
    return BarcodeLookupResult(
      found: json['found'] as bool? ?? false,
      barcode: json['barcode'] as String? ?? '',
      barcodeType: json['barcodeType'] as String? ?? 'EAN_13',
      product: json['product'] != null
          ? ProductCatalogModel.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      existingInventory: (json['existingInventoryItem'] ?? json['existingInventory']) != null
          ? ExistingInventoryContext.fromJson(
              (json['existingInventoryItem'] ?? json['existingInventory']) as Map<String, dynamic>)
          : null,
      existingShopping: (json['existingShoppingListItem'] ?? json['existingShopping']) != null
          ? ExistingShoppingContext.fromJson(
              (json['existingShoppingListItem'] ?? json['existingShopping']) as Map<String, dynamic>)
          : null,
      isFromLocalCache: isFromCache,
    );
  }
}

/// Item in a running Quick Scan shopping session
@immutable
class QuickScanSessionItem {
  final String barcode;
  final String name;
  final String? brand;
  final double quantity;
  final String unit;
  final double? unitPrice;
  final String? existingInventoryItemId;

  const QuickScanSessionItem({
    required this.barcode,
    required this.name,
    this.brand,
    this.quantity = 1.0,
    this.unit = 'pcs',
    this.unitPrice,
    this.existingInventoryItemId,
  });

  QuickScanSessionItem copyWith({
    double? quantity,
    double? unitPrice,
  }) {
    return QuickScanSessionItem(
      barcode: barcode,
      name: name,
      brand: brand,
      quantity: quantity ?? this.quantity,
      unit: unit,
      unitPrice: unitPrice ?? this.unitPrice,
      existingInventoryItemId: existingInventoryItemId,
    );
  }
}
