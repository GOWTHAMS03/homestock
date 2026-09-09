import 'package:flutter/material.dart';
import '../constants/household_staples.dart';
import '../constants/product_icon_mapper.dart';

/// Normalized product model representing an item in the master catalog.
class Product {
  final String id;
  final String name;
  final String? tamilName;
  final String category;
  final String? subCategory;
  final String? productType;
  final String defaultUnit;
  final String soldBy;
  final String storageLocation;
  final double minimumQuantity;
  final List<double> customQuantities;
  final List<String> commonNames;
  final List<String> aliases;
  final List<String> brands;
  final bool barcodeSupport;
  final String? barcodeType;
  final List<String> barcodes;
  final bool isLoose;
  final bool isPackaged;
  final String iconKey;

  const Product({
    required this.id,
    required this.name,
    this.tamilName,
    required this.category,
    this.subCategory,
    this.productType,
    required this.defaultUnit,
    required this.soldBy,
    this.storageLocation = 'Pantry Shelf',
    this.minimumQuantity = 1.0,
    this.customQuantities = const [1.0],
    this.commonNames = const [],
    this.aliases = const [],
    this.brands = const [],
    this.barcodeSupport = true,
    this.barcodeType,
    this.barcodes = const [],
    this.isLoose = false,
    this.isPackaged = true,
    this.iconKey = 'staple',
  });

  /// User-facing display title including authentic Tamil script when available
  String get displayName => tamilName != null && tamilName!.isNotEmpty
      ? '$name ($tamilName)'
      : name;

  /// Material icon resolver based on iconKey
  IconData get iconData => ProductIconMapper.getIcon(iconKey);

  /// Emoji representation
  String get emoji => ProductIconMapper.getEmoji(iconKey);

  /// Backward-compatible bridge to [HouseholdStaple]
  HouseholdStaple toHouseholdStaple() {
    return HouseholdStaple(
      name: name,
      tamilName: tamilName,
      defaultQty: minimumQuantity,
      defaultUnit: defaultUnit,
      emoji: emoji,
      icon: iconData,
      category: category,
      subCategory: subCategory,
      storageLocation: storageLocation,
      minimumQuantity: minimumQuantity,
      customQuantities: customQuantities,
      customBrands: brands,
      commonNames: commonNames.isNotEmpty ? commonNames : aliases,
      isLoose: isLoose,
      isPackaged: isPackaged,
      barcodeSupport: barcodeSupport,
      barcodeType: barcodeType,
      soldBy: soldBy,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      tamilName: json['tamilName'] as String?,
      category: json['category'] as String? ?? 'General',
      subCategory: json['subCategory'] as String?,
      productType: json['productType'] as String?,
      defaultUnit: json['defaultUnit'] as String? ?? 'piece',
      soldBy: json['soldBy'] as String? ?? 'piece',
      storageLocation: json['storageLocation'] as String? ?? 'Pantry Shelf',
      minimumQuantity: (json['minimumQuantity'] as num?)?.toDouble() ?? 1.0,
      customQuantities: (json['customQuantities'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [1.0],
      commonNames: (json['commonNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      aliases: (json['aliases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      brands: (json['brands'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      barcodeSupport: json['barcodeSupport'] as bool? ?? true,
      barcodeType: json['barcodeType'] as String?,
      barcodes: (json['barcodes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isLoose: json['isLoose'] as bool? ?? false,
      isPackaged: json['isPackaged'] as bool? ?? true,
      iconKey: json['iconKey'] as String? ?? 'staple',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tamilName': tamilName,
      'category': category,
      'subCategory': subCategory,
      'productType': productType,
      'defaultUnit': defaultUnit,
      'soldBy': soldBy,
      'storageLocation': storageLocation,
      'minimumQuantity': minimumQuantity,
      'customQuantities': customQuantities,
      'commonNames': commonNames,
      'aliases': aliases,
      'brands': brands,
      'barcodeSupport': barcodeSupport,
      'barcodeType': barcodeType,
      'barcodes': barcodes,
      'isLoose': isLoose,
      'isPackaged': isPackaged,
      'iconKey': iconKey,
    };
  }
}

