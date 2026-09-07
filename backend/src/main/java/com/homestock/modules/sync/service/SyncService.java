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
                case "TOGGLE_SHOPPING_ITEM" -> handleToggleShoppingItem(op, currentUser, payload);
                case "DELETE_SHOPPING_ITEM" -> handleDeleteShoppingItem(op);
                case "RECORD_PURCHASE" -> handleRecordPurchase(op, home, currentUser, payload);
                case "CREATE_STORE" -> handleCreateStore(op, home, payload);
                case "CLEAR_COMPLETED_SHOPPING" -> handleClearCompletedShopping(home);
                case "CREATE_CATEGORY" -> handleCreateCategory(op, home, payload);
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

        // Record initial stock transaction
        if (qty.compareTo(BigDecimal.ZERO) > 0) {
            StockTransaction tx = StockTransaction.builder()
                    .home(home)
                    .item(savedItem)
                    .user(user)
                    .transactionType(TransactionType.STOCK_IN)
                    .quantityChange(qty)
                    .previousQuantity(BigDecimal.ZERO)
                    .newQuantity(qty)
                    .unit(savedItem.getUnit())
                    .reason("Initial offline stock addition")
                    .build();
            stockTransactionRepository.save(tx);
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

        inventoryItemRepository.save(item);
    }

    /**
     * Delta-based stock update: applies the transaction delta (STOCK_IN, STOCK_OUT, etc.)
     * rather than absolute quantity overwrite!
     */
    private void handleStockUpdate(SyncOperationDto op, Home home, User user, Map<String, Object> payload) {
        if (op.getEntityId() == null) return;
        UUID itemId = UUID.fromString(op.getEntityId());
        Optional<InventoryItem> optItem = inventoryItemRepository.findByIdAndHomeId(itemId, home.getId());
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
        stockTransactionRepository.save(tx);
    }

    private void handleDeleteItem(SyncOperationDto op, Home home) {
        if (op.getEntityId() == null) return;
        UUID itemId = UUID.fromString(op.getEntityId());
        inventoryItemRepository.findByIdAndHomeId(itemId, home.getId()).ifPresent(item -> {
            item.setIsArchived(true);
            inventoryItemRepository.save(item);
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

        shoppingListItemRepository.save(item);
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
            shoppingListItemRepository.save(item);
        });
    }

    private void handleDeleteShoppingItem(SyncOperationDto op) {
        if (op.getEntityId() == null) return;
        UUID itemId = UUID.fromString(op.getEntityId());
        shoppingListItemRepository.deleteById(itemId);
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
                        stockTransactionRepository.save(tx);
                    }
                }
            }
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

        storeRepository.save(store);
    }

    private void handleClearCompletedShopping(Home home) {
        ShoppingList list = shoppingService.getOrCreateDefaultListEntity(home);
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

        categoryRepository.save(category);
    }

    /**
     * Pull incremental server changes since the given timestamp.
     */
    @Transactional(readOnly = true)
    public SyncPullResponse pullChanges(UUID homeId, Instant since) {
        Instant serverTimestamp = Instant.now();

        // 1. Categories
        List<Category> categories = categoryRepository.findByHomeIdAndUpdatedAtAfter(homeId, since);
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
        List<InventoryItem> items = inventoryItemRepository.findByHomeIdAndUpdatedAtAfter(homeId, since);
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
        List<StockTransaction> transactions = stockTransactionRepository.findByHomeIdAndCreatedAtAfter(homeId, since);
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
        List<ShoppingList> lists = shoppingListRepository.findByHomeIdAndUpdatedAtAfter(homeId, since);
        List<Map<String, Object>> listMaps = lists.stream().map(l -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", l.getId().toString());
            map.put("name", l.getName());
            map.put("isDefault", Boolean.TRUE.equals(l.getIsDefault()));
            return map;
        }).toList();

        // 5. Shopping list items
        List<ShoppingListItem> shoppingItems = shoppingListItemRepository.findByHomeIdAndUpdatedAtAfter(homeId, since);
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
        List<Purchase> purchases = purchaseRepository.findByHomeIdAndUpdatedAtAfter(homeId, since);
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
        List<Store> stores = storeRepository.findByHomeIdAndUpdatedAtAfter(homeId, since);
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
                .build();
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
