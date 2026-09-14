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
import com.homestock.modules.shopping.dto.UpdateShoppingItemRequest;
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
    private final ProductResolutionService productResolutionService;
    private final com.homestock.modules.product.repository.ProductRepository productRepository;

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

        String lang = commandResult.getDetectedLanguage() != null && !commandResult.getDetectedLanguage().isBlank()
                ? commandResult.getDetectedLanguage()
                : "EN";

        ExecuteCommandResponse response = switch (intent) {
            case ADD_SHOPPING_ITEM -> executeAddShoppingItem(homeId, entities, lang);
            case REMOVE_SHOPPING_ITEM -> executeRemoveShoppingItem(homeId, entities, commandResult, request);
            case UPDATE_SHOPPING_ITEM -> executeUpdateShoppingItem(homeId, entities);
            case COMPLETE_SHOPPING_ITEM -> executeCompleteShoppingItem(homeId, entities);
            case CLEAR_SHOPPING_LIST -> executeClearShoppingList(homeId);
            case STOCK_IN -> executeStockIn(homeId, entities);
            case STOCK_OUT -> executeStockOut(homeId, entities);
            case UPDATE_STOCK -> executeUpdateStock(homeId, entities, request);
            case ADD_INVENTORY_ITEM -> executeAddInventoryItem(homeId, entities, commandResult, request);
            case REMOVE_INVENTORY_ITEM -> executeRemoveInventoryItem(homeId, entities);
            case GET_ITEM_STATUS -> executeGetItemStatus(homeId, entities, lang);
            case GET_SHOPPING_LIST -> executeGetShoppingList(homeId);
            case GET_LOW_STOCK_ITEMS -> executeGetLowStockItems(homeId);
            case GET_EXPIRING_ITEMS -> executeGetExpiringItems(homeId);
            case SEARCH_INVENTORY -> executeSearchInventory(homeId, entities);
            case SEARCH_PRODUCT -> executeSearchProduct(homeId, entities);
            case GET_PRODUCT_DETAILS -> executeGetProductDetails(homeId, entities);
            case OPEN_SHOPPING_LIST -> ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(intent)
                    .message("Opening shopping list")
                    .executionStatus("EXECUTED")
                    .navigation(Map.of("route", "/shopping"))
                    .build();
            case OPEN_INVENTORY -> ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(intent)
                    .message("Opening inventory")
                    .executionStatus("EXECUTED")
                    .navigation(Map.of("route", "/inventory"))
                    .build();
            case OPEN_ANALYTICS -> ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(intent)
                    .message("Opening analytics")
                    .executionStatus("EXECUTED")
                    .navigation(Map.of("route", "/analytics"))
                    .build();
            case SMART_PRICE_CHECK -> executeSmartPriceCheck(homeId, entities);
            default -> ExecuteCommandResponse.builder()
                    .success(false)
                    .intent(intent)
                    .message("I could not determine how to execute this command. Please try again.")
                    .executionStatus("FAILED")
                    .build();
        };

        if (response.getResponseLanguage() == null && commandResult.getDetectedLanguage() != null) {
            response.setResponseLanguage(commandResult.getDetectedLanguage());
        }
        if (response.getVoiceCommandId() == null && commandResult.getVoiceCommandId() != null) {
            response.setVoiceCommandId(commandResult.getVoiceCommandId());
        }
        if (response.getExecutionStatus() == null) {
            response.setExecutionStatus(response.isSuccess() ? "EXECUTED" : "FAILED");
        }
        response.setIntentConfidence(commandResult.getIntentConfidence());
        response.setProductMatchConfidence(commandResult.getProductMatchConfidence());

        return response;
    }

    private ExecuteCommandResponse executeAddShoppingItem(UUID homeId, VoiceEntities entities, String lang) {
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

        String trimmedName = itemName.trim();
        ShoppingListDto defaultList = shoppingService.getDefaultShoppingList(homeId);
        List<ShoppingListItem> existingPending = shoppingListItemRepository.findPendingItemsByHomeId(homeId);

        BigDecimal addQty = entities.getQuantity() != null ? entities.getQuantity() : BigDecimal.ONE;
        String unit = entities.getUnit() != null ? entities.getUnit() : "pcs";

        // Check if item is already on pending shopping list (new vs existing check)
        Optional<ShoppingListItem> existingOpt = existingPending.stream()
                .filter(i -> i.getItemName().equalsIgnoreCase(trimmedName)
                        || (entities.getMatchedInventoryItemId() != null
                        && i.getInventoryItem() != null
                        && entities.getMatchedInventoryItemId().equals(i.getInventoryItem().getId()))
                        || i.getItemName().toLowerCase().contains(trimmedName.toLowerCase())
                        || trimmedName.toLowerCase().contains(i.getItemName().toLowerCase()))
                .findFirst();

        if (existingOpt.isPresent()) {
            // Existing item on shopping list -> update quantity
            ShoppingListItem existing = existingOpt.get();
            BigDecimal currentQty = existing.getQuantity() != null ? existing.getQuantity() : BigDecimal.ZERO;
            BigDecimal newQty = currentQty.add(addQty);

            UpdateShoppingItemRequest updateReq = new UpdateShoppingItemRequest();
            updateReq.setItemName(existing.getItemName());
            updateReq.setQuantity(newQty);
            updateReq.setUnit(existing.getUnit() != null ? existing.getUnit() : unit);

            ShoppingListItemDto updated = shoppingService.updateItem(homeId, existing.getShoppingList().getId(), existing.getId(), updateReq);
            String qtyStr = newQty.stripTrailingZeros().toPlainString();
            String addedStr = addQty.stripTrailingZeros().toPlainString();

            String msg;
            if ("TANGLISH".equalsIgnoreCase(lang)) {
                msg = String.format("Shopping list-la %s-ku innoru %s %s sethuten! Motham %s %s irukku.",
                        existing.getItemName(), addedStr, updateReq.getUnit(), qtyStr, updateReq.getUnit());
            } else if ("TA".equalsIgnoreCase(lang)) {
                msg = String.format("ஷாப்பிங் பட்டியலில் %sக்கு மேலும் %s %s சேர்க்கப்பட்டது! மொத்தம் %s %s உள்ளது.",
                        existing.getItemName(), addedStr, updateReq.getUnit(), qtyStr, updateReq.getUnit());
            } else {
                msg = String.format("Updated %s on shopping list: added %s %s (total %s %s)",
                        existing.getItemName(), addedStr, updateReq.getUnit(), qtyStr, updateReq.getUnit());
            }

            return ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(VoiceIntent.ADD_SHOPPING_ITEM)
                    .message(msg)
                    .data(updated)
                    .navigation(Map.of("route", "/shopping"))
                    .build();
        } else {
            // New item on shopping list -> add new item
            CreateShoppingItemRequest req = new CreateShoppingItemRequest();
            req.setItemName(capitalize(trimmedName));
            req.setQuantity(addQty);
            req.setUnit(unit);
            req.setInventoryItemId(entities.getMatchedInventoryItemId());

            ShoppingListItemDto created = shoppingService.addItem(homeId, defaultList.getId(), req);

            String quantityStr = req.getQuantity().stripTrailingZeros().toPlainString();
            String msg;
            if ("TANGLISH".equalsIgnoreCase(lang)) {
                msg = String.format("%s %s %s-ah shopping list-la add pannitten!", quantityStr, req.getUnit(), req.getItemName());
            } else if ("TA".equalsIgnoreCase(lang)) {
                msg = String.format("%s %s %s ஷாப்பிங் பட்டியலில் சேர்க்கப்பட்டது!", quantityStr, req.getUnit(), req.getItemName());
            } else {
                msg = String.format("Added %s %s %s to your shopping list!", quantityStr, req.getUnit(), req.getItemName());
            }

            return ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(VoiceIntent.ADD_SHOPPING_ITEM)
                    .message(msg)
                    .data(created)
                    .navigation(Map.of("route", "/shopping"))
                    .build();
        }
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
            String itemName = entities.getItemName();
            if (itemName == null || itemName.isBlank()) {
                return ExecuteCommandResponse.builder()
                        .success(false)
                        .intent(VoiceIntent.STOCK_IN)
                        .message("Item name cannot be empty.")
                        .build();
            }

            BigDecimal initialQty = entities.getQuantity() != null ? entities.getQuantity() : BigDecimal.ONE;
            CreateInventoryItemRequest req = new CreateInventoryItemRequest();
            req.setName(capitalize(itemName.trim()));
            req.setQuantity(initialQty);
            req.setUnit(entities.getUnit() != null ? entities.getUnit() : "pcs");
            req.setBrand(entities.getBrand());
            req.setPurchasePrice(entities.getPrice());

            InventoryItemDto created = inventoryService.createItem(homeId, req);
            return ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(VoiceIntent.STOCK_IN)
                    .message(String.format("Added new product %s (%s %s) to inventory",
                            created.getName(),
                            created.getQuantity().stripTrailingZeros().toPlainString(),
                            created.getUnit()))
                    .data(created)
                    .navigation(Map.of("route", "/inventory", "itemId", created.getId().toString()))
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

        BigDecimal addQty = entities.getQuantity() != null ? entities.getQuantity() : BigDecimal.ONE;

        // Check new or existing product
        InventoryItem existingItem = resolveInventoryItem(homeId, entities);
        if (existingItem != null) {
            // Existing product found -> update stock
            StockUpdateRequest stockReq = new StockUpdateRequest();
            stockReq.setTransactionType(TransactionType.STOCK_IN);
            stockReq.setQuantityChange(addQty);
            stockReq.setReason("Voice command: added to existing stock");

            InventoryItemDto updated = inventoryService.updateStock(homeId, existingItem.getId(), stockReq);
            String qtyStr = updated.getQuantity().stripTrailingZeros().toPlainString();
            String addedStr = addQty.stripTrailingZeros().toPlainString();

            return ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(VoiceIntent.ADD_INVENTORY_ITEM)
                    .message(String.format("Updated existing %s: added %s %s (total stock now %s %s)",
                            updated.getName(), addedStr, updated.getUnit(), qtyStr, updated.getUnit()))
                    .data(updated)
                    .navigation(Map.of("route", "/inventory", "itemId", existingItem.getId().toString()))
                    .build();
        } else {
            // New product not in inventory -> add new product
            CreateInventoryItemRequest req = new CreateInventoryItemRequest();
            req.setName(capitalize(itemName.trim()));
            req.setQuantity(addQty);
            req.setUnit(entities.getUnit() != null ? entities.getUnit() : "pcs");
            req.setBrand(entities.getBrand());
            req.setPurchasePrice(entities.getPrice());

            InventoryItemDto created = inventoryService.createItem(homeId, req);

            return ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(VoiceIntent.ADD_INVENTORY_ITEM)
                    .message(String.format("Added new product %s (%s %s) to inventory",
                            created.getName(),
                            created.getQuantity().stripTrailingZeros().toPlainString(),
                            created.getUnit()))
                    .data(created)
                    .navigation(Map.of("route", "/inventory", "itemId", created.getId().toString()))
                    .build();
        }
    }

    private ExecuteCommandResponse executeGetItemStatus(UUID homeId, VoiceEntities entities, String lang) {
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
            String location = (item.getStorageLocation() != null && !item.getStorageLocation().isBlank())
                    ? item.getStorageLocation()
                    : "inventory";
            String unit = item.getUnit() != null ? item.getUnit() : "pcs";

            String msg;
            if ("TANGLISH".equalsIgnoreCase(lang)) {
                msg = String.format("Ungaloda %s-la %s %s %s irukku.", location, qtyStr, unit, item.getName());
                if (onShoppingList) {
                    msg += " Idhu ungaloda shopping list-layum irukku.";
                }
            } else if ("TA".equalsIgnoreCase(lang)) {
                msg = String.format("உங்கள் %sல் %s %s %s உள்ளது.", location, qtyStr, unit, item.getName());
                if (onShoppingList) {
                    msg += " இது உங்கள் ஷாப்பிங் பட்டியலிலும் உள்ளது.";
                }
            } else {
                msg = String.format("You have %s %s of %s available in your %s.", qtyStr, unit, item.getName(), location);
                if (onShoppingList) {
                    msg += " It is also currently on your shopping list.";
                }
            }

            return ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(VoiceIntent.GET_ITEM_STATUS)
                    .message(msg)
                    .data(InventoryItemDto.fromEntity(item))
                    .navigation(Map.of("route", "/inventory", "itemId", item.getId().toString()))
                    .build();
        } else if (onShoppingList) {
            String msg;
            if ("TANGLISH".equalsIgnoreCase(lang)) {
                msg = capitalize(itemName) + " ippo ungaloda shopping list-la irukku, inventory-la illa.";
            } else if ("TA".equalsIgnoreCase(lang)) {
                msg = capitalize(itemName) + " இப்போது உங்கள் ஷாப்பிங் பட்டியலில் உள்ளது, இருப்பில் இல்லை.";
            } else {
                msg = capitalize(itemName) + " is currently on your shopping list, not recorded in inventory.";
            }
            return ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(VoiceIntent.GET_ITEM_STATUS)
                    .message(msg)
                    .navigation(Map.of("route", "/shopping"))
                    .build();
        } else {
            String msg;
            if ("TANGLISH".equalsIgnoreCase(lang)) {
                msg = capitalize(itemName) + " ungaloda inventory-layo shopping list-layo illa.";
            } else if ("TA".equalsIgnoreCase(lang)) {
                msg = capitalize(itemName) + " உங்கள் இருப்பிலோ ஷாப்பிங் பட்டியலிலோ இல்லை.";
            } else {
                msg = capitalize(itemName) + " was not found in your inventory or shopping list.";
            }
            return ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(VoiceIntent.GET_ITEM_STATUS)
                    .message(msg)
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

    private ExecuteCommandResponse executeClearShoppingList(UUID homeId) {
        if (!homeSecurityService.canEditShoppingList(homeId)) {
            throw new AccessDeniedException("Permission denied to edit shopping list");
        }
        ShoppingListDto defaultList = shoppingService.getDefaultShoppingList(homeId);
        List<ShoppingListItem> items = shoppingListItemRepository
                .findAllByShoppingListIdOrderByIsCompletedAscCreatedAtDesc(defaultList.getId());
        shoppingListItemRepository.deleteAll(items);
        return ExecuteCommandResponse.builder()
                .success(true)
                .intent(VoiceIntent.CLEAR_SHOPPING_LIST)
                .message("Shopping list has been cleared.")
                .executionStatus("EXECUTED")
                .navigation(Map.of("route", "/shopping"))
                .build();
    }

    private ExecuteCommandResponse executeUpdateShoppingItem(UUID homeId, VoiceEntities entities) {
        if (!homeSecurityService.canEditShoppingList(homeId)) {
            throw new AccessDeniedException("Permission denied to edit shopping list");
        }
        String itemName = entities.getItemName();
        if (itemName == null || itemName.isBlank()) {
            return ExecuteCommandResponse.builder()
                    .success(false)
                    .intent(VoiceIntent.UPDATE_SHOPPING_ITEM)
                    .message("Item name was not specified.")
                    .executionStatus("FAILED")
                    .build();
        }

        ShoppingListDto defaultList = shoppingService.getDefaultShoppingList(homeId);
        List<ShoppingListItem> items = shoppingListItemRepository
                .findAllByShoppingListIdOrderByIsCompletedAscCreatedAtDesc(defaultList.getId());

        ShoppingListItem matched = null;
        for (ShoppingListItem item : items) {
            if (item.getItemName().equalsIgnoreCase(itemName.trim())
                    || (entities.getMatchedInventoryItemId() != null && item.getInventoryItem() != null
                    && item.getInventoryItem().getId().equals(entities.getMatchedInventoryItemId()))) {
                matched = item;
                break;
            }
        }

        if (matched == null) {
            return ExecuteCommandResponse.builder()
                    .success(false)
                    .intent(VoiceIntent.UPDATE_SHOPPING_ITEM)
                    .message("Could not find '" + itemName + "' in your shopping list.")
                    .executionStatus("FAILED")
                    .build();
        }

        if (entities.getQuantity() != null) {
            matched.setQuantity(entities.getQuantity());
        }
        if (entities.getUnit() != null && !entities.getUnit().isBlank()) {
            matched.setUnit(entities.getUnit());
        }
        ShoppingListItem saved = shoppingListItemRepository.save(matched);

        return ExecuteCommandResponse.builder()
                .success(true)
                .intent(VoiceIntent.UPDATE_SHOPPING_ITEM)
                .message("Updated " + saved.getItemName() + " to " + saved.getQuantity() + " " + saved.getUnit() + " in shopping list.")
                .data(ShoppingListItemDto.fromEntity(saved))
                .executionStatus("EXECUTED")
                .navigation(Map.of("route", "/shopping"))
                .build();
    }

    private ExecuteCommandResponse executeRemoveInventoryItem(UUID homeId, VoiceEntities entities) {
        if (!homeSecurityService.canManageInventory(homeId)) {
            throw new AccessDeniedException("Permission denied to manage inventory");
        }
        InventoryItem item = resolveInventoryItem(homeId, entities);
        if (item == null) {
            return ExecuteCommandResponse.builder()
                    .success(false)
                    .intent(VoiceIntent.REMOVE_INVENTORY_ITEM)
                    .message("Could not find item '" + (entities.getItemName() != null ? entities.getItemName() : "unknown") + "' in inventory.")
                    .executionStatus("FAILED")
                    .build();
        }

        item.setIsArchived(true);
        inventoryItemRepository.save(item);
        inventoryService.deleteItem(homeId, item.getId());

        return ExecuteCommandResponse.builder()
                .success(true)
                .intent(VoiceIntent.REMOVE_INVENTORY_ITEM)
                .message("Removed " + item.getName() + " from inventory.")
                .executionStatus("EXECUTED")
                .navigation(Map.of("route", "/inventory"))
                .build();
    }

    private ExecuteCommandResponse executeSearchProduct(UUID homeId, VoiceEntities entities) {
        String query = entities.getItemName() != null ? entities.getItemName().trim() : "";
        ProductMatchResult match = productResolutionService.resolveProduct(homeId, query, query);

        List<InventoryItem> localMatches = inventoryItemRepository.findAllByHomeIdAndIsArchivedFalseOrderByNameAsc(homeId)
                .stream()
                .filter(i -> i.getName().toLowerCase().contains(query.toLowerCase()))
                .limit(5)
                .toList();

        var catalogMatches = productRepository.searchProducts(query);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("query", query);
        data.put("bestMatch", match);
        data.put("inventoryItems", localMatches.stream().map(InventoryItemDto::fromEntity).toList());
        data.put("catalogMatches", catalogMatches);

        String msg = localMatches.isEmpty()
                ? "Searched product catalog for '" + query + "'."
                : "Found " + localMatches.size() + " inventory item(s) matching '" + query + "'.";

        return ExecuteCommandResponse.builder()
                .success(true)
                .intent(VoiceIntent.SEARCH_PRODUCT)
                .message(msg)
                .data(data)
                .executionStatus("EXECUTED")
                .navigation(Map.of("route", "/inventory", "query", query))
                .build();
    }

    private ExecuteCommandResponse executeGetProductDetails(UUID homeId, VoiceEntities entities) {
        InventoryItem item = resolveInventoryItem(homeId, entities);
        if (item != null) {
            return ExecuteCommandResponse.builder()
                    .success(true)
                    .intent(VoiceIntent.GET_PRODUCT_DETAILS)
                    .message(item.getName() + ": " + item.getQuantity() + " " + item.getUnit() + " in stock.")
                    .data(InventoryItemDto.fromEntity(item))
                    .executionStatus("EXECUTED")
                    .navigation(Map.of("route", "/inventory/" + item.getId()))
                    .build();
        }
        return executeSearchProduct(homeId, entities);
    }

    private String capitalize(String str) {
        if (str == null || str.isEmpty()) return str;
        return Character.toUpperCase(str.charAt(0)) + str.substring(1);
    }
}
