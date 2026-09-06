class CategorySpendingModel {
  final String categoryName;
  final double amount;

  CategorySpendingModel({required this.categoryName, required this.amount});

  factory CategorySpendingModel.fromJson(Map<String, dynamic> json) {
    return CategorySpendingModel(
      categoryName: json['categoryName'] ?? 'General',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StoreSpendingModel {
  final String storeName;
  final double amount;

  StoreSpendingModel({required this.storeName, required this.amount});

  factory StoreSpendingModel.fromJson(Map<String, dynamic> json) {
    return StoreSpendingModel(
      storeName: json['storeName'] ?? 'Direct',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TopItemModel {
  final String name;
  final double quantity;
  final int count;

  TopItemModel({required this.name, required this.quantity, required this.count});

  factory TopItemModel.fromJson(Map<String, dynamic> json) {
    return TopItemModel(
      name: json['name'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AnalyticsOverviewModel {
  final double monthlySpending;
  final String currency;
  final List<CategorySpendingModel> categorySpending;
  final List<StoreSpendingModel> storeSpending;
  final List<TopItemModel> mostPurchasedItems;
  final List<TopItemModel> mostConsumedItems;

  AnalyticsOverviewModel({
    required this.monthlySpending,
    required this.currency,
    required this.categorySpending,
    required this.storeSpending,
    required this.mostPurchasedItems,
    required this.mostConsumedItems,
  });

  factory AnalyticsOverviewModel.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categorySpending'] as List? ?? [];
    final rawStores = json['storeSpending'] as List? ?? [];
    final rawPurchased = json['mostPurchasedItems'] as List? ?? [];
    final rawConsumed = json['mostConsumedItems'] as List? ?? [];

    return AnalyticsOverviewModel(
      monthlySpending: (json['monthlySpending'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
      categorySpending: rawCats.map((c) => CategorySpendingModel.fromJson(c)).toList(),
      storeSpending: rawStores.map((s) => StoreSpendingModel.fromJson(s)).toList(),
      mostPurchasedItems: rawPurchased.map((p) => TopItemModel.fromJson(p)).toList(),
      mostConsumedItems: rawConsumed.map((c) => TopItemModel.fromJson(c)).toList(),
    );
  }
}
