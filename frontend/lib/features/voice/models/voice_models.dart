enum VoiceIntentType {
  addShoppingItem,
  removeShoppingItem,
  completeShoppingItem,
  updateStock,
  stockIn,
  stockOut,
  getItemStatus,
  getShoppingList,
  getLowStockItems,
  getExpiringItems,
  searchInventory,
  addInventoryItem,
  updateInventoryItem,
  openShoppingList,
  openInventory,
  openAnalytics,
  smartPriceCheck,
  unknown;

  static VoiceIntentType fromString(String? val) {
    if (val == null) return VoiceIntentType.unknown;
    switch (val.toUpperCase()) {
      case 'ADD_SHOPPING_ITEM':
        return VoiceIntentType.addShoppingItem;
      case 'REMOVE_SHOPPING_ITEM':
        return VoiceIntentType.removeShoppingItem;
      case 'COMPLETE_SHOPPING_ITEM':
        return VoiceIntentType.completeShoppingItem;
      case 'UPDATE_STOCK':
        return VoiceIntentType.updateStock;
      case 'STOCK_IN':
        return VoiceIntentType.stockIn;
      case 'STOCK_OUT':
        return VoiceIntentType.stockOut;
      case 'GET_ITEM_STATUS':
        return VoiceIntentType.getItemStatus;
      case 'GET_SHOPPING_LIST':
        return VoiceIntentType.getShoppingList;
      case 'GET_LOW_STOCK_ITEMS':
        return VoiceIntentType.getLowStockItems;
      case 'GET_EXPIRING_ITEMS':
        return VoiceIntentType.getExpiringItems;
      case 'SEARCH_INVENTORY':
        return VoiceIntentType.searchInventory;
      case 'ADD_INVENTORY_ITEM':
        return VoiceIntentType.addInventoryItem;
      case 'UPDATE_INVENTORY_ITEM':
        return VoiceIntentType.updateInventoryItem;
      case 'OPEN_SHOPPING_LIST':
        return VoiceIntentType.openShoppingList;
      case 'OPEN_INVENTORY':
        return VoiceIntentType.openInventory;
      case 'OPEN_ANALYTICS':
        return VoiceIntentType.openAnalytics;
      case 'SMART_PRICE_CHECK':
        return VoiceIntentType.smartPriceCheck;
      default:
        return VoiceIntentType.unknown;
    }
  }

  String toServerString() {
    switch (this) {
      case VoiceIntentType.addShoppingItem:
        return 'ADD_SHOPPING_ITEM';
      case VoiceIntentType.removeShoppingItem:
        return 'REMOVE_SHOPPING_ITEM';
      case VoiceIntentType.completeShoppingItem:
        return 'COMPLETE_SHOPPING_ITEM';
      case VoiceIntentType.updateStock:
        return 'UPDATE_STOCK';
      case VoiceIntentType.stockIn:
        return 'STOCK_IN';
      case VoiceIntentType.stockOut:
        return 'STOCK_OUT';
      case VoiceIntentType.getItemStatus:
        return 'GET_ITEM_STATUS';
      case VoiceIntentType.getShoppingList:
        return 'GET_SHOPPING_LIST';
      case VoiceIntentType.getLowStockItems:
        return 'GET_LOW_STOCK_ITEMS';
      case VoiceIntentType.getExpiringItems:
        return 'GET_EXPIRING_ITEMS';
      case VoiceIntentType.searchInventory:
        return 'SEARCH_INVENTORY';
      case VoiceIntentType.addInventoryItem:
        return 'ADD_INVENTORY_ITEM';
      case VoiceIntentType.updateInventoryItem:
        return 'UPDATE_INVENTORY_ITEM';
      case VoiceIntentType.openShoppingList:
        return 'OPEN_SHOPPING_LIST';
      case VoiceIntentType.openInventory:
        return 'OPEN_INVENTORY';
      case VoiceIntentType.openAnalytics:
        return 'OPEN_ANALYTICS';
      case VoiceIntentType.smartPriceCheck:
        return 'SMART_PRICE_CHECK';
      case VoiceIntentType.unknown:
        return 'UNKNOWN';
    }
  }

  String get displayName {
    switch (this) {
      case VoiceIntentType.addShoppingItem:
        return 'Add to Shopping List';
      case VoiceIntentType.removeShoppingItem:
        return 'Remove from Shopping List';
      case VoiceIntentType.completeShoppingItem:
        return 'Mark Item as Bought';
      case VoiceIntentType.updateStock:
        return 'Update Stock';
      case VoiceIntentType.stockIn:
        return 'Add Stock';
      case VoiceIntentType.stockOut:
        return 'Use / Deduct Stock';
      case VoiceIntentType.getItemStatus:
        return 'Check Item Status';
      case VoiceIntentType.getShoppingList:
        return 'View Shopping List';
      case VoiceIntentType.getLowStockItems:
        return 'Check Low Stock';
      case VoiceIntentType.getExpiringItems:
        return 'Check Expiring Items';
      case VoiceIntentType.searchInventory:
        return 'Search Inventory';
      case VoiceIntentType.addInventoryItem:
        return 'New Inventory Item';
      case VoiceIntentType.updateInventoryItem:
        return 'Update Inventory Item';
      case VoiceIntentType.openShoppingList:
        return 'Open Shopping List';
      case VoiceIntentType.openInventory:
        return 'Open Inventory';
      case VoiceIntentType.openAnalytics:
        return 'Open Analytics';
      case VoiceIntentType.smartPriceCheck:
        return 'Check Best Prices';
      case VoiceIntentType.unknown:
        return 'Voice Command';
    }
  }
}

class TranscriptionResult {
  final String transcript;
  final String language;
  final double confidence;
  final int processingTimeMs;

  const TranscriptionResult({
    required this.transcript,
    this.language = 'auto',
    this.confidence = 1.0,
    this.processingTimeMs = 0,
  });

  factory TranscriptionResult.fromJson(Map<String, dynamic> json) {
    return TranscriptionResult(
      transcript: json['transcript'] as String? ?? '',
      language: json['language'] as String? ?? 'auto',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      processingTimeMs: (json['processingTimeMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class VoiceEntities {
  final String? itemName;
  final num? quantity;
  final String? unit;
  final String? brand;
  final num? price;
  final String? category;
  final String? store;
  final String? matchedInventoryItemId;
  final String? matchedInventoryItemName;

  const VoiceEntities({
    this.itemName,
    this.quantity,
    this.unit,
    this.brand,
    this.price,
    this.category,
    this.store,
    this.matchedInventoryItemId,
    this.matchedInventoryItemName,
  });

  factory VoiceEntities.fromJson(Map<String, dynamic> json) {
    return VoiceEntities(
      itemName: json['itemName'] as String?,
      quantity: json['quantity'] as num?,
      unit: json['unit'] as String?,
      brand: json['brand'] as String?,
      price: json['price'] as num?,
      category: json['category'] as String?,
      store: json['store'] as String?,
      matchedInventoryItemId: json['matchedInventoryItemId'] as String?,
      matchedInventoryItemName: json['matchedInventoryItemName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (itemName != null) 'itemName': itemName,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (brand != null) 'brand': brand,
      if (price != null) 'price': price,
      if (category != null) 'category': category,
      if (store != null) 'store': store,
      if (matchedInventoryItemId != null) 'matchedInventoryItemId': matchedInventoryItemId,
      if (matchedInventoryItemName != null) 'matchedInventoryItemName': matchedInventoryItemName,
    };
  }

  VoiceEntities copyWith({
    String? itemName,
    num? quantity,
    String? unit,
    String? brand,
    num? price,
    String? category,
    String? store,
    String? matchedInventoryItemId,
    String? matchedInventoryItemName,
  }) {
    return VoiceEntities(
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      category: category ?? this.category,
      store: store ?? this.store,
      matchedInventoryItemId: matchedInventoryItemId ?? this.matchedInventoryItemId,
      matchedInventoryItemName: matchedInventoryItemName ?? this.matchedInventoryItemName,
    );
  }
}

class DisambiguationOption {
  final String id;
  final String label;
  final String? subLabel;
  final String? action;

  const DisambiguationOption({
    required this.id,
    required this.label,
    this.subLabel,
    this.action,
  });

  factory DisambiguationOption.fromJson(Map<String, dynamic> json) {
    return DisambiguationOption(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      subLabel: json['subLabel'] as String?,
      action: json['action'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      if (subLabel != null) 'subLabel': subLabel,
      if (action != null) 'action': action,
    };
  }
}

class VoiceCommandResult {
  final String transcript;
  final VoiceIntentType intent;
  final double confidence;
  final VoiceEntities? entities;
  final bool requiresConfirmation;
  final String message;
  final List<DisambiguationOption> disambiguationOptions;

  const VoiceCommandResult({
    required this.transcript,
    required this.intent,
    this.confidence = 1.0,
    this.entities,
    this.requiresConfirmation = false,
    required this.message,
    this.disambiguationOptions = const [],
  });

  factory VoiceCommandResult.fromJson(Map<String, dynamic> json) {
    return VoiceCommandResult(
      transcript: json['transcript'] as String? ?? '',
      intent: VoiceIntentType.fromString(json['intent'] as String?),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      entities: json['entities'] != null ? VoiceEntities.fromJson(json['entities'] as Map<String, dynamic>) : null,
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      disambiguationOptions: (json['disambiguationOptions'] as List<dynamic>?)
              ?.map((e) => DisambiguationOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transcript': transcript,
      'intent': intent.toServerString(),
      'confidence': confidence,
      if (entities != null) 'entities': entities!.toJson(),
      'requiresConfirmation': requiresConfirmation,
      'message': message,
      'disambiguationOptions': disambiguationOptions.map((o) => o.toJson()).toList(),
    };
  }

  VoiceCommandResult copyWith({
    String? transcript,
    VoiceIntentType? intent,
    double? confidence,
    VoiceEntities? entities,
    bool? requiresConfirmation,
    String? message,
    List<DisambiguationOption>? disambiguationOptions,
  }) {
    return VoiceCommandResult(
      transcript: transcript ?? this.transcript,
      intent: intent ?? this.intent,
      confidence: confidence ?? this.confidence,
      entities: entities ?? this.entities,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      message: message ?? this.message,
      disambiguationOptions: disambiguationOptions ?? this.disambiguationOptions,
    );
  }
}

class ExecuteCommandRequest {
  final String homeId;
  final VoiceCommandResult commandResult;
  final bool confirmed;
  final String? selectedOptionId;

  const ExecuteCommandRequest({
    required this.homeId,
    required this.commandResult,
    this.confirmed = true,
    this.selectedOptionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'homeId': homeId,
      'commandResult': commandResult.toJson(),
      'confirmed': confirmed,
      if (selectedOptionId != null) 'selectedOptionId': selectedOptionId,
    };
  }
}

class ExecuteCommandResponse {
  final bool success;
  final VoiceIntentType intent;
  final String message;
  final dynamic data;
  final Map<String, dynamic>? navigation;

  const ExecuteCommandResponse({
    required this.success,
    required this.intent,
    required this.message,
    this.data,
    this.navigation,
  });

  factory ExecuteCommandResponse.fromJson(Map<String, dynamic> json) {
    return ExecuteCommandResponse(
      success: json['success'] as bool? ?? false,
      intent: VoiceIntentType.fromString(json['intent'] as String?),
      message: json['message'] as String? ?? '',
      data: json['data'],
      navigation: json['navigation'] as Map<String, dynamic>?,
    );
  }
}
