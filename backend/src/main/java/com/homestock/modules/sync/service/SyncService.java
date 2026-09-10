package com.homestock.modules.sync.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.core.util.SecurityUtils;
import com.homestock.modules.category.entity.Category;
import com.homestock.modules.category.repository.CategoryRepository;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.inventory.entity.*;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.inventory.repository.StockTransactionRepository;
import com.homestock.modules.notification.service.NotificationEngine;
import com.homestock.modules.purchase.entity.Purchase;
import com.homestock.modules.purchase.entity.PurchaseItem;
import com.homestock.modules.purchase.repository.PurchaseItemRepository;
import com.homestock.modules.purchase.repository.PurchaseRepository;
import com.homestock.modules.shopping.entity.ShoppingList;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.shopping.repository.ShoppingListRepository;
import com.homestock.modules.shopping.service.ShoppingService;
import com.homestock.modules.store.entity.Store;
import com.homestock.modules.store.repository.StoreRepository;
import com.homestock.modules.sync.dto.*;
import com.homestock.modules.sync.entity.HomeChangeLog;
import com.homestock.modules.sync.entity.ProcessedOperation;
import com.homestock.modules.sync.repository.ProcessedOperationRepository;
import com.homestock.modules.user.entity.User;
import com.homestock.modules.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.*;

@Service
@RequiredArgsConstructor
public class SyncService {

    private static final Logger log = LoggerFactory.getLogger(SyncService.class);

    private final ProcessedOperationRepository processedOperationRepository;
    private final InventoryItemRepository inventoryItemRepository;
    private final StockTransactionRepository stockTransactionRepository;
    private final ShoppingListRepository shoppingListRepository;
    private final ShoppingListItemRepository shoppingListItemRepository;
    private final PurchaseRepository purchaseRepository;
    private final PurchaseItemRepository purchaseItemRepository;
    private final CategoryRepository categoryRepository;
    private final StoreRepository storeRepository;
    private final HomeRepository homeRepository;
    private final UserRepository userRepository;
    private final ShoppingService shoppingService;
    private final ObjectMapper objectMapper;
    private final com.homestock.modules.consumption.service.ConsumptionService consumptionService;
    private final HomeChangeLogService homeChangeLogService;
    private final NotificationEngine notificationEngine;

    /**
     * Process batch of offline operations idempotently.
     */
    @Transactional
    public SyncPushResponse pushOperations(SyncRequest request) {
        UUID homeId = request.getHomeId();
        Home home = homeRepository.findById(homeId)
                .orElseThrow(() -> new ResourceNotFoundException("Home not found"));

        UUID currentUserId = null;
        User currentUser = null;
        try {
            currentUserId = SecurityUtils.getCurrentUserId();
            currentUser = userRepository.findById(currentUserId).orElse(null);
        } catch (Exception ignored) {}

        List<SyncOperationResultDto> results = new ArrayList<>();

        if (request.getOperations() != null) {
            for (SyncOperationDto op : request.getOperations()) {
                SyncOperationResultDto result = processSingleOperation(op, home, currentUser);
                results.add(result);
            }
        }

        return SyncPushResponse.builder().results(results).build();
    }

    private SyncOperationResultDto processSingleOperation(SyncOperationDto op, Home home, User currentUser) {
        String opId = op.getOperationId();

        // 1. Idempotency check: return ALREADY_PROCESSED if operation was already handled
        if (processedOperationRepository.existsByOperationId(opId)) {
            return SyncOperationResultDto.builder()
                    .operationId(opId)
                    .status("ALREADY_PROCESSED")
                    .build();
        }

        try {
            String opType = op.getOperationType();
            Map<String, Object> payload = op.getPayload() != null ? op.getPayload() : Collections.emptyMap();

            switch (opType) {
                case "CREATE_ITEM" -> handleCreateItem(op, home, currentUser, payload);
                case "UPDATE_ITEM" -> handleUpdateItem(op, home, currentUser, payload);
                case "STOCK_IN", "STOCK_OUT", "EXPIRED", "DAMAGED", "ADJUSTMENT" ->
                        handleStockUpdate(op, home, currentUser, payload);
                case "DELETE_ITEM" -> handleDeleteItem(op, home);
                case "ADD_SHOPPING_ITEM" -> handleAddShoppingItem(op, home, currentUser, payload);
                case "UPDATE_SHOPPING_ITEM" -> handleUpdateShoppingItem(op, currentUser, payload);
                case "TOGGLE_SHOPPING_ITEM" -> handleToggleShoppingItem(op, currentUser, payload);
                case "DELETE_SHOPPING_ITEM" -> handleDeleteShoppingItem(op);
                case "RECORD_PURCHASE" -> handleRecordPurchase(op, home, currentUser, payload);
                case "CREATE_STORE" -> handleCreateStore(op, home, payload);
                case "CLEAR_COMPLETED_SHOPPING" -> handleClearCompletedShopping(home);
                case "CREATE_CATEGORY" -> handleCreateCategory(op, home, payload);
                case "CONFIRM_STATUS" -> handleConfirmStatus(op, home, payload);
                case "CONFIRM_QUANTITY" -> handleConfirmQuantity(op, home, payload);
                default -> log.warn("Unknown sync operation type: {}", opType);
            }

            // Record successful operation
            ProcessedOperation record = ProcessedOperation.builder()
                    .operationId(opId)
                    .homeId(home.getId())
                    .userId(currentUser != null ? currentUser.getId() : null)
                    .operationType(op.getOperationType())
                    .entityType(op.getEntityType())
                    .entityId(op.getEntityId())
                    .status("SYNCED")
                    .processedAt(Instant.now())
                    .build();
            processedOperationRepository.save(record);

            return SyncOperationResultDto.builder()
                    .operationId(opId)
                    .status("SYNCED")
                    .build();

        } catch (Exception e) {
            log.error("Failed to process sync operation {}: {}", opId, e.getMessage(), e);

            ProcessedOperation record = ProcessedOperation.builder()
                    .operationId(opId)
                    .homeId(home.getId())
                    .userId(currentUser != null ? currentUser.getId() : null)
                    .operationType(op.getOperationType())
                    .entityType(op.getEntityType())
                    .entityId(op.getEntityId())
                    .status("FAILED")
                    .errorMessage(e.getMessage())
                    .processedAt(Instant.now())
                    .build();
            processedOperationRepository.save(record);

            return SyncOperationResultDto.builder()
                    .operationId(opId)
                    .status("FAILED")
                    .errorMessage(e.getMessage())
                    .build();
        }
    }

    private void handleCreateItem(SyncOperationDto op, Home home, User user, Map<String, Object> payload) {
        UUID itemId = null;
        if (op.getEntityId() != null) {
            try {
                itemId = UUID.fromString(op.getEntityId());
            } catch (Exception ignored) {}
        }

        // If item already exists, treat as update
        if (itemId != null && inventoryItemRepository.existsById(itemId)) {
            handleUpdateItem(op, home, user, payload);
            return;
        }

        Category category = null;
        Object catIdVal = payload.get("categoryId");
        if (catIdVal != null) {
            try {
                category = categoryRepository.findById(UUID.fromString(catIdVal.toString())).orElse(null);
            } catch (Exception ignored) {}
        }
        if (category == null && payload.get("categoryName") != null) {
            category = categoryRepository.findByHomeIdAndNameIgnoreCase(home.getId(), payload.get("categoryName").toString().trim()).orElse(null);
        }

        BigDecimal qty = toBigDecimal(payload.get("quantity"), BigDecimal.ZERO);
        BigDecimal minQty = toBigDecimal(payload.get("minimumQuantity"), BigDecimal.ONE);
        BigDecimal maxQty = payload.get("maximumQuantity") != null ? toBigDecimal(payload.get("maximumQuantity"), null) : null;
        BigDecimal price = payload.get("purchasePrice") != null ? toBigDecimal(payload.get("purchasePrice"), null) : null;

        InventoryItem.InventoryItemBuilder builder = InventoryItem.builder()
                .home(home)
                .category(category)
                .name(payload.getOrDefault("name", "Unnamed Item").toString().trim())
                .brand(payload.get("brand") != null ? payload.get("brand").toString().trim() : null)
                .quantity(qty)
                .unit(payload.getOrDefault("unit", "pcs").toString().trim())
                .minimumQuantity(minQty)
                .maximumQuantity(maxQty)
                .storageLocation(payload.get("storageLocation") != null ? payload.get("storageLocation").toString() : null)
                .purchasePrice(price)
                .purchaseDate(parseLocalDate(payload.get("purchaseDate")))
                .expiryDate(parseLocalDate(payload.get("expiryDate")))
                .notes(payload.get("notes") != null ? payload.get("notes").toString() : null)
                .imageUrl(payload.get("imageUrl") != null ? payload.get("imageUrl").toString() : null)
                .isArchived(false);

        InventoryItem item = builder.build();
        if (itemId != null) {
            item.setId(itemId);
        }

        InventoryItem savedItem = inventoryItemRepository.save(item);
        UUID effectiveItemId = savedItem != null && savedItem.getId() != null ? savedItem.getId() : (itemId != null ? itemId : UUID.randomUUID());

        // Record change log
        homeChangeLogService.recordChange(home, "INVENTORY_ITEM", effectiveItemId, "INSERT", serializePayload(payload), op.getOperationId());

        // Record initial stock transaction
        if (qty.compareTo(BigDecimal.ZERO) > 0) {
            StockTransaction tx = StockTransaction.builder()
                    .home(home)
                    .item(savedItem != null ? savedItem : item)
                    .user(user)
                    .transactionType(TransactionType.STOCK_IN)
                    .quantityChange(qty)
                    .previousQuantity(BigDecimal.ZERO)
                    .newQuantity(qty)
                    .unit(item.getUnit())
                    .reason("Initial offline stock addition")
                    .build();
            StockTransaction savedTx = stockTransactionRepository.save(tx);
            UUID effectiveTxId = savedTx != null && savedTx.getId() != null ? savedTx.getId() : UUID.randomUUID();
            homeChangeLogService.recordChange(home, "STOCK_TRANSACTION", effectiveTxId, "INSERT", null, op.getOperationId());
        }
    }

    private void handleUpdateItem(SyncOperationDto op, Home home, User user, Map<String, Object> payload) {
        if (op.getEntityId() == null) return;
        UUID itemId = UUID.fromString(op.getEntityId());
        Optional<InventoryItem> optItem = inventoryItemRepository.findByIdAndHomeId(itemId, home.getId());
        if (optItem.isEmpty()) return;

        InventoryItem item = optItem.get();

        if (payload.containsKey("name") && payload.get("name") != null) {
            item.setName(payload.get("name").toString().trim());
        }
        if (payload.containsKey("brand")) {
            item.setBrand(payload.get("brand") != null ? payload.get("brand").toString().trim() : null);
        }
        if (payload.containsKey("unit") && payload.get("unit") != null) {
            item.setUnit(payload.get("unit").toString().trim());
        }
        if (payload.containsKey("minimumQuantity") && payload.get("minimumQuantity") != null) {
            item.setMinimumQuantity(toBigDecimal(payload.get("minimumQuantity"), BigDecimal.ONE));
        }
        if (payload.containsKey("maximumQuantity")) {
            item.setMaximumQuantity(payload.get("maximumQuantity") != null ? toBigDecimal(payload.get("maximumQuantity"), null) : null);
        }
        if (payload.containsKey("storageLocation")) {
            item.setStorageLocation(payload.get("storageLocation") != null ? payload.get("storageLocation").toString() : null);
        }
        if (payload.containsKey("purchasePrice")) {
            item.setPurchasePrice(payload.get("purchasePrice") != null ? toBigDecimal(payload.get("purchasePrice"), null) : null);
        }
        if (payload.containsKey("purchaseDate")) {
            item.setPurchaseDate(parseLocalDate(payload.get("purchaseDate")));
        }
        if (payload.containsKey("expiryDate")) {
            item.setExpiryDate(parseLocalDate(payload.get("expiryDate")));
        }
        if (payload.containsKey("notes")) {
            item.setNotes(payload.get("notes") != null ? payload.get("notes").toString() : null);
        }
        if (payload.containsKey("categoryId") || payload.containsKey("categoryName")) {
            Category category = null;
            Object catId = payload.get("categoryId");
            if (catId != null) {
                try {
                    category = categoryRepository.findById(UUID.fromString(catId.toString())).orElse(null);
                } catch (Exception ignored) {}
            }
            if (category == null && payload.get("categoryName") != null) {
                category = categoryRepository.findByHomeIdAndNameIgnoreCase(home.getId(), payload.get("categoryName").toString().trim()).orElse(null);
            }
            item.setCategory(category);
        }

        InventoryItem saved = inventoryItemRepository.save(item);
        UUID effectiveId = saved != null && saved.getId() != null ? saved.getId() : item.getId();
        homeChangeLogService.recordChange(home, "INVENTORY_ITEM", effectiveId, "UPDATE", serializePayload(payload), op.getOperationId());
    }

    /**
     * Delta-based stock update: applies the transaction delta (STOCK_IN, STOCK_OUT, etc.)
     * rather than absolute quantity overwrite!
     * Concurrency-safe delta stock update using pessimistic write locking:
     * Applies delta (STOCK_IN, STOCK_OUT) rather than absolute quantity overwrite!
     */
    private void handleStockUpdate(SyncOperationDto op, Home home, User user, Map<String, Object> payload) {
        if (op.getEntityId() == null) return;
        UUID itemId = UUID.fromString(op.getEntityId());

        // Use pessimistic lock to serialize concurrent stock deltas safely
        Optional<InventoryItem> optItem = inventoryItemRepository.findWithLockByIdAndHomeId(itemId, home.getId());
        if (optItem.isEmpty()) {
            optItem = inventoryItemRepository.findByIdAndHomeId(itemId, home.getId());
        }
        if (optItem.isEmpty()) return;

        InventoryItem item = optItem.get();
        BigDecimal currentQty = item.getQuantity();

        BigDecimal change = toBigDecimal(payload.get("quantityChange"), BigDecimal.ONE);
        String txTypeStr = op.getOperationType();
        TransactionType txType = TransactionType.valueOf(txTypeStr);

        BigDecimal newQty;
        switch (txType) {
            case STOCK_IN -> newQty = currentQty.add(change);
            case STOCK_OUT, EXPIRED, DAMAGED -> {
                // If current quantity is less than change due to concurrent edits, floor at 0
                newQty = currentQty.compareTo(change) >= 0 ? currentQty.subtract(change) : BigDecimal.ZERO;
            }
            case ADJUSTMENT -> newQty = change;
            default -> newQty = currentQty;
        }

        item.setQuantity(newQty);
        inventoryItemRepository.save(item);

        StockTransaction tx = StockTransaction.builder()
                .home(home)
                .item(item)
                .user(user)
                .transactionType(txType)
                .quantityChange(change)
                .previousQuantity(currentQty)
                .newQuantity(newQty)
                .unit(item.getUnit())
                .reason(payload.get("reason") != null ? payload.get("reason").toString() : "Offline sync update")
                .build();
        StockTransaction savedTx = stockTransactionRepository.save(tx);
        UUID effectiveTxId = savedTx != null && savedTx.getId() != null ? savedTx.getId() : UUID.randomUUID();

        // Record change log entries
        homeChangeLogService.recordChange(home, "INVENTORY_ITEM", item.getId(), "UPDATE", serializePayload(payload), op.getOperationId());
        homeChangeLogService.recordChange(home, "STOCK_TRANSACTION", effectiveTxId, "INSERT", null, op.getOperationId());

        // Recalculate consumption profile for the affected item
        consumptionService.recalculateForItem(home, item.getId());

        // Family notification dispatch
        notificationEngine.notifyStockUpdated(home, user, item, change, item.getUnit());
        if (newQty.compareTo(BigDecimal.ZERO) == 0) {
            notificationEngine.notifyOutOfStock(home, item, user);
        } else if (newQty.compareTo(item.getMinimumQuantity()) <= 0) {
            notificationEngine.notifyLowStock(home, item, user);
        }
    }

    private void handleDeleteItem(SyncOperationDto op, Home home) {
        if (op.getEntityId() == null) return;
        UUID itemId = UUID.fromString(op.getEntityId());
        inventoryItemRepository.findByIdAndHomeId(itemId, home.getId()).ifPresent(item -> {
            item.setIsArchived(true);
            inventoryItemRepository.save(item);
            homeChangeLogService.recordChange(home, "INVENTORY_ITEM", itemId, "DELETE", null, op.getOperationId());
        });
    }

    private void handleAddShoppingItem(SyncOperationDto op, Home home, User user, Map<String, Object> payload) {
        ShoppingList list = shoppingService.getOrCreateDefaultListEntity(home);

        UUID itemId = null;
        if (op.getEntityId() != null) {
            try {
                itemId = UUID.fromString(op.getEntityId());
            } catch (Exception ignored) {}
        }

        if (itemId != null && shoppingListItemRepository.existsById(itemId)) {
            return;
        }

        InventoryItem invItem = null;
        Object invId = payload.get("inventoryItemId");
        if (invId != null) {
            try {
                invItem = inventoryItemRepository.findById(UUID.fromString(invId.toString())).orElse(null);
            } catch (Exception ignored) {}
        }

        ShoppingListItem item = ShoppingListItem.builder()
                .shoppingList(list)
                .inventoryItem(invItem)
                .itemName(payload.getOrDefault("itemName", "Shopping Item").toString())
                .quantity(toBigDecimal(payload.get("quantity"), BigDecimal.ONE))
                .unit(payload.getOrDefault("unit", "pcs").toString())
                .isCompleted(Boolean.TRUE.equals(payload.get("isCompleted")))
                .isAutoGenerated(Boolean.TRUE.equals(payload.get("isAutoGenerated")))
                .addedBy(user)
                .notes(payload.get("notes") != null ? payload.get("notes").toString() : null)
                .build();

        if (itemId != null) {
            item.setId(itemId);
        }

        ShoppingListItem saved = shoppingListItemRepository.save(item);
        homeChangeLogService.recordChange(home, "SHOPPING_LIST_ITEM", saved.getId(), "INSERT", serializePayload(payload), op.getOperationId());

        // Notify other family members
        notificationEngine.notifyShoppingListUpdate(home, user, List.of(saved.getItemName()));
    }

    private void handleUpdateShoppingItem(SyncOperationDto op, User user, Map<String, Object> payload) {
        if (op.getEntityId() == null) return;
        UUID itemId = UUID.fromString(op.getEntityId());
        shoppingListItemRepository.findById(itemId).ifPresent(item -> {
            if (payload.containsKey("itemName") && payload.get("itemName") != null) {
                item.setItemName(payload.get("itemName").toString().trim());
            }
            if (payload.containsKey("quantity") && payload.get("quantity") != null) {
                item.setQuantity(toBigDecimal(payload.get("quantity"), item.getQuantity()));
            }
            if (payload.containsKey("unit") && payload.get("unit") != null) {
                item.setUnit(payload.get("unit").toString().trim());
            }
            if (payload.containsKey("notes")) {
                item.setNotes(payload.get("notes") != null ? payload.get("notes").toString() : null);
            }
            ShoppingListItem saved = shoppingListItemRepository.save(item);
            Home home = saved.getShoppingList().getHome();
            homeChangeLogService.recordChange(home, "SHOPPING_LIST_ITEM", saved.getId(), "UPDATE", serializePayload(payload), op.getOperationId());
        });
    }

    private void handleToggleShoppingItem(SyncOperationDto op, User user, Map<String, Object> payload) {
        if (op.getEntityId() == null) return;
        UUID itemId = UUID.fromString(op.getEntityId());
        shoppingListItemRepository.findById(itemId).ifPresent(item -> {
            boolean completed = payload.containsKey("isCompleted")
                    ? Boolean.TRUE.equals(payload.get("isCompleted"))
                    : !Boolean.TRUE.equals(item.getIsCompleted());
            item.setIsCompleted(completed);
            item.setCompletedBy(completed ? user : null);
            item.setCompletedAt(completed ? Instant.now() : null);
            ShoppingListItem saved = shoppingListItemRepository.save(item);
            Home home = saved.getShoppingList().getHome();
            homeChangeLogService.recordChange(home, "SHOPPING_LIST_ITEM", saved.getId(), "UPDATE", serializePayload(payload), op.getOperationId());
        });
    }

    private void handleDeleteShoppingItem(SyncOperationDto op) {
        if (op.getEntityId() == null) return;
        UUID itemId = UUID.fromString(op.getEntityId());
        shoppingListItemRepository.findById(itemId).ifPresent(item -> {
            Home home = item.getShoppingList().getHome();
            shoppingListItemRepository.delete(item);
            homeChangeLogService.recordChange(home, "SHOPPING_LIST_ITEM", itemId, "DELETE", null, op.getOperationId());
        });
    }

    private void handleRecordPurchase(SyncOperationDto op, Home home, User user, Map<String, Object> payload) {
        UUID purchaseId = null;
        if (op.getEntityId() != null) {
            try {
                purchaseId = UUID.fromString(op.getEntityId());
            } catch (Exception ignored) {}
        }

        if (purchaseId != null && purchaseRepository.existsById(purchaseId)) {
            return;
        }

        Store store = null;
        Object storeId = payload.get("storeId");
        if (storeId != null) {
            try {
                store = storeRepository.findByIdAndHomeId(UUID.fromString(storeId.toString()), home.getId()).orElse(null);
            } catch (Exception ignored) {}
        }

        Purchase purchase = Purchase.builder()
                .home(home)
                .store(store)
                .recordedBy(user)
                .totalAmount(toBigDecimal(payload.get("totalAmount"), BigDecimal.ZERO))
                .purchaseDate(parseLocalDate(payload.get("purchaseDate")))
                .receiptImageUrl(payload.get("receiptImageUrl") != null ? payload.get("receiptImageUrl").toString() : null)
                .notes(payload.get("notes") != null ? payload.get("notes").toString() : null)
                .build();

        if (purchaseId != null) {
            purchase.setId(purchaseId);
        }

        Purchase savedPurchase = purchaseRepository.save(purchase);
        homeChangeLogService.recordChange(home, "PURCHASE", savedPurchase.getId(), "INSERT", serializePayload(payload), op.getOperationId());

        // Process purchase items
        Object itemsRaw = payload.get("items");
        if (itemsRaw instanceof List<?> itemsList) {
            for (Object obj : itemsList) {
                if (obj instanceof Map<?, ?> itemMap) {
                    BigDecimal qty = toBigDecimal(itemMap.get("quantity"), BigDecimal.ONE);
                    BigDecimal unitPrice = toBigDecimal(itemMap.get("unitPrice"), BigDecimal.ZERO);
                    BigDecimal total = toBigDecimal(itemMap.get("totalPrice"), unitPrice.multiply(qty));

                    InventoryItem linkedItem = null;
                    Object invId = itemMap.get("inventoryItemId");
                    if (invId != null) {
                        try {
                            linkedItem = inventoryItemRepository.findById(UUID.fromString(invId.toString())).orElse(null);
                        } catch (Exception ignored) {}
                    }

                    String itemName = itemMap.get("itemName") != null ? itemMap.get("itemName").toString() : "Item";
                    String unit = itemMap.get("unit") != null ? itemMap.get("unit").toString() : "pcs";

                    PurchaseItem pItem = PurchaseItem.builder()
                            .purchase(savedPurchase)
                            .inventoryItem(linkedItem)
                            .itemName(itemName)
                            .quantity(qty)
                            .unit(unit)
                            .unitPrice(unitPrice)
                            .totalPrice(total)
                            .build();
                    purchaseItemRepository.save(pItem);

                    // Restock linked inventory item
                    if (linkedItem != null) {
                        BigDecimal prev = linkedItem.getQuantity();
                        BigDecimal nQty = prev.add(qty);
                        linkedItem.setQuantity(nQty);
                        inventoryItemRepository.save(linkedItem);

                        StockTransaction tx = StockTransaction.builder()
                                .home(home)
                                .item(linkedItem)
                                .user(user)
                                .transactionType(TransactionType.STOCK_IN)
                                .quantityChange(qty)
                                .previousQuantity(prev)
                                .newQuantity(nQty)
                                .unit(linkedItem.getUnit())
                                .reason("Purchase restock")
                                .build();
                        StockTransaction savedTx = stockTransactionRepository.save(tx);

                        homeChangeLogService.recordChange(home, "INVENTORY_ITEM", linkedItem.getId(), "UPDATE", null, op.getOperationId());
                        homeChangeLogService.recordChange(home, "STOCK_TRANSACTION", savedTx.getId(), "INSERT", null, op.getOperationId());

                        // Trigger consumption learning for the restocked item
                        consumptionService.onPurchaseRecorded(home, linkedItem, qty, savedPurchase.getPurchaseDate());
                    }
                }
            }
        }

        // Notify family members
        notificationEngine.notifyPurchaseRecorded(home, user, savedPurchase);
    }

    private void handleConfirmStatus(SyncOperationDto op, Home home, Map<String, Object> payload) {
        if (op.getEntityId() == null) return;
        try {
            UUID itemId = UUID.fromString(op.getEntityId());
            String statusStr = payload.get("status") != null ? payload.get("status").toString() : null;
            String actionStr = payload.get("action") != null ? payload.get("action").toString() : null;
            com.homestock.modules.consumption.entity.QuantityStatus status = null;
            if (statusStr != null) {
                try {
                    status = com.homestock.modules.consumption.entity.QuantityStatus.valueOf(statusStr);
                } catch (Exception ignored) {}
            }
            com.homestock.modules.consumption.dto.ConfirmStatusRequest req = com.homestock.modules.consumption.dto.ConfirmStatusRequest.builder()
                    .status(status)
                    .action(actionStr)
                    .build();
            consumptionService.confirmStatus(itemId, req);
            homeChangeLogService.recordChange(home, "INVENTORY_ITEM", itemId, "UPDATE", serializePayload(payload), op.getOperationId());
        } catch (Exception e) {
            log.warn("Failed to process CONFIRM_STATUS sync operation: {}", e.getMessage());
        }
    }

    private void handleConfirmQuantity(SyncOperationDto op, Home home, Map<String, Object> payload) {
        if (op.getEntityId() == null) return;
        try {
            UUID itemId = UUID.fromString(op.getEntityId());
            BigDecimal qty = toBigDecimal(payload.get("quantity"), BigDecimal.ZERO);
            String unit = payload.get("unit") != null ? payload.get("unit").toString() : null;
            com.homestock.modules.consumption.dto.ConfirmQuantityRequest req = com.homestock.modules.consumption.dto.ConfirmQuantityRequest.builder()
                    .quantity(qty)
                    .unit(unit)
                    .build();
            consumptionService.confirmQuantity(itemId, req);
            homeChangeLogService.recordChange(home, "INVENTORY_ITEM", itemId, "UPDATE", serializePayload(payload), op.getOperationId());
        } catch (Exception e) {
            log.warn("Failed to process CONFIRM_QUANTITY sync operation: {}", e.getMessage());
        }
    }

    private void handleCreateStore(SyncOperationDto op, Home home, Map<String, Object> payload) {
        UUID storeId = null;
        if (op.getEntityId() != null) {
            try {
                storeId = UUID.fromString(op.getEntityId());
            } catch (Exception ignored) {}
        }

        if (storeId != null && storeRepository.existsById(storeId)) {
            return;
        }

        String name = payload.getOrDefault("name", "Store").toString().trim();
        String location = payload.get("location") != null ? payload.get("location").toString().trim() : null;

        Store store = Store.builder()
                .home(home)
                .name(name)
                .location(location)
                .build();

        if (storeId != null) {
            store.setId(storeId);
        }

        Store savedStore = storeRepository.save(store);
        UUID effectiveStoreId = savedStore != null && savedStore.getId() != null ? savedStore.getId() : (storeId != null ? storeId : UUID.randomUUID());
        homeChangeLogService.recordChange(home, "STORE", effectiveStoreId, "INSERT", serializePayload(payload), op.getOperationId());
    }

    private void handleClearCompletedShopping(Home home) {
        ShoppingList list = shoppingService.getOrCreateDefaultListEntity(home);
        List<ShoppingListItem> completed = shoppingListItemRepository.findAllCompletedByShoppingListId(list.getId());
        for (ShoppingListItem item : completed) {
            homeChangeLogService.recordChange(home, "SHOPPING_LIST_ITEM", item.getId(), "DELETE", null, null);
        }
        shoppingListItemRepository.deleteAllCompletedByShoppingListId(list.getId());
    }

    private void handleCreateCategory(SyncOperationDto op, Home home, Map<String, Object> payload) {
        UUID categoryId = null;
        if (op.getEntityId() != null) {
            try {
                categoryId = UUID.fromString(op.getEntityId());
            } catch (Exception ignored) {}
        }

        if (categoryId != null && categoryRepository.existsById(categoryId)) {
            return;
        }

        String name = payload.getOrDefault("name", "Category").toString().trim();
        String icon = payload.getOrDefault("icon", "category").toString();
        String colorHex = payload.getOrDefault("colorHex", "#6366F1").toString();
        int displayOrder = payload.get("displayOrder") != null ? Integer.parseInt(payload.get("displayOrder").toString()) : 0;

        Category category = Category.builder()
                .home(home)
                .name(name)
                .icon(icon)
                .colorHex(colorHex)
                .displayOrder(displayOrder)
                .build();

        if (categoryId != null) {
            category.setId(categoryId);
        }

        Category saved = categoryRepository.save(category);
        UUID effectiveCatId = saved != null && saved.getId() != null ? saved.getId() : (categoryId != null ? categoryId : UUID.randomUUID());
        homeChangeLogService.recordChange(home, "CATEGORY", effectiveCatId, "INSERT", serializePayload(payload), op.getOperationId());
    }

    @Transactional(readOnly = true)
    public SyncPullResponse pullChanges(UUID homeId, Instant since) {
        return pullChanges(homeId, since, null, 500);
    }

    @Transactional(readOnly = true)
    public SyncPullResponse pullChanges(UUID homeId, Instant since, Long sinceVersion) {
        return pullChanges(homeId, since, sinceVersion, 500);
    }

    /**
     * Pull incremental server changes since the given timestamp or version cursor.
     */
    @Transactional(readOnly = true)
    public SyncPullResponse pullChanges(UUID homeId, Instant since, Long sinceVersion, Integer limit) {
        Instant serverTimestamp = Instant.now();
        Long currentServerVersion = homeChangeLogService.getMaxVersion(homeId);

        List<String> deletedShoppingItemIds = new ArrayList<>();
        List<String> deletedInventoryItemIds = new ArrayList<>();
        List<String> deletedStoreIds = new ArrayList<>();
        List<String> deletedCategoryIds = new ArrayList<>();

        int safeLimit = (limit != null && limit > 0) ? Math.min(limit, 1000) : 500;
        Long nextServerVersion = currentServerVersion;
        boolean hasMore = false;

        Instant effectiveSince = since != null ? since : Instant.EPOCH;

        if (sinceVersion != null && sinceVersion > 0) {
            List<HomeChangeLog> changes = homeChangeLogService.getChangesSince(homeId, sinceVersion, safeLimit);
            if (!changes.isEmpty()) {
                long maxVerInBatch = changes.get(changes.size() - 1).getChangeVersion();
                nextServerVersion = maxVerInBatch;
                hasMore = maxVerInBatch < currentServerVersion;

                // If since was not explicitly specified, use the earliest change's timestamp
                if (since == null || since.equals(Instant.EPOCH)) {
                    Instant firstCreated = changes.get(0).getCreatedAt();
                    if (firstCreated != null) {
                        effectiveSince = firstCreated.minusSeconds(1);
                    }
                }
            } else {
                nextServerVersion = currentServerVersion;
                hasMore = false;
            }

            for (HomeChangeLog cl : changes) {
                if ("DELETE".equalsIgnoreCase(cl.getOperationType())) {
                    String idStr = cl.getEntityId() != null ? cl.getEntityId().toString() : "";
                    if (!idStr.isEmpty()) {
                        switch (cl.getEntityType()) {
                            case "SHOPPING_LIST_ITEM" -> deletedShoppingItemIds.add(idStr);
                            case "INVENTORY_ITEM" -> deletedInventoryItemIds.add(idStr);
                            case "STORE" -> deletedStoreIds.add(idStr);
                            case "CATEGORY" -> deletedCategoryIds.add(idStr);
                        }
                    }
                }
            }
        }

        // 1. Categories
        List<Category> categories = categoryRepository.findByHomeIdAndUpdatedAtAfter(homeId, effectiveSince);
        List<Map<String, Object>> catMaps = categories.stream().map(c -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", c.getId().toString());
            map.put("name", c.getName());
            map.put("icon", c.getIcon());
            map.put("colorHex", c.getColorHex());
            map.put("displayOrder", c.getDisplayOrder());
            return map;
        }).toList();

        // 2. Inventory items
        List<InventoryItem> items = inventoryItemRepository.findByHomeIdAndUpdatedAtAfter(homeId, effectiveSince);
        List<Map<String, Object>> itemMaps = items.stream().map(i -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", i.getId().toString());
            map.put("categoryId", i.getCategory() != null ? i.getCategory().getId().toString() : null);
            map.put("categoryName", i.getCategory() != null ? i.getCategory().getName() : "General");
            map.put("categoryIcon", i.getCategory() != null ? i.getCategory().getIcon() : "category");
            map.put("categoryColor", i.getCategory() != null ? i.getCategory().getColorHex() : "#6366F1");
            map.put("name", i.getName());
            map.put("brand", i.getBrand());
            map.put("quantity", i.getQuantity().doubleValue());
            map.put("unit", i.getUnit());
            map.put("minimumQuantity", i.getMinimumQuantity().doubleValue());
            map.put("maximumQuantity", i.getMaximumQuantity() != null ? i.getMaximumQuantity().doubleValue() : null);
            map.put("storageLocation", i.getStorageLocation());
            map.put("purchasePrice", i.getPurchasePrice() != null ? i.getPurchasePrice().doubleValue() : null);
            map.put("purchaseDate", i.getPurchaseDate() != null ? i.getPurchaseDate().toString() : null);
            map.put("expiryDate", i.getExpiryDate() != null ? i.getExpiryDate().toString() : null);
            map.put("imageUrl", i.getImageUrl());
            map.put("notes", i.getNotes());
            map.put("stockStatus", i.calculateStockStatus().name());
            map.put("expiryStatus", i.calculateExpiryStatus().name());
            map.put("daysUntilExpiry", i.getDaysUntilExpiry());
            map.put("isDeleted", Boolean.TRUE.equals(i.getIsArchived()));
            return map;
        }).toList();

        // 3. Stock transactions
        List<StockTransaction> transactions = stockTransactionRepository.findByHomeIdAndCreatedAtAfter(homeId, effectiveSince);
        List<Map<String, Object>> txMaps = transactions.stream().map(t -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", t.getId().toString());
            map.put("itemId", t.getItem().getId().toString());
            map.put("itemName", t.getItem().getName());
            map.put("userName", t.getUser() != null ? t.getUser().getFullName() : "Member");
            map.put("transactionType", t.getTransactionType().name());
            map.put("quantityChange", t.getQuantityChange().doubleValue());
            map.put("previousQuantity", t.getPreviousQuantity().doubleValue());
            map.put("newQuantity", t.getNewQuantity().doubleValue());
            map.put("unit", t.getUnit());
            map.put("reason", t.getReason());
            map.put("createdAt", t.getCreatedAt().toString());
            return map;
        }).toList();

        // 4. Shopping lists
        List<ShoppingList> lists = shoppingListRepository.findByHomeIdAndUpdatedAtAfter(homeId, effectiveSince);
        List<Map<String, Object>> listMaps = lists.stream().map(l -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", l.getId().toString());
            map.put("name", l.getName());
            map.put("isDefault", Boolean.TRUE.equals(l.getIsDefault()));
            return map;
        }).toList();

        // 5. Shopping list items
        List<ShoppingListItem> shoppingItems = shoppingListItemRepository.findByHomeIdAndUpdatedAtAfter(homeId, effectiveSince);
        List<Map<String, Object>> shoppingItemMaps = shoppingItems.stream().map(s -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", s.getId().toString());
            map.put("shoppingListId", s.getShoppingList().getId().toString());
            map.put("inventoryItemId", s.getInventoryItem() != null ? s.getInventoryItem().getId().toString() : null);
            map.put("itemName", s.getItemName());
            map.put("categoryName", s.getInventoryItem() != null && s.getInventoryItem().getCategory() != null
                    ? s.getInventoryItem().getCategory().getName() : null);
            map.put("categoryIcon", s.getInventoryItem() != null && s.getInventoryItem().getCategory() != null
                    ? s.getInventoryItem().getCategory().getIcon() : "category");
            map.put("categoryColor", s.getInventoryItem() != null && s.getInventoryItem().getCategory() != null
                    ? s.getInventoryItem().getCategory().getColorHex() : "#6366F1");
            map.put("quantity", s.getQuantity().doubleValue());
            map.put("unit", s.getUnit());
            map.put("isCompleted", Boolean.TRUE.equals(s.getIsCompleted()));
            map.put("isAutoGenerated", Boolean.TRUE.equals(s.getIsAutoGenerated()));
            map.put("addedByName", s.getAddedBy() != null ? s.getAddedBy().getFullName() : "Member");
            map.put("completedByName", s.getCompletedBy() != null ? s.getCompletedBy().getFullName() : null);
            map.put("completedAt", s.getCompletedAt() != null ? s.getCompletedAt().toString() : null);
            map.put("notes", s.getNotes());
            return map;
        }).toList();

        // 6. Purchases
        List<Purchase> purchases = purchaseRepository.findByHomeIdAndUpdatedAtAfter(homeId, effectiveSince);
        List<Map<String, Object>> purchaseMaps = purchases.stream().map(p -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", p.getId().toString());
            map.put("storeName", p.getStore() != null ? p.getStore().getName() : "Direct");
            map.put("totalAmount", p.getTotalAmount().doubleValue());
            map.put("purchaseDate", p.getPurchaseDate().toString());
            map.put("itemCount", p.getItems() != null ? p.getItems().size() : 0);
            return map;
        }).toList();

        // 7. Stores
        List<Store> stores = storeRepository.findByHomeIdAndUpdatedAtAfter(homeId, effectiveSince);
        List<Map<String, Object>> storeMaps = stores.stream().map(s -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", s.getId().toString());
            map.put("name", s.getName());
            map.put("location", s.getLocation());
            return map;
        }).toList();

        return SyncPullResponse.builder()
                .inventoryItems(itemMaps)
                .stockTransactions(txMaps)
                .shoppingLists(listMaps)
                .shoppingListItems(shoppingItemMaps)
                .purchases(purchaseMaps)
                .categories(catMaps)
                .stores(storeMaps)
                .serverTimestamp(serverTimestamp.toString())
                .serverVersion(currentServerVersion)
                .nextServerVersion(nextServerVersion)
                .hasMore(hasMore)
                .deletedShoppingItemIds(deletedShoppingItemIds)
                .deletedInventoryItemIds(deletedInventoryItemIds)
                .deletedStoreIds(deletedStoreIds)
                .deletedCategoryIds(deletedCategoryIds)
                .build();
    }

    private String serializePayload(Map<String, Object> payload) {
        if (payload == null || payload.isEmpty()) return null;
        try {
            return objectMapper.writeValueAsString(payload);
        } catch (Exception e) {
            return null;
        }
    }

    private BigDecimal toBigDecimal(Object value, BigDecimal defaultValue) {
        if (value == null) return defaultValue;
        if (value instanceof BigDecimal bd) return bd;
        if (value instanceof Number num) return BigDecimal.valueOf(num.doubleValue());
        try {
            return new BigDecimal(value.toString());
        } catch (Exception e) {
            return defaultValue;
        }
    }

    private LocalDate parseLocalDate(Object value) {
        if (value == null) return null;
        try {
            return LocalDate.parse(value.toString());
        } catch (Exception e) {
            return null;
        }
    }
}
