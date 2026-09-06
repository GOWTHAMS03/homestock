class StoreModel {
  final String id;
  final String name;
  final String? location;

  StoreModel({required this.id, required this.name, this.location});

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: json['location'],
    );
  }
}

class PurchaseItemModel {
  final String id;
  final String? inventoryItemId;
  final String itemName;
  final String? categoryName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final double totalPrice;

  PurchaseItemModel({
    required this.id,
    this.inventoryItemId,
    required this.itemName,
    this.categoryName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseItemModel(
      id: json['id'] ?? '',
      inventoryItemId: json['inventoryItemId'],
      itemName: json['itemName'] ?? '',
      categoryName: json['categoryName'],
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] ?? 'pcs',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PurchaseModel {
  final String id;
  final String? storeName;
  final String recordedByName;
  final String purchaseDate;
  final double totalAmount;
  final String currency;
  final String? notes;
  final List<PurchaseItemModel> items;

  PurchaseModel({
    required this.id,
    this.storeName,
    required this.recordedByName,
    required this.purchaseDate,
    required this.totalAmount,
    required this.currency,
    this.notes,
    required this.items,
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return PurchaseModel(
      id: json['id'] ?? '',
      storeName: json['storeName'],
      recordedByName: json['recordedByName'] ?? '',
      purchaseDate: json['purchaseDate'] ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
      notes: json['notes'],
      items: rawItems.map((i) => PurchaseItemModel.fromJson(i)).toList(),
    );
  }
}
