package com.homestock.modules.voice.service;

import com.homestock.core.exception.BusinessRuleException;
import com.homestock.core.security.HomeSecurityService;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.inventory.dto.CreateInventoryItemRequest;
import com.homestock.modules.inventory.dto.InventoryItemDto;
import com.homestock.modules.inventory.dto.StockUpdateRequest;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.entity.TransactionType;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.inventory.service.InventoryService;
import com.homestock.modules.shopping.dto.CreateShoppingItemRequest;
import com.homestock.modules.shopping.dto.ShoppingListDto;
import com.homestock.modules.shopping.dto.ShoppingListItemDto;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.shopping.repository.ShoppingListRepository;
import com.homestock.modules.shopping.service.ShoppingService;
import com.homestock.modules.voice.dto.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class VoiceCommandExecutor {

    private final ShoppingService shoppingService;
    private final ShoppingListItemRepository shoppingListItemRepository;
    private final ShoppingListRepository shoppingListRepository;
    private final InventoryService inventoryService;
    private final InventoryItemRepository inventoryItemRepository;
    private final HomeRepository homeRepository;
    private final HomeSecurityService homeSecurityService;

    @Transactional
    public ExecuteCommandResponse execute(ExecuteCommandRequest request) {
        UUID homeId = request.getHomeId();
        VoiceCommandResult commandResult = request.getCommandResult();
        if (commandResult == null || commandResult.getIntent() == null) {
            return ExecuteCommandResponse.builder()
                    .success(false)
                    .intent(VoiceIntent.UNKNOWN)
                    .message("No command result provided to execute.")
                    .build();
        }

        VoiceIntent intent = commandResult.getIntent();
        VoiceEntities entities = commandResult.getEntities() != null ? commandResult.getEntities() : new VoiceEntities();

        // Check base home membership
        if (!homeSecurityService.isMember(homeId)) {
            throw new AccessDeniedException("User is not a member of home " + homeId);
        }

        return switch (intent) {
            case ADD_SHOPPING_ITEM -> executeAddShoppingItem(homeId, entities);
            case REMOVE_SHOPPING_ITEM -> executeRemoveShoppingItem(homeId, entities, commandResult, request);
            case COMPLETE_SHOPPING_ITEM -> executeCompleteShoppingItem(homeId, entities);
            case STOCK_IN -> executeStockIn(homeId, entities);
            case STOCK_OUT -> executeStockOut(homeId, entities);
            case UPDATE_STOCK -> executeUpdateStock(homeId, entities, request);
            case ADD_INVENTORY_ITEM -> executeAddInventoryItem(homeId, entities, commandResult, request);
            case GET_ITEM_STATUS -> executeGetItemStatus(homeId, entities);
            case GET_SHOPPING_LIST -> executeGetShoppingList(homeId);
            case GET_LOW_STOCK_ITEMS -> executeGetLowStockItems(homeId);
            case GET_EXPIRING_ITEMS -> executeGetExpiringItems(homeId);
            case SEARCH_INVENTORY -> executeSearchInventory(homeId, entities);
            case OPEN_SHOPPING_LIST -> ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(intent)
                    .message("Opening shopping list")
                    .navigation(Map.of("route", "/shopping"))
                    .build();
            case OPEN_INVENTORY -> ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(intent)
                    .message("Opening inventory")
                    .navigation(Map.of("route", "/inventory"))
                    .build();
            case OPEN_ANALYTICS -> ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(intent)
                    .message("Opening analytics")
                    .navigation(Map.of("route", "/analytics"))
                    .build();
            case SMART_PRICE_CHECK -> executeSmartPriceCheck(homeId, entities);
            default -> ExecuteCommandResponse.builder()
                    .success(false)
                    .intent(intent)
                    .message("I could not determine how to execute this command. Please try again.")
                    .build();
        };
    }

    private ExecuteCommandResponse executeAddShoppingItem(UUID homeId, VoiceEntities entities) {
        if (!homeSecurityService.canEditShoppingList(homeId)) {
            throw new AccessDeniedException("Permission denied to edit shopping list");
        }

        String itemName = entities.getItemName();
        if (itemName == null || itemName.isBlank()) {
            return ExecuteCommandResponse.builder()
                    .success(false)
                    .intent(VoiceIntent.ADD_SHOPPING_ITEM)
                    .message("Item name was not specified.")
                    .build();
        }

        ShoppingListDto defaultList = shoppingService.getDefaultShoppingList(homeId);
        CreateShoppingItemRequest req = new CreateShoppingItemRequest();
        req.setItemName(capitalize(itemName.trim()));
        req.setQuantity(entities.getQuantity() != null ? entities.getQuantity() : BigDecimal.ONE);
        req.setUnit(entities.getUnit() != null ? entities.getUnit() : "pcs");
        req.setInventoryItemId(entities.getMatchedInventoryItemId());

        ShoppingListItemDto created = shoppingService.addItem(homeId, defaultList.getId(), req);

        String quantityStr = req.getQuantity().stripTrailingZeros().toPlainString();
        String msg = String.format("Added %s %s %s to shopping list", quantityStr, req.getUnit(), req.getItemName());

        return ExecuteCommandResponse.builder()
                .success(true)
                .intent(VoiceIntent.ADD_SHOPPING_ITEM)
                .message(msg)
                .data(created)
                .navigation(Map.of("route", "/shopping"))
                .build();
    }

    private ExecuteCommandResponse executeRemoveShoppingItem(UUID homeId, VoiceEntities entities,
                                                             VoiceCommandResult commandResult,
                                                             ExecuteCommandRequest request) {
        if (!homeSecurityService.canEditShoppingList(homeId)) {
            throw new AccessDeniedException("Permission denied to edit shopping list");
        }

        if (commandResult.isRequiresConfirmation() && !request.isConfirmed()) {
            return ExecuteCommandResponse.builder()
                    .success(false)
                    .intent(VoiceIntent.REMOVE_SHOPPING_ITEM)
                    .message("Please confirm removing " + entities.getItemName() + " from the shopping list.")
                    .build();
        }

        String targetName = entities.getItemName();
        if (targetName == null || targetName.isBlank()) {
            return ExecuteCommandResponse.builder()
                    .success(false)
                    .intent(VoiceIntent.REMOVE_SHOPPING_ITEM)
                    .message("Item name not recognized.")
                    .build();
        }

        List<ShoppingListItem> items = shoppingListItemRepository.findPendingItemsByHomeId(homeId);
        Optional<ShoppingListItem> matched = items.stream()
                .filter(i -> i.getItemName().equalsIgnoreCase(targetName)
                        || (entities.getMatchedInventoryItemId() != null
                        && i.getInventoryItem() != null
                        && entities.getMatchedInventoryItemId().equals(i.getInventoryItem().getId())))
                .findFirst();

        if (matched.isEmpty()) {
            // Partial match fallback
            matched = items.stream()
                    .filter(i -> i.getItemName().toLowerCase().contains(targetName.toLowerCase()))
                    .findFirst();
        }

        if (matched.isEmpty()) {
            return ExecuteCommandResponse.builder()
                    .success(false)
                    .intent(VoiceIntent.REMOVE_SHOPPING_ITEM)
                    .message("Item '" + targetName + "' was not found on your shopping list.")
                    .build();
        }

        ShoppingListItem toRemove = matched.get();
        shoppingService.deleteItem(homeId, toRemove.getShoppingList().getId(), toRemove.getId());

        return ExecuteCommandResponse.builder()
                .success(true)
                .intent(VoiceIntent.REMOVE_SHOPPING_ITEM)
                .message("Removed " + toRemove.getItemName() + " from shopping list")
                .navigation(Map.of("route", "/shopping"))
                .build();
    }

    private ExecuteCommandResponse executeCompleteShoppingItem(UUID homeId, VoiceEntities entities) {
        if (!homeSecurityService.canEditShoppingList(homeId)) {
            throw new AccessDeniedException("Permission denied to edit shopping list");
        }

        String targetName = entities.getItemName();
        List<ShoppingListItem> items = shoppingListItemRepository.findPendingItemsByHomeId(homeId);
        Optional<ShoppingListItem> matched = items.stream()
                .filter(i -> i.getItemName().equalsIgnoreCase(targetName)
                        || (entities.getMatchedInventoryItemId() != null
                        && i.getInventoryItem() != null
                        && entities.getMatchedInventoryItemId().equals(i.getInventoryItem().getId()))
                        || i.getItemName().toLowerCase().contains(targetName.toLowerCase()))
                .findFirst();

        if (matched.isEmpty()) {
            return ExecuteCommandResponse.builder()
                    .success(false)
                    .intent(VoiceIntent.COMPLETE_SHOPPING_ITEM)
                    .message("Item '" + targetName + "' was not found on your shopping list.")
                    .build();
        }

        ShoppingListItem toComplete = matched.get();
        ShoppingListItemDto toggled = shoppingService.toggleItem(homeId, toComplete.getShoppingList().getId(), toComplete.getId());

        return ExecuteCommandResponse.builder()
                .success(true)
                .intent(VoiceIntent.COMPLETE_SHOPPING_ITEM)
                .message("Marked " + toComplete.getItemName() + " as purchased")
                .data(toggled)
                .navigation(Map.of("route", "/shopping"))
                .build();
    }

    private ExecuteCommandResponse executeStockIn(UUID homeId, VoiceEntities entities) {
        if (!homeSecurityService.canManageInventory(homeId)) {
            throw new AccessDeniedException("Permission denied to manage inventory");
        }

        InventoryItem item = resolveInventoryItem(homeId, entities);
        if (item == null) {
            return ExecuteCommandResponse.builder()
                    .success(false)
                    .intent(VoiceIntent.STOCK_IN)
                    .message("Item '" + entities.getItemName() + "' not found in inventory.")
                    .build();
        }

        BigDecimal qtyChange = entities.getQuantity() != null ? entities.getQuantity() : BigDecimal.ONE;
        StockUpdateRequest stockReq = new StockUpdateRequest();
        stockReq.setTransactionType(TransactionType.STOCK_IN);
        stockReq.setQuantityChange(qtyChange);
        stockReq.setReason("Voice command: stock added");

        InventoryItemDto updated = inventoryService.updateStock(homeId, item.getId(), stockReq);
        String qtyChangeStr = qtyChange.stripTrailingZeros().toPlainString();
        String currentQtyStr = updated.getQuantity().stripTrailingZeros().toPlainString();

        return ExecuteCommandResponse.builder()
                .success(true)
                .intent(VoiceIntent.STOCK_IN)
                .message(String.format("Added %s %s to %s. New stock: %s %s",
                        qtyChangeStr, updated.getUnit(), updated.getName(), currentQtyStr, updated.getUnit()))
                .data(updated)
                .navigation(Map.of("route", "/inventory", "itemId", item.getId().toString()))
                .build();
    }

    private ExecuteCommandResponse executeStockOut(UUID homeId, VoiceEntities entities) {
        if (!homeSecurityService.canManageInventory(homeId)) {
            throw new AccessDeniedException("Permission denied to manage inventory");
        }

        InventoryItem item = resolveInventoryItem(homeId, entities);
        if (item == null) {
            return ExecuteCommandResponse.builder()
                    .success(false)
                    .intent(VoiceIntent.STOCK_OUT)
                    .message("Item '" + entities.getItemName() + "' not found in inventory.")
                    .build();
        }

        BigDecimal qtyChange = entities.getQuantity() != null ? entities.getQuantity() : BigDecimal.ONE;
        StockUpdateRequest stockReq = new StockUpdateRequest();
        stockReq.setTransactionType(TransactionType.STOCK_OUT);
        stockReq.setQuantityChange(qtyChange);
        stockReq.setReason("Voice command: stock used");

        try {
            InventoryItemDto updated = inventoryService.updateStock(homeId, item.getId(), stockReq);
            String qtyChangeStr = qtyChange.stripTrailingZeros().toPlainString();
            String currentQtyStr = updated.getQuantity().stripTrailingZeros().toPlainString();

            return ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(VoiceIntent.STOCK_OUT)
                    .message(String.format("Used %s %s of %s. Remaining: %s %s",
                            qtyChangeStr, updated.getUnit(), updated.getName(), currentQtyStr, updated.getUnit()))
                    .data(updated)
                    .navigation(Map.of("route", "/inventory", "itemId", item.getId().toString()))
                    .build();
        } catch (BusinessRuleException e) {
            return ExecuteCommandResponse.builder()
                    .success(false)
                    .intent(VoiceIntent.STOCK_OUT)
                    .message(e.getMessage())
                    .build();
        }
    }

    private ExecuteCommandResponse executeUpdateStock(UUID homeId, VoiceEntities entities, ExecuteCommandRequest request) {
        if (!homeSecurityService.canManageInventory(homeId)) {
            throw new AccessDeniedException("Permission denied to manage inventory");
        }

        // If user chose "ADD_STOCK" from disambiguation
        if ("ADD_STOCK".equalsIgnoreCase(request.getSelectedOptionId())) {
            return executeStockIn(homeId, entities);
        }

        InventoryItem item = resolveInventoryItem(homeId, entities);
        if (item == null) {
            return ExecuteCommandResponse.builder()
                    .success(false)
                    .intent(VoiceIntent.UPDATE_STOCK)
                    .message("Item '" + entities.getItemName() + "' not found in inventory.")
                    .build();
        }

        BigDecimal targetQty = entities.getQuantity() != null ? entities.getQuantity() : BigDecimal.ZERO;
        StockUpdateRequest stockReq = new StockUpdateRequest();
        stockReq.setTransactionType(TransactionType.ADJUSTMENT);
        stockReq.setQuantityChange(targetQty);
        stockReq.setReason("Voice command: updated stock level");

        InventoryItemDto updated = inventoryService.updateStock(homeId, item.getId(), stockReq);
        String qtyStr = updated.getQuantity().stripTrailingZeros().toPlainString();

        return ExecuteCommandResponse.builder()
                .success(true)
                .intent(VoiceIntent.UPDATE_STOCK)
                .message(String.format("Updated %s stock to %s %s", updated.getName(), qtyStr, updated.getUnit()))
                .data(updated)
                .navigation(Map.of("route", "/inventory", "itemId", item.getId().toString()))
                .build();
    }

    private ExecuteCommandResponse executeAddInventoryItem(UUID homeId, VoiceEntities entities,
                                                           VoiceCommandResult commandResult,
                                                           ExecuteCommandRequest request) {
        if (!homeSecurityService.canManageInventory(homeId)) {
            throw new AccessDeniedException("Permission denied to manage inventory");
        }

        if (commandResult.isRequiresConfirmation() && !request.isConfirmed()) {
            return ExecuteCommandResponse.builder()
                    .success(false)
                    .intent(VoiceIntent.ADD_INVENTORY_ITEM)
                    .message("Please confirm adding " + entities.getItemName() + " to inventory.")
                    .build();
        }

        String itemName = entities.getItemName();
        if (itemName == null || itemName.isBlank()) {
            return ExecuteCommandResponse.builder()
                    .success(false)
                    .intent(VoiceIntent.ADD_INVENTORY_ITEM)
                    .message("Item name cannot be empty.")
                    .build();
        }

        CreateInventoryItemRequest req = new CreateInventoryItemRequest();
        req.setName(capitalize(itemName.trim()));
        req.setQuantity(entities.getQuantity() != null ? entities.getQuantity() : BigDecimal.ONE);
        req.setUnit(entities.getUnit() != null ? entities.getUnit() : "pcs");
        req.setBrand(entities.getBrand());
        req.setPurchasePrice(entities.getPrice());

        InventoryItemDto created = inventoryService.createItem(homeId, req);

        return ExecuteCommandResponse.builder()
                .success(true)
                .intent(VoiceIntent.ADD_INVENTORY_ITEM)
                .message(String.format("Added %s (%s %s) to inventory",
                        created.getName(),
                        created.getQuantity().stripTrailingZeros().toPlainString(),
                        created.getUnit()))
                .data(created)
                .navigation(Map.of("route", "/inventory", "itemId", created.getId().toString()))
                .build();
    }

    private ExecuteCommandResponse executeGetItemStatus(UUID homeId, VoiceEntities entities) {
        String itemName = entities.getItemName();
        if (itemName == null || itemName.isBlank()) {
            return ExecuteCommandResponse.builder()
                    .success(false)
                    .intent(VoiceIntent.GET_ITEM_STATUS)
                    .message("Please specify which item to check.")
                    .build();
        }

        InventoryItem item = resolveInventoryItem(homeId, entities);
        List<ShoppingListItem> pendingShoppingItems = shoppingListItemRepository.findPendingItemsByHomeId(homeId);

        boolean onShoppingList = pendingShoppingItems.stream()
                .anyMatch(s -> s.getItemName().toLowerCase().contains(itemName.toLowerCase())
                        || (item != null && s.getInventoryItem() != null && s.getInventoryItem().getId().equals(item.getId())));

        if (item != null) {
            String qtyStr = item.getQuantity().stripTrailingZeros().toPlainString();
            String msg = String.format("%s: %s %s available in %s.",
                    item.getName(), qtyStr, item.getUnit(),
                    item.getStorageLocation() != null ? item.getStorageLocation() : "inventory");
            if (onShoppingList) {
                msg += " It is also currently on your shopping list.";
            }
            return ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(VoiceIntent.GET_ITEM_STATUS)
                    .message(msg)
                    .data(InventoryItemDto.fromEntity(item))
                    .navigation(Map.of("route", "/inventory", "itemId", item.getId().toString()))
                    .build();
        } else if (onShoppingList) {
            return ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(VoiceIntent.GET_ITEM_STATUS)
                    .message(capitalize(itemName) + " is currently on your shopping list, not recorded in inventory.")
                    .navigation(Map.of("route", "/shopping"))
                    .build();
        } else {
            return ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(VoiceIntent.GET_ITEM_STATUS)
                    .message(capitalize(itemName) + " was not found in your inventory or shopping list.")
                    .build();
        }
    }

    private ExecuteCommandResponse executeGetShoppingList(UUID homeId) {
        List<ShoppingListItem> pending = shoppingListItemRepository.findPendingItemsByHomeId(homeId);
        if (pending.isEmpty()) {
            return ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(VoiceIntent.GET_SHOPPING_LIST)
                    .message("Your shopping list is empty.")
                    .data(Collections.emptyList())
                    .navigation(Map.of("route", "/shopping"))
                    .build();
        }

        String itemsSummary = pending.stream()
                .limit(5)
                .map(i -> i.getItemName() + " (" + i.getQuantity().stripTrailingZeros().toPlainString() + " " + i.getUnit() + ")")
                .collect(Collectors.joining(", "));

        String msg = String.format("You have %d items on your shopping list: %s%s",
                pending.size(),
                itemsSummary,
                pending.size() > 5 ? " and " + (pending.size() - 5) + " more." : ".");

        return ExecuteCommandResponse.builder()
                .success(true)
                .intent(VoiceIntent.GET_SHOPPING_LIST)
                .message(msg)
                .data(pending.stream().map(ShoppingListItemDto::fromEntity).collect(Collectors.toList()))
                .navigation(Map.of("route", "/shopping"))
                .build();
    }

    private ExecuteCommandResponse executeGetLowStockItems(UUID homeId) {
        List<InventoryItem> lowStock = inventoryItemRepository.findLowStockItems(homeId);
        if (lowStock.isEmpty()) {
            return ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(VoiceIntent.GET_LOW_STOCK_ITEMS)
                    .message("Good news! No items are currently low on stock.")
                    .data(Collections.emptyList())
                    .navigation(Map.of("route", "/inventory"))
                    .build();
        }

        String itemsSummary = lowStock.stream()
                .limit(5)
                .map(i -> i.getName() + " (" + i.getQuantity().stripTrailingZeros().toPlainString() + " " + i.getUnit() + ")")
                .collect(Collectors.joining(", "));

        String msg = String.format("You have %d low stock items: %s%s",
                lowStock.size(),
                itemsSummary,
                lowStock.size() > 5 ? " and " + (lowStock.size() - 5) + " more." : ".");

        return ExecuteCommandResponse.builder()
                .success(true)
                .intent(VoiceIntent.GET_LOW_STOCK_ITEMS)
                .message(msg)
                .data(lowStock.stream().map(InventoryItemDto::fromEntity).collect(Collectors.toList()))
                .navigation(Map.of("route", "/inventory", "filter", "low_stock"))
                .build();
    }

    private ExecuteCommandResponse executeGetExpiringItems(UUID homeId) {
        LocalDate today = LocalDate.now();
        List<InventoryItem> expiring = inventoryItemRepository.findExpiringSoonItems(homeId, today, today.plusDays(7));
        if (expiring.isEmpty()) {
            return ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(VoiceIntent.GET_EXPIRING_ITEMS)
                    .message("No items are expiring in the next 7 days.")
                    .data(Collections.emptyList())
                    .navigation(Map.of("route", "/inventory"))
                    .build();
        }

        String itemsSummary = expiring.stream()
                .limit(5)
                .map(i -> i.getName() + " (expires " + i.getExpiryDate() + ")")
                .collect(Collectors.joining(", "));

        String msg = String.format("%d items are expiring in the next 7 days: %s%s",
                expiring.size(),
                itemsSummary,
                expiring.size() > 5 ? " and " + (expiring.size() - 5) + " more." : ".");

        return ExecuteCommandResponse.builder()
                .success(true)
                .intent(VoiceIntent.GET_EXPIRING_ITEMS)
                .message(msg)
                .data(expiring.stream().map(InventoryItemDto::fromEntity).collect(Collectors.toList()))
                .navigation(Map.of("route", "/inventory", "filter", "expiring_soon"))
                .build();
    }

    private ExecuteCommandResponse executeSearchInventory(UUID homeId, VoiceEntities entities) {
        String query = entities.getItemName();
        if (query == null || query.isBlank()) {
            return ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(VoiceIntent.SEARCH_INVENTORY)
                    .message("Showing all inventory items.")
                    .navigation(Map.of("route", "/inventory"))
                    .build();
        }

        var results = inventoryService.getItems(homeId, null, null, query, 0, 10);
        String msg = String.format("Found %d items matching '%s'.", results.getTotalElements(), query);

        return ExecuteCommandResponse.builder()
                .success(true)
                .intent(VoiceIntent.SEARCH_INVENTORY)
                .message(msg)
                .data(results.getContent())
                .navigation(Map.of("route", "/inventory", "query", query))
                .build();
    }

    private ExecuteCommandResponse executeSmartPriceCheck(UUID homeId, VoiceEntities entities) {
        String itemName = entities.getItemName();
        String msg = "Smart price comparisons are available in the Smart Shopping tab for " + (itemName != null ? itemName : "this item") + ".";
        return ExecuteCommandResponse.builder()
                .success(true)
                .intent(VoiceIntent.SMART_PRICE_CHECK)
                .message(msg)
                .navigation(Map.of("route", "/smart-shopping", "query", itemName != null ? itemName : ""))
                .build();
    }

    private InventoryItem resolveInventoryItem(UUID homeId, VoiceEntities entities) {
        if (entities.getMatchedInventoryItemId() != null) {
            return inventoryItemRepository.findByIdAndHomeId(entities.getMatchedInventoryItemId(), homeId).orElse(null);
        }

        String name = entities.getItemName();
        if (name == null || name.isBlank()) return null;

        var items = inventoryItemRepository.findAll((root, cq, cb) -> cb.and(
                cb.equal(root.get("home").get("id"), homeId),
                cb.isFalse(root.get("isArchived"))
        ));

        // Exact match
        for (var item : items) {
            if (item.getName().equalsIgnoreCase(name.trim())) return item;
        }

        // Substring match
        for (var item : items) {
            if (item.getName().toLowerCase().contains(name.trim().toLowerCase())) return item;
        }

        return null;
    }

    private String capitalize(String str) {
        if (str == null || str.isEmpty()) return str;
        return Character.toUpperCase(str.charAt(0)) + str.substring(1);
    }
}
