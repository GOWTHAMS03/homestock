/// Represents a single sync operation queued for server synchronization.
class SyncOperation {
  final String operationId;
  final String operationType;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final String homeId;

  const SyncOperation({
    required this.operationId,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    required this.homeId,
  });

  Map<String, dynamic> toJson() => {
        'operationId': operationId,
        'operationType': operationType,
        'entityType': entityType,
        'entityId': entityId,
        'payload': payload,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'homeId': homeId,
      };

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      operationId: json['operationId'] as String,
      operationType: json['operationType'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      payload: json['payload'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      homeId: json['homeId'] as String? ?? '',
    );
  }
}

/// Operation types for sync queue
class SyncOperationType {
  SyncOperationType._();

  // Inventory
  static const String createItem = 'CREATE_ITEM';
  static const String updateItem = 'UPDATE_ITEM';
  static const String deleteItem = 'DELETE_ITEM';
  static const String stockIn = 'STOCK_IN';
  static const String stockOut = 'STOCK_OUT';
  static const String adjustment = 'ADJUSTMENT';

  // Shopping
  static const String addShoppingItem = 'ADD_SHOPPING_ITEM';
  static const String toggleShoppingItem = 'TOGGLE_SHOPPING_ITEM';
  static const String deleteShoppingItem = 'DELETE_SHOPPING_ITEM';
  static const String clearCompletedShopping = 'CLEAR_COMPLETED_SHOPPING';

  // Purchases
  static const String recordPurchase = 'RECORD_PURCHASE';

  // Stores
  static const String createStore = 'CREATE_STORE';

  // Categories
  static const String createCategory = 'CREATE_CATEGORY';
}

/// Entity types for sync queue
class SyncEntityType {
  SyncEntityType._();

  static const String inventoryItem = 'INVENTORY_ITEM';
  static const String stockTransaction = 'STOCK_TRANSACTION';
  static const String shoppingListItem = 'SHOPPING_LIST_ITEM';
  static const String shoppingList = 'SHOPPING_LIST';
  static const String purchase = 'PURCHASE';
  static const String store = 'STORE';
  static const String category = 'CATEGORY';
}

/// Result status for each sync operation from the server
class SyncResultStatus {
  SyncResultStatus._();

  static const String synced = 'SYNCED';
  static const String alreadyProcessed = 'ALREADY_PROCESSED';
  static const String failed = 'FAILED';
  static const String conflict = 'CONFLICT';
}

/// Per-operation result from the server
class SyncOperationResult {
  final String operationId;
  final String status;
  final String? errorMessage;
  final Map<String, dynamic>? serverEntity;

  const SyncOperationResult({
    required this.operationId,
    required this.status,
    this.errorMessage,
    this.serverEntity,
  });

  factory SyncOperationResult.fromJson(Map<String, dynamic> json) {
    return SyncOperationResult(
      operationId: json['operationId'] as String,
      status: json['status'] as String,
      errorMessage: json['errorMessage'] as String?,
      serverEntity: json['serverEntity'] as Map<String, dynamic>?,
    );
  }

  bool get isSynced =>
      status == SyncResultStatus.synced ||
      status == SyncResultStatus.alreadyProcessed;
}

/// Batch sync response from server
class SyncPushResponse {
  final List<SyncOperationResult> results;

  const SyncPushResponse({required this.results});

  factory SyncPushResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List? ?? [];
    return SyncPushResponse(
      results: rawResults
          .map((r) => SyncOperationResult.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Incremental pull response from server
class SyncPullResponse {
  final List<Map<String, dynamic>> inventoryItems;
  final List<Map<String, dynamic>> stockTransactions;
  final List<Map<String, dynamic>> shoppingListItems;
  final List<Map<String, dynamic>> shoppingLists;
  final List<Map<String, dynamic>> purchases;
  final List<Map<String, dynamic>> purchaseItems;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> stores;
  final String serverTimestamp;

  const SyncPullResponse({
    this.inventoryItems = const [],
    this.stockTransactions = const [],
    this.shoppingListItems = const [],
    this.shoppingLists = const [],
    this.purchases = const [],
    this.purchaseItems = const [],
    this.categories = const [],
    this.stores = const [],
    required this.serverTimestamp,
  });

  factory SyncPullResponse.fromJson(Map<String, dynamic> json) {
    return SyncPullResponse(
      inventoryItems: _toMapList(json['inventoryItems']),
      stockTransactions: _toMapList(json['stockTransactions']),
      shoppingListItems: _toMapList(json['shoppingListItems']),
      shoppingLists: _toMapList(json['shoppingLists']),
      purchases: _toMapList(json['purchases']),
      purchaseItems: _toMapList(json['purchaseItems']),
      categories: _toMapList(json['categories']),
      stores: _toMapList(json['stores']),
      serverTimestamp: json['serverTimestamp'] as String? ??
          DateTime.now().toUtc().toIso8601String(),
    );
  }

  static List<Map<String, dynamic>> _toMapList(dynamic raw) {
    if (raw is! List) return [];
    return raw.cast<Map<String, dynamic>>();
  }

  bool get isEmpty =>
      inventoryItems.isEmpty &&
      stockTransactions.isEmpty &&
      shoppingListItems.isEmpty &&
      shoppingLists.isEmpty &&
      purchases.isEmpty &&
      purchaseItems.isEmpty &&
      categories.isEmpty &&
      stores.isEmpty;
}
