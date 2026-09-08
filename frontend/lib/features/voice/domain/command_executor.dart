import '../../inventory/inventory_repository.dart';
import '../../shopping/shopping_repository.dart';
import '../models/command_result.dart';
import '../models/normalized_voice_command.dart';
import '../models/voice_models.dart' show VoiceIntentType;

/// Executes validated voice commands offline-first using local repositories and sync queue
class CommandExecutor {
  final ShoppingRepository _shoppingRepo;
  final InventoryRepository _inventoryRepo;

  CommandExecutor({
    required ShoppingRepository shoppingRepo,
    required InventoryRepository inventoryRepo,
  })  : _shoppingRepo = shoppingRepo,
        _inventoryRepo = inventoryRepo;

  Future<CommandExecutionResult> execute({
    required NormalizedVoiceCommand command,
    required String homeId,
    String? selectedOptionId,
  }) async {
    try {
      switch (command.intent) {
        case VoiceIntentType.addShoppingItem:
          return await _executeAddShoppingItem(command, homeId, selectedOptionId);

        case VoiceIntentType.removeShoppingItem:
          return await _executeRemoveShoppingItem(command, homeId);

        case VoiceIntentType.updateShoppingQuantity:
          return await _executeUpdateShoppingQuantity(command, homeId);

        case VoiceIntentType.completeShoppingItem:
          return await _executeCompleteShoppingItem(command, homeId);

        case VoiceIntentType.clearShoppingList:
          return await _executeClearShoppingList(command, homeId);

        case VoiceIntentType.stockIn:
          return await _executeStockIn(command, homeId, selectedOptionId);

        case VoiceIntentType.stockOut:
          return await _executeStockOut(command, homeId, selectedOptionId);

        case VoiceIntentType.updateStock:
          return await _executeUpdateStock(command, homeId, selectedOptionId);

        case VoiceIntentType.getItemStatus:
          return await _executeCheckStock(command, homeId);

        case VoiceIntentType.getShoppingList:
          return CommandExecutionResult.success(
            operationId: command.operationId,
            intent: command.intent,
            message: 'Here is your shopping list',
            navigationRoute: '/shopping',
            isOffline: command.isOffline,
          );

        case VoiceIntentType.getLowStockItems:
          return await _executeCheckLowStock(command, homeId);

        case VoiceIntentType.getOutOfStockItems:
          return await _executeCheckOutOfStock(command, homeId);

        case VoiceIntentType.getExpiringItems:
          return await _executeCheckExpiring(command, homeId);

        case VoiceIntentType.getPurchaseHistory:
          return CommandExecutionResult.success(
            operationId: command.operationId,
            intent: command.intent,
            message: 'Viewing purchase history',
            navigationRoute: '/analytics',
            isOffline: command.isOffline,
          );

        case VoiceIntentType.getSpending:
          return CommandExecutionResult.success(
            operationId: command.operationId,
            intent: command.intent,
            message: 'Viewing spending analytics',
            navigationRoute: '/analytics',
            isOffline: command.isOffline,
          );

        case VoiceIntentType.whatDoINeed:
          return CommandExecutionResult.success(
            operationId: command.operationId,
            intent: command.intent,
            message: 'Opening restock recommendations',
            navigationRoute: '/shopping',
            isOffline: command.isOffline,
          );

        case VoiceIntentType.openShoppingList:
          return CommandExecutionResult.success(
            operationId: command.operationId,
            intent: command.intent,
            message: 'Opening shopping list',
            navigationRoute: '/shopping',
            isOffline: command.isOffline,
          );

        case VoiceIntentType.openInventory:
          return CommandExecutionResult.success(
            operationId: command.operationId,
            intent: command.intent,
            message: 'Opening inventory',
            navigationRoute: '/inventory',
            isOffline: command.isOffline,
          );

        case VoiceIntentType.openAnalytics:
          return CommandExecutionResult.success(
            operationId: command.operationId,
            intent: command.intent,
            message: 'Opening analytics',
            navigationRoute: '/analytics',
            isOffline: command.isOffline,
          );

        case VoiceIntentType.startShoppingMode:
          return CommandExecutionResult.success(
            operationId: command.operationId,
            intent: command.intent,
            message: 'Starting in-store shopping mode',
            navigationRoute: '/shopping-mode',
            isOffline: command.isOffline,
          );

        case VoiceIntentType.smartPriceCheck:
          return CommandExecutionResult.success(
            operationId: command.operationId,
            intent: command.intent,
            message: 'Comparing prices for ${command.productName ?? 'item'}',
            navigationRoute: '/smart-shopping',
            isOffline: command.isOffline,
          );

        default:
          return CommandExecutionResult.failure(
            operationId: command.operationId,
            intent: command.intent,
            message: "I didn't recognize that command.",
            isOffline: command.isOffline,
          );
      }
    } catch (e) {
      return CommandExecutionResult.failure(
        operationId: command.operationId,
        intent: command.intent,
        message: "Failed to execute voice command: ${e.toString().replaceAll('Exception: ', '')}",
        isOffline: command.isOffline,
      );
    }
  }

  /// Adds item to shopping list, intelligently INCREMENTING if a duplicate active item exists!
  Future<CommandExecutionResult> _executeAddShoppingItem(
    NormalizedVoiceCommand command,
    String homeId,
    String? selectedOptionId,
  ) async {
    final list = await _shoppingRepo.getDefaultList(homeId);
    final listId = list?.id ?? (await _shoppingRepo.ensureDefaultList(homeId)).id;

    final targetName = (selectedOptionId != null && selectedOptionId.isNotEmpty)
        ? selectedOptionId
        : (command.productName ?? command.productQuery);

    final addQty = command.quantity ?? 1.0;
    final unit = command.unit ?? 'pcs';

    // Check for existing active (uncompleted) item to increment
    final existingItems = list?.items ?? [];
    final matchingItem = existingItems.cast<dynamic>().firstWhere(
      (item) => !item.isCompleted &&
          (item.itemName.toLowerCase().trim() == targetName.toLowerCase().trim() ||
           (command.productId != null && item.inventoryItemId == command.productId)),
      orElse: () => null,
    );

    if (matchingItem != null) {
      // Intelligently increment quantity (no duplicate items!)
      final newQuantity = matchingItem.quantity + addQty;
      await _shoppingRepo.updateQuantity(homeId, listId, matchingItem.id, newQuantity);

      final formattedNewQty = newQuantity.truncateToDouble() == newQuantity
          ? newQuantity.toInt().toString()
          : newQuantity.toStringAsFixed(1);

      return CommandExecutionResult.success(
        operationId: command.operationId,
        intent: command.intent,
        message: '✓ Added ${_formatQty(addQty)} $unit $targetName (now $formattedNewQty ${matchingItem.unit})',
        affectedItemName: targetName,
        affectedQuantity: newQuantity,
        affectedUnit: matchingItem.unit,
        isOffline: command.isOffline,
      );
    } else {
      // Add fresh item
      await _shoppingRepo.addItem(
        homeId,
        listId,
        itemName: targetName,
        quantity: addQty,
        unit: unit,
        categoryName: command.category ?? 'General',
        inventoryItemId: command.productId,
      );

      return CommandExecutionResult.success(
        operationId: command.operationId,
        intent: command.intent,
        message: '✓ Added ${_formatQty(addQty)} $unit $targetName to your shopping list',
        affectedItemName: targetName,
        affectedQuantity: addQty,
        affectedUnit: unit,
        isOffline: command.isOffline,
      );
    }
  }

  Future<CommandExecutionResult> _executeRemoveShoppingItem(
    NormalizedVoiceCommand command,
    String homeId,
  ) async {
    final list = await _shoppingRepo.getDefaultList(homeId);
    if (list == null || list.items.isEmpty) {
      return CommandExecutionResult.failure(
        operationId: command.operationId,
        intent: command.intent,
        message: 'Shopping list is empty.',
        isOffline: command.isOffline,
      );
    }

    final targetName = (command.productName ?? command.productQuery).toLowerCase().trim();
    final matchingItem = list.items.cast<dynamic>().firstWhere(
      (item) => item.itemName.toLowerCase().trim() == targetName ||
                item.itemName.toLowerCase().contains(targetName),
      orElse: () => null,
    );

    if (matchingItem == null) {
      return CommandExecutionResult.failure(
        operationId: command.operationId,
        intent: command.intent,
        message: '${command.productName ?? targetName} is not in your shopping list.',
        isOffline: command.isOffline,
      );
    }

    await _shoppingRepo.deleteItem(homeId, list.id, matchingItem.id);

    return CommandExecutionResult.success(
      operationId: command.operationId,
      intent: command.intent,
      message: '✓ Removed ${matchingItem.itemName} from your shopping list',
      affectedItemName: matchingItem.itemName,
      isOffline: command.isOffline,
    );
  }

  Future<CommandExecutionResult> _executeUpdateShoppingQuantity(
    NormalizedVoiceCommand command,
    String homeId,
  ) async {
    final list = await _shoppingRepo.getDefaultList(homeId);
    if (list == null) throw Exception('Shopping list not found');

    final targetName = (command.productName ?? command.productQuery).toLowerCase().trim();
    final matchingItem = list.items.cast<dynamic>().firstWhere(
      (item) => item.itemName.toLowerCase().trim() == targetName ||
                item.itemName.toLowerCase().contains(targetName),
      orElse: () => null,
    );

    if (matchingItem == null) {
      return CommandExecutionResult.failure(
        operationId: command.operationId,
        intent: command.intent,
        message: '${command.productName ?? targetName} is not in your shopping list.',
        isOffline: command.isOffline,
      );
    }

    final newQty = command.quantity ?? 1.0;
    await _shoppingRepo.updateQuantity(homeId, list.id, matchingItem.id, newQty);

    return CommandExecutionResult.success(
      operationId: command.operationId,
      intent: command.intent,
      message: '✓ Updated ${matchingItem.itemName} quantity to ${_formatQty(newQty)} ${matchingItem.unit}',
      affectedItemName: matchingItem.itemName,
      affectedQuantity: newQty,
      isOffline: command.isOffline,
    );
  }

  Future<CommandExecutionResult> _executeCompleteShoppingItem(
    NormalizedVoiceCommand command,
    String homeId,
  ) async {
    final list = await _shoppingRepo.getDefaultList(homeId);
    if (list == null) throw Exception('Shopping list not found');

    final targetName = (command.productName ?? command.productQuery).toLowerCase().trim();
    final matchingItem = list.items.cast<dynamic>().firstWhere(
      (item) => !item.isCompleted &&
          (item.itemName.toLowerCase().trim() == targetName ||
           item.itemName.toLowerCase().contains(targetName)),
      orElse: () => null,
    );

    if (matchingItem == null) {
      return CommandExecutionResult.failure(
        operationId: command.operationId,
        intent: command.intent,
        message: 'Active item ${command.productName} not found in shopping list.',
        isOffline: command.isOffline,
      );
    }

    await _shoppingRepo.toggleItem(homeId, list.id, matchingItem.id);

    return CommandExecutionResult.success(
      operationId: command.operationId,
      intent: command.intent,
      message: '✓ Marked ${matchingItem.itemName} as bought',
      affectedItemName: matchingItem.itemName,
      isOffline: command.isOffline,
    );
  }

  Future<CommandExecutionResult> _executeClearShoppingList(
    NormalizedVoiceCommand command,
    String homeId,
  ) async {
    final list = await _shoppingRepo.getDefaultList(homeId);
    if (list != null) {
      for (final item in list.items) {
        await _shoppingRepo.deleteItem(homeId, list.id, item.id);
      }
    }
    return CommandExecutionResult.success(
      operationId: command.operationId,
      intent: command.intent,
      message: '✓ Cleared your shopping list',
      isOffline: command.isOffline,
    );
  }

  Future<CommandExecutionResult> _executeStockIn(
    NormalizedVoiceCommand command,
    String homeId,
    String? selectedOptionId,
  ) async {
    final items = await _inventoryRepo.getItems(homeId);
    final targetName = (selectedOptionId != null && selectedOptionId.isNotEmpty)
        ? selectedOptionId
        : (command.productName ?? command.productQuery);

    final matching = items.cast<dynamic>().firstWhere(
      (i) => i.name.toLowerCase().trim() == targetName.toLowerCase().trim() ||
             i.name.toLowerCase().contains(targetName.toLowerCase().trim()),
      orElse: () => null,
    );

    final qtyChange = command.quantity ?? 1.0;

    if (matching != null) {
      final prev = matching.quantity as double;
      await _inventoryRepo.updateStock(
        homeId,
        matching.id,
        quantityChange: qtyChange,
        transactionType: 'STOCK_IN',
        reason: 'Voice command',
      );
      final newQty = prev + qtyChange;
      return CommandExecutionResult.success(
        operationId: command.operationId,
        intent: command.intent,
        message: '✓ Added ${_formatQty(qtyChange)} ${matching.unit} ${matching.name} to stock (now ${_formatQty(newQty)} ${matching.unit})',
        affectedItemName: matching.name,
        previousStock: prev,
        newStock: newQty,
        isOffline: command.isOffline,
      );
    } else {
      // Create new inventory item
      final created = await _inventoryRepo.createItem(
        homeId,
        {
          'name': targetName,
          'quantity': qtyChange,
          'unit': command.unit ?? 'pcs',
          'categoryName': command.category ?? 'General',
        },
      );
      return CommandExecutionResult.success(
        operationId: command.operationId,
        intent: command.intent,
        message: '✓ Added ${_formatQty(qtyChange)} ${command.unit ?? 'pcs'} ${created.name} to inventory',
        affectedItemName: created.name,
        newStock: qtyChange,
        isOffline: command.isOffline,
      );
    }
  }

  Future<CommandExecutionResult> _executeStockOut(
    NormalizedVoiceCommand command,
    String homeId,
    String? selectedOptionId,
  ) async {
    final items = await _inventoryRepo.getItems(homeId);
    final targetName = (selectedOptionId != null && selectedOptionId.isNotEmpty)
        ? selectedOptionId
        : (command.productName ?? command.productQuery);

    final matching = items.cast<dynamic>().firstWhere(
      (i) => i.name.toLowerCase().trim() == targetName.toLowerCase().trim() ||
             i.name.toLowerCase().contains(targetName.toLowerCase().trim()),
      orElse: () => null,
    );

    if (matching == null) {
      return CommandExecutionResult.failure(
        operationId: command.operationId,
        intent: command.intent,
        message: '$targetName is not in your inventory.',
        isOffline: command.isOffline,
      );
    }

    final prev = matching.quantity as double;
    final qtyChange = command.quantity ?? 1.0;

    if (prev < qtyChange) {
      return CommandExecutionResult.failure(
        operationId: command.operationId,
        intent: command.intent,
        message: 'Cannot deduct ${_formatQty(qtyChange)} ${matching.unit}. Only ${_formatQty(prev)} ${matching.unit} available.',
        isOffline: command.isOffline,
      );
    }

    await _inventoryRepo.updateStock(
      homeId,
      matching.id,
      quantityChange: qtyChange,
      transactionType: 'STOCK_OUT',
      reason: 'Voice command: consumed',
    );
    final newQty = prev - qtyChange;

    return CommandExecutionResult.success(
      operationId: command.operationId,
      intent: command.intent,
      message: '✓ Deducted ${_formatQty(qtyChange)} ${matching.unit} ${matching.name} from stock (remaining: ${_formatQty(newQty)} ${matching.unit})',
      affectedItemName: matching.name,
      previousStock: prev,
      newStock: newQty,
      isOffline: command.isOffline,
    );
  }

  Future<CommandExecutionResult> _executeUpdateStock(
    NormalizedVoiceCommand command,
    String homeId,
    String? selectedOptionId,
  ) async {
    final items = await _inventoryRepo.getItems(homeId);
    final targetName = (selectedOptionId != null && selectedOptionId.isNotEmpty)
        ? selectedOptionId
        : (command.productName ?? command.productQuery);

    final matching = items.cast<dynamic>().firstWhere(
      (i) => i.name.toLowerCase().trim() == targetName.toLowerCase().trim() ||
             i.name.toLowerCase().contains(targetName.toLowerCase().trim()),
      orElse: () => null,
    );

    if (matching == null) {
      return CommandExecutionResult.failure(
        operationId: command.operationId,
        intent: command.intent,
        message: '$targetName not found in inventory.',
        isOffline: command.isOffline,
      );
    }

    final newQty = command.quantity ?? 0.0;
    await _inventoryRepo.updateStock(
      homeId,
      matching.id,
      quantityChange: newQty,
      transactionType: 'ADJUSTMENT',
      reason: 'Voice command: stock update',
    );

    return CommandExecutionResult.success(
      operationId: command.operationId,
      intent: command.intent,
      message: '✓ Updated ${matching.name} stock to ${_formatQty(newQty)} ${matching.unit}',
      affectedItemName: matching.name,
      newStock: newQty,
      isOffline: command.isOffline,
    );
  }

  Future<CommandExecutionResult> _executeCheckStock(
    NormalizedVoiceCommand command,
    String homeId,
  ) async {
    final items = await _inventoryRepo.getItems(homeId);
    final targetName = (command.productName ?? command.productQuery).toLowerCase().trim();

    final matching = items.cast<dynamic>().firstWhere(
      (i) => i.name.toLowerCase().trim() == targetName ||
             i.name.toLowerCase().contains(targetName),
      orElse: () => null,
    );

    if (matching != null) {
      return CommandExecutionResult.success(
        operationId: command.operationId,
        intent: command.intent,
        message: '✓ ${matching.name} stock is ${_formatQty(matching.quantity)} ${matching.unit}',
        affectedItemName: matching.name,
        affectedQuantity: matching.quantity,
        affectedUnit: matching.unit,
        isOffline: command.isOffline,
      );
    } else {
      return CommandExecutionResult.success(
        operationId: command.operationId,
        intent: command.intent,
        message: '${command.productName ?? targetName} is currently not in your pantry.',
        isOffline: command.isOffline,
      );
    }
  }

  Future<CommandExecutionResult> _executeCheckLowStock(
    NormalizedVoiceCommand command,
    String homeId,
  ) async {
    final items = await _inventoryRepo.getItems(homeId);
    final lowItems = items.cast<dynamic>().where((i) => i.stockStatus == 'LOW_STOCK' || i.stockStatus == 'OUT_OF_STOCK').toList();

    if (lowItems.isEmpty) {
      return CommandExecutionResult.success(
        operationId: command.operationId,
        intent: command.intent,
        message: 'All household items are well-stocked! 🌿',
        isOffline: command.isOffline,
      );
    }

    final names = lowItems.take(3).map((i) => i.name).join(', ');
    final more = lowItems.length > 3 ? ' and ${lowItems.length - 3} more' : '';

    return CommandExecutionResult.success(
      operationId: command.operationId,
      intent: command.intent,
      message: '✓ ${lowItems.length} items running low: $names$more',
      navigationRoute: '/inventory',
      isOffline: command.isOffline,
    );
  }

  Future<CommandExecutionResult> _executeCheckOutOfStock(
    NormalizedVoiceCommand command,
    String homeId,
  ) async {
    final items = await _inventoryRepo.getItems(homeId);
    final outItems = items.cast<dynamic>().where((i) => i.stockStatus == 'OUT_OF_STOCK' || i.quantity <= 0).toList();

    if (outItems.isEmpty) {
      return CommandExecutionResult.success(
        operationId: command.operationId,
        intent: command.intent,
        message: 'No items are out of stock! 🌿',
        isOffline: command.isOffline,
      );
    }

    final names = outItems.take(3).map((i) => i.name).join(', ');
    return CommandExecutionResult.success(
      operationId: command.operationId,
      intent: command.intent,
      message: '✓ ${outItems.length} items out of stock: $names',
      navigationRoute: '/inventory',
      isOffline: command.isOffline,
    );
  }

  Future<CommandExecutionResult> _executeCheckExpiring(
    NormalizedVoiceCommand command,
    String homeId,
  ) async {
    final items = await _inventoryRepo.getItems(homeId);
    final expiring = items.cast<dynamic>().where((i) => i.daysUntilExpiry != null && i.daysUntilExpiry! <= 3).toList();

    if (expiring.isEmpty) {
      return CommandExecutionResult.success(
        operationId: command.operationId,
        intent: command.intent,
        message: 'No items are expiring soon! 🌿',
        isOffline: command.isOffline,
      );
    }

    final names = expiring.take(3).map((i) => i.name).join(', ');
    return CommandExecutionResult.success(
      operationId: command.operationId,
      intent: command.intent,
      message: '✓ ${expiring.length} items expiring soon: $names',
      navigationRoute: '/inventory',
      isOffline: command.isOffline,
    );
  }

  static String _formatQty(num qty) {
    if (qty.truncateToDouble() == qty) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(1);
  }
}
