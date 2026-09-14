package com.homestock.modules.bill.service;

import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.bill.dto.*;
import com.homestock.modules.bill.entity.ProductPriceHistory;
import com.homestock.modules.bill.entity.PurchasedBill;
import com.homestock.modules.bill.entity.PurchasedBillItem;
import com.homestock.modules.bill.matching.ProductMatchingEngine;
import com.homestock.modules.bill.matching.ProductNormalizationService;
import com.homestock.modules.bill.repository.ProductPriceHistoryRepository;
import com.homestock.modules.bill.repository.PurchasedBillItemRepository;
import com.homestock.modules.bill.repository.PurchasedBillRepository;
import com.homestock.modules.category.entity.Category;
import com.homestock.modules.category.repository.CategoryRepository;
import com.homestock.modules.dashboard.service.DashboardCacheService;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.entity.StockTransaction;
import com.homestock.modules.inventory.entity.TransactionType;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.inventory.repository.StockTransactionRepository;
import com.homestock.modules.product.entity.Product;
import com.homestock.modules.product.repository.ProductRepository;
import com.homestock.modules.purchase.entity.Purchase;
import com.homestock.modules.purchase.entity.PurchaseItem;
import com.homestock.modules.purchase.repository.PurchaseItemRepository;
import com.homestock.modules.purchase.repository.PurchaseRepository;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.consumption.service.ConsumptionService;
import com.homestock.modules.notification.service.NotificationEngine;
import com.homestock.modules.store.entity.Store;
import com.homestock.modules.store.repository.StoreRepository;
import com.homestock.modules.sync.service.HomeChangeLogService;
import com.homestock.modules.user.entity.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class BillConfirmationService {

    private static final Logger log = LoggerFactory.getLogger(BillConfirmationService.class);

    private final PurchasedBillRepository billRepository;
    private final PurchasedBillItemRepository billItemRepository;
    private final InventoryItemRepository inventoryItemRepository;
    private final StockTransactionRepository stockTransactionRepository;
    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final ShoppingListItemRepository shoppingListItemRepository;
    private final ProductPriceHistoryRepository priceHistoryRepository;
    private final PurchaseRepository purchaseRepository;
    private final PurchaseItemRepository purchaseItemRepository;
    private final StoreRepository storeRepository;
    private final ProductNormalizationService normalizationService;
    private final DashboardCacheService dashboardCacheService;
    private final HomeChangeLogService homeChangeLogService;
    private final HomeRepository homeRepository;
    private final DuplicateBillDetector duplicateDetector;
    private final NotificationEngine notificationEngine;
    private final ConsumptionService consumptionService;

    public BillConfirmationService(
            PurchasedBillRepository billRepository,
            PurchasedBillItemRepository billItemRepository,
            InventoryItemRepository inventoryItemRepository,
            StockTransactionRepository stockTransactionRepository,
            ProductRepository productRepository,
            CategoryRepository categoryRepository,
            ShoppingListItemRepository shoppingListItemRepository,
            ProductPriceHistoryRepository priceHistoryRepository,
            PurchaseRepository purchaseRepository,
            PurchaseItemRepository purchaseItemRepository,
            StoreRepository storeRepository,
            ProductNormalizationService normalizationService,
            DashboardCacheService dashboardCacheService,
            HomeChangeLogService homeChangeLogService,
            HomeRepository homeRepository,
            DuplicateBillDetector duplicateDetector,
            NotificationEngine notificationEngine,
            ConsumptionService consumptionService
    ) {
        this.billRepository = billRepository;
        this.billItemRepository = billItemRepository;
        this.inventoryItemRepository = inventoryItemRepository;
        this.stockTransactionRepository = stockTransactionRepository;
        this.productRepository = productRepository;
        this.categoryRepository = categoryRepository;
        this.shoppingListItemRepository = shoppingListItemRepository;
        this.priceHistoryRepository = priceHistoryRepository;
        this.purchaseRepository = purchaseRepository;
        this.purchaseItemRepository = purchaseItemRepository;
        this.storeRepository = storeRepository;
        this.normalizationService = normalizationService;
        this.dashboardCacheService = dashboardCacheService;
        this.homeChangeLogService = homeChangeLogService;
        this.homeRepository = homeRepository;
        this.duplicateDetector = duplicateDetector;
        this.notificationEngine = notificationEngine;
        this.consumptionService = consumptionService;
    }

    @Transactional
    public BillResponseDto confirmBill(
            UUID homeId,
            UUID billId,
            ConfirmBillRequest request,
            User currentUser
    ) {
        PurchasedBill bill = null;
        if (billId != null) {
            bill = billRepository.findById(billId).orElse(null);
        }
        if (bill == null && request != null && request.getBillId() != null) {
            bill = billRepository.findById(request.getBillId()).orElse(null);
        }

        Home home;
        if (bill != null) {
            if (!bill.getHome().getId().equals(homeId)) {
                throw new org.springframework.security.access.AccessDeniedException("Bill does not belong to this household");
            }
            home = bill.getHome();
        } else {
            home = homeRepository.findById(homeId)
                    .orElseThrow(() -> new ResourceNotFoundException("Household not found"));
            String defaultShopName = (request != null && request.getShopName() != null) ? request.getShopName() : "Retail Store";
            LocalDate defaultBillDate = (request != null && request.getBillDate() != null) ? request.getBillDate() : LocalDate.now();
            BigDecimal defaultTotal = (request != null && request.getTotalAmount() != null) ? request.getTotalAmount() : BigDecimal.ZERO;
            String idempotencyKey = duplicateDetector.generateIdempotencyKey(homeId, defaultShopName, request != null ? request.getBillNumber() : null, defaultBillDate, defaultTotal);

            bill = PurchasedBill.builder()
                    .home(home)
                    .shopName(defaultShopName)
                    .billNumber(request != null ? request.getBillNumber() : null)
                    .billDate(defaultBillDate)
                    .subtotal((request != null && request.getSubtotal() != null) ? request.getSubtotal() : defaultTotal)
                    .taxAmount((request != null && request.getTaxAmount() != null) ? request.getTaxAmount() : BigDecimal.ZERO)
                    .discountAmount((request != null && request.getDiscountAmount() != null) ? request.getDiscountAmount() : BigDecimal.ZERO)
                    .totalAmount(defaultTotal)
                    .currency("INR")
                    .idempotencyKey(idempotencyKey)
                    .status("CONFIRMED")
                    .rawOcrText(request != null ? request.getRawOcrText() : null)
                    .recordedBy(currentUser)
                    .build();
            bill = billRepository.save(bill);
        }

        // 1. Resolve Store
        Store store = null;
        String rawShop = request.getShopName() != null ? request.getShopName() : bill.getShopName();
        String shopName = sanitize(rawShop);
        if (shopName != null && !shopName.isBlank()) {
            store = storeRepository.findByHomeIdAndNameIgnoreCase(homeId, shopName)
                    .orElseGet(() -> storeRepository.save(Store.builder()
                            .home(home)
                            .name(shopName)
                            .build()));
        }

        LocalDate billDate = request.getBillDate() != null ? request.getBillDate() : bill.getBillDate();
        String billNumber = sanitize(request.getBillNumber() != null ? request.getBillNumber() : bill.getBillNumber());
        BigDecimal totalAmount = request.getTotalAmount() != null ? request.getTotalAmount() : bill.getTotalAmount();

        // 2. Update Bill Header
        bill.setStore(store);
        bill.setShopName(shopName != null ? shopName : "Retail Store");
        bill.setBillNumber(billNumber);
        bill.setBillDate(billDate);
        bill.setSubtotal(request.getSubtotal() != null ? request.getSubtotal() : bill.getSubtotal());
        bill.setTaxAmount(request.getTaxAmount() != null ? request.getTaxAmount() : bill.getTaxAmount());
        bill.setDiscountAmount(request.getDiscountAmount() != null ? request.getDiscountAmount() : bill.getDiscountAmount());
        bill.setTotalAmount(totalAmount);
        bill.setStatus("CONFIRMED");
        bill.setConfirmedAt(Instant.now());
        billRepository.save(bill);

        // 3. Create Permanent Purchase Record with explicit [BILL:<uuid>] reference
        String billRefNumber = (billNumber != null && !billNumber.isBlank() && !billNumber.equalsIgnoreCase("null"))
                ? billNumber : "REC-" + bill.getId().toString().substring(0, 8).toUpperCase();
        String purchaseNote = "Generated from Bill #" + billRefNumber + (shopName != null ? " at " + shopName : "") + " [BILL:" + bill.getId() + "]";

        Purchase purchase = Purchase.builder()
                .home(home)
                .store(store)
                .recordedBy(currentUser)
                .purchaseDate(billDate)
                .totalAmount(totalAmount)
                .currency(bill.getCurrency())
                .receiptImageUrl(bill.getReceiptImageUrl())
                .notes(sanitize(purchaseNote))
                .items(new ArrayList<>())
                .build();
        purchase = purchaseRepository.save(purchase);

        // Clear draft bill items if any, then insert confirmed items
        List<PurchasedBillItem> existingDraftItems = billItemRepository.findByBillId(bill.getId());
        if (!existingDraftItems.isEmpty()) {
            billItemRepository.deleteAll(existingDraftItems);
            billItemRepository.flush();
        }
        List<PurchasedBillItem> confirmedBillItems = new ArrayList<>();

        for (ConfirmBillItemRequest itemReq : request.getItems()) {
            BigDecimal qty = itemReq.getQuantity();
            BigDecimal unitPrice = itemReq.getUnitPrice();
            BigDecimal finalPrice = itemReq.getFinalPrice();
            String unit = itemReq.getUnit();

            // A. Resolve or Create Product & InventoryItem
            InventoryItem inventoryItem = null;
            Product product = null;

            if (itemReq.getInventoryItemId() != null) {
                inventoryItem = inventoryItemRepository.findById(itemReq.getInventoryItemId())
                        .orElse(null);
            }

            if (inventoryItem == null && itemReq.getProductId() != null) {
                product = productRepository.findById(itemReq.getProductId()).orElse(null);
                if (product != null) {
                    inventoryItem = inventoryItemRepository.findByHomeIdAndProductIdAndIsArchivedFalse(homeId, product.getId()).orElse(null);
                }
            }

            String rawName = itemReq.getProductName() != null ? itemReq.getProductName() : itemReq.getRawItemName();
            String sanitized = sanitize(rawName);
            final String cleanName = (sanitized != null && !sanitized.isBlank()) ? sanitized : "Item";
            ProductNormalizationService.NormalizedProductInfo norm = normalizationService.normalize(cleanName);

            if (product == null) {
                product = productRepository.findByNormalizedName(norm.normalizedName()).orElse(null);
            }

            // If still not resolved and not explicitly marked as a forced brand-new item, search household inventory
            if (inventoryItem == null && !Boolean.TRUE.equals(itemReq.getCreateNewProduct())) {
                // 1. Check barcode if present
                if (itemReq.getBarcode() != null && !itemReq.getBarcode().isBlank()) {
                    inventoryItem = inventoryItemRepository.findByHomeIdAndBarcodeAndIsArchivedFalse(homeId, itemReq.getBarcode()).orElse(null);
                }

                // 2. Check if household has an inventory item linked to the resolved product
                if (inventoryItem == null && product != null) {
                    inventoryItem = inventoryItemRepository.findByHomeIdAndProductIdAndIsArchivedFalse(homeId, product.getId()).orElse(null);
                }

                // 3. Search active household items by exact name, normalized name, or token containment
                if (inventoryItem == null) {
                    List<InventoryItem> activeHomeItems = inventoryItemRepository.findAllByHomeIdAndIsArchivedFalseOrderByNameAsc(homeId);
                    
                    // Exact name or normalized name
                    for (InventoryItem hItem : activeHomeItems) {
                        if (hItem.getName().equalsIgnoreCase(cleanName) || hItem.getName().equalsIgnoreCase(itemReq.getRawItemName())) {
                            inventoryItem = hItem;
                            break;
                        }
                        ProductNormalizationService.NormalizedProductInfo hNorm = normalizationService.normalize(hItem.getName());
                        if (hNorm.normalizedName().equalsIgnoreCase(norm.normalizedName())) {
                            inventoryItem = hItem;
                            break;
                        }
                    }

                    // Token containment / similarity match
                    if (inventoryItem == null) {
                        InventoryItem bestCandidate = null;
                        double bestSim = 0.0;
                        for (InventoryItem hItem : activeHomeItems) {
                            ProductNormalizationService.NormalizedProductInfo hNorm = normalizationService.normalize(hItem.getName());
                            double sim = calculateSimilarity(norm.normalizedName(), hNorm.normalizedName(), norm.detectedBrand(), hItem.getBrand(), cleanName, hItem.getName());
                            if (sim > bestSim) {
                                bestSim = sim;
                                bestCandidate = hItem;
                            }
                        }
                        if (bestSim >= 0.70 && bestCandidate != null) {
                            inventoryItem = bestCandidate;
                        }
                    }
                }
            }

            // Resolve Category for this line item
            String targetCategoryName = (itemReq.getCategoryName() != null && !itemReq.getCategoryName().isBlank())
                    ? itemReq.getCategoryName().trim()
                    : ProductMatchingEngine.inferCategory(cleanName);

            Category resolvedCategory = categoryRepository.findFirstByHomeIdOrGlobalAndNameIgnoreCase(homeId, targetCategoryName)
                    .orElseGet(() -> {
                        Category newCat = Category.builder()
                                .home(home)
                                .name(targetCategoryName)
                                .icon("category")
                                .colorHex("#6366F1")
                                .displayOrder(50)
                                .build();
                        return categoryRepository.save(newCat);
                    });

            // If not found in household inventory, create or link
            boolean isNewItem = false;
            if (inventoryItem == null) {
                isNewItem = true;

                if (product == null) {
                    product = productRepository.findByNormalizedName(norm.normalizedName())
                            .orElseGet(() -> productRepository.save(Product.builder()
                                    .name(cleanName)
                                    .normalizedName(norm.normalizedName())
                                    .brand(itemReq.getBrand() != null ? itemReq.getBrand() : norm.detectedBrand())
                                    .unit(unit)
                                    .categoryName(targetCategoryName)
                                    .barcode(itemReq.getBarcode())
                                    .source("BILL_SCAN")
                                    .build()));
                }

                inventoryItem = InventoryItem.builder()
                        .home(home)
                        .product(product)
                        .name(cleanName)
                        .brand(itemReq.getBrand() != null ? itemReq.getBrand() : norm.detectedBrand())
                        .category(resolvedCategory)
                        .quantity(BigDecimal.ZERO)
                        .unit(unit)
                        .minimumQuantity(BigDecimal.ONE)
                        .purchasePrice(unitPrice)
                        .purchaseDate(billDate)
                        .barcode(itemReq.getBarcode())
                        .build();
                inventoryItem = inventoryItemRepository.save(inventoryItem);
            } else if (inventoryItem.getCategory() == null && resolvedCategory != null) {
                inventoryItem.setCategory(resolvedCategory);
            }

            // B. Increment Inventory Quantity with unit conversion & Record Transaction
            BigDecimal previousQuantity = inventoryItem.getQuantity() != null ? inventoryItem.getQuantity() : BigDecimal.ZERO;
            BigDecimal convertedQty = convertQuantity(qty, unit, inventoryItem.getUnit());
            BigDecimal newQuantity = previousQuantity.add(convertedQty);

            inventoryItem.setQuantity(newQuantity);
            if (unitPrice != null && unitPrice.compareTo(BigDecimal.ZERO) > 0) {
                inventoryItem.setPurchasePrice(unitPrice);
            }
            inventoryItem.setPurchaseDate(billDate);
            if (inventoryItem.getMaximumQuantity() != null && inventoryItem.getMaximumQuantity().compareTo(BigDecimal.ZERO) > 0) {
                inventoryItem.setQuantityStatus(com.homestock.modules.consumption.entity.QuantityStatus.fromRatio(
                        newQuantity.divide(inventoryItem.getMaximumQuantity(), 2, RoundingMode.HALF_UP)));
            }
            inventoryItem.setQuantitySource(com.homestock.modules.consumption.entity.QuantitySource.VERIFIED);
            inventoryItem.setLastVerifiedAt(Instant.now());
            inventoryItem.setConfidence(com.homestock.modules.consumption.entity.ConfidenceLevel.HIGH);

            if (inventoryItem.getProduct() == null && product != null) {
                inventoryItem.setProduct(product);
            }

            InventoryItem savedInv = inventoryItemRepository.save(inventoryItem);
            homeChangeLogService.recordChange(home, "INVENTORY_ITEM", savedInv.getId(), isNewItem ? "INSERT" : "UPDATE", null, null);

            // Record Stock Transaction with reference to BILL
            String storeDesc = (shopName != null && !shopName.isBlank()) ? " at " + shopName : "";
            StockTransaction tx = StockTransaction.builder()
                    .home(home)
                    .item(savedInv)
                    .user(currentUser)
                    .transactionType(TransactionType.STOCK_IN)
                    .quantityChange(convertedQty)
                    .previousQuantity(previousQuantity)
                    .newQuantity(newQuantity)
                    .unit(savedInv.getUnit())
                    .reason("Purchased via Bill #" + billNumber + storeDesc)
                    .referenceType("BILL")
                    .referenceId(bill.getId())
                    .build();
            StockTransaction savedTx = stockTransactionRepository.save(tx);
            homeChangeLogService.recordChange(home, "STOCK_TRANSACTION", savedTx.getId(), "INSERT", null, null);

            // C. Shopping List Integration (Partial vs Full)
            ShoppingListItem shoppingItem = null;
            if (itemReq.getShoppingListItemId() != null) {
                shoppingItem = shoppingListItemRepository.findById(itemReq.getShoppingListItemId()).orElse(null);
            } else {
                // Heuristic match if user didn't explicitly pick one
                List<ShoppingListItem> pending = shoppingListItemRepository.findPendingItemsByHomeId(homeId);
                for (ShoppingListItem p : pending) {
                    if (p.getItemName().equalsIgnoreCase(savedInv.getName())) {
                        shoppingItem = p;
                        break;
                    }
                }
            }

            if (shoppingItem != null) {
                BigDecimal currentPurchased = shoppingItem.getPurchasedQuantity() != null
                        ? shoppingItem.getPurchasedQuantity()
                        : BigDecimal.ZERO;
                BigDecimal totalPurchased = currentPurchased.add(qty);
                shoppingItem.setPurchasedQuantity(totalPurchased);

                if (shoppingItem.getQuantity() != null && totalPurchased.compareTo(shoppingItem.getQuantity()) >= 0) {
                    shoppingItem.setIsCompleted(true);
                    shoppingItem.setStatus("PURCHASED");
                    shoppingItem.setCompletedAt(Instant.now());
                    shoppingItem.setCompletedBy(currentUser);
                } else {
                    shoppingItem.setIsCompleted(false);
                    shoppingItem.setStatus("PARTIALLY_PURCHASED");
                }
                ShoppingListItem savedShop = shoppingListItemRepository.save(shoppingItem);
                homeChangeLogService.recordChange(home, "SHOPPING_LIST_ITEM", savedShop.getId(), "UPDATE", null, null);
            }

            // D. Feed Consumption Learning Engine
            consumptionService.onPurchaseRecorded(home, savedInv, qty, billDate);

            // E. Save Bill Item
            BigDecimal standardPrice = calculateStandardUnitPrice(finalPrice, qty, unit);

            PurchasedBillItem billItem = PurchasedBillItem.builder()
                    .bill(bill)
                    .product(savedInv.getProduct())
                    .inventoryItem(savedInv)
                    .shoppingListItem(shoppingItem)
                    .rawItemName(itemReq.getRawItemName())
                    .normalizedItemName(savedInv.getName())
                    .quantity(qty)
                    .unit(unit)
                    .mrp(itemReq.getMrp())
                    .unitPrice(unitPrice)
                    .discount(itemReq.getDiscount() != null ? itemReq.getDiscount() : BigDecimal.ZERO)
                    .tax(itemReq.getTax() != null ? itemReq.getTax() : BigDecimal.ZERO)
                    .finalPrice(finalPrice)
                    .standardUnitPrice(standardPrice)
                    .matchConfidence(BigDecimal.valueOf(100.0))
                    .matchStatus("AUTO_MATCHED")
                    .build();
            billItem = billItemRepository.save(billItem);
            confirmedBillItems.add(billItem);

            // F. Save Permanent Purchase Item
            PurchaseItem purchaseItem = PurchaseItem.builder()
                    .purchase(purchase)
                    .inventoryItem(savedInv)
                    .itemName(savedInv.getName())
                    .category(savedInv.getCategory() != null ? savedInv.getCategory() : resolvedCategory)
                    .quantity(qty)
                    .unit(unit)
                    .unitPrice(unitPrice)
                    .totalPrice(finalPrice)
                    .build();
            purchaseItem = purchaseItemRepository.save(purchaseItem);
            purchase.getItems().add(purchaseItem);

            // G. Record Product Price History
            ProductPriceHistory priceHistory = ProductPriceHistory.builder()
                    .home(home)
                    .product(savedInv.getProduct())
                    .inventoryItem(savedInv)
                    .store(store)
                    .storeName(shopName)
                    .purchaseDate(billDate)
                    .quantity(qty)
                    .unit(unit)
                    .unitPrice(unitPrice)
                    .standardUnitPrice(standardPrice)
                    .totalPrice(finalPrice)
                    .billItem(billItem)
                    .build();
            priceHistoryRepository.save(priceHistory);
        }

        // 4. Change Log, Notifications & Cache Eviction
        homeChangeLogService.recordChange(home, "PURCHASE", purchase.getId(), "INSERT", null, null);
        homeChangeLogService.recordChange(home, "PURCHASED_BILL", bill.getId(), "INSERT", null, "bill-" + bill.getId());

        notificationEngine.notifyPurchaseRecorded(home, currentUser, purchase);
        notificationEngine.notifyHomeChanged(home, currentUser.getId());
        dashboardCacheService.evict(homeId);

        return mapToResponseDto(bill, confirmedBillItems);
    }

    private BigDecimal calculateStandardUnitPrice(BigDecimal price, BigDecimal quantity, String unit) {
        if (price == null || quantity == null || quantity.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }

        BigDecimal unitPrice = price.divide(quantity, 4, RoundingMode.HALF_UP);
        String u = unit != null ? unit.toLowerCase() : "pcs";

        if ("g".equals(u) || "gm".equals(u) || "grams".equals(u)) {
            return unitPrice.multiply(BigDecimal.valueOf(1000)).setScale(2, RoundingMode.HALF_UP);
        }
        if ("ml".equals(u)) {
            return unitPrice.multiply(BigDecimal.valueOf(1000)).setScale(2, RoundingMode.HALF_UP);
        }

        return unitPrice.setScale(2, RoundingMode.HALF_UP);
    }

    private BillResponseDto mapToResponseDto(PurchasedBill bill, List<PurchasedBillItem> items) {
        List<BillItemResponseDto> itemDtos = items.stream().map(i -> BillItemResponseDto.builder()
                .id(i.getId())
                .productId(i.getProduct() != null ? i.getProduct().getId() : null)
                .inventoryItemId(i.getInventoryItem() != null ? i.getInventoryItem().getId() : null)
                .shoppingListItemId(i.getShoppingListItem() != null ? i.getShoppingListItem().getId() : null)
                .rawItemName(i.getRawItemName())
                .normalizedItemName(i.getNormalizedItemName())
                .quantity(i.getQuantity())
                .unit(i.getUnit())
                .mrp(i.getMrp())
                .unitPrice(i.getUnitPrice())
                .discount(i.getDiscount())
                .tax(i.getTax())
                .finalPrice(i.getFinalPrice())
                .standardUnitPrice(i.getStandardUnitPrice())
                .matchConfidence(i.getMatchConfidence())
                .matchStatus(i.getMatchStatus())
                .build()).toList();

        return BillResponseDto.builder()
                .id(bill.getId())
                .homeId(bill.getHome().getId())
                .shopName(bill.getShopName())
                .billNumber(bill.getBillNumber())
                .billDate(bill.getBillDate())
                .subtotal(bill.getSubtotal())
                .taxAmount(bill.getTaxAmount())
                .discountAmount(bill.getDiscountAmount())
                .totalAmount(bill.getTotalAmount())
                .currency(bill.getCurrency())
                .status(bill.getStatus())
                .receiptImageUrl(bill.getReceiptImageUrl())
                .recordedByUserId(bill.getRecordedBy() != null ? bill.getRecordedBy().getId() : null)
                .recordedByName(bill.getRecordedBy() != null ? bill.getRecordedBy().getFullName() : null)
                .confirmedAt(bill.getConfirmedAt())
                .createdAt(bill.getCreatedAt())
                .items(itemDtos)
                .build();
    }

    private String sanitize(String input) {
        if (input == null) return null;
        String s = input.replace("\u0000", "").replaceAll("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F]", "").trim();
        return s.isEmpty() ? null : s;
    }

    private BigDecimal convertQuantity(BigDecimal qty, String fromUnit, String toUnit) {
        if (qty == null) return BigDecimal.ZERO;
        if (fromUnit == null || toUnit == null) return qty;

        String from = fromUnit.trim().toLowerCase();
        String to = toUnit.trim().toLowerCase();

        if (from.equals(to)) return qty;

        // Weight: g/gm/grams to kg
        if ((from.equals("g") || from.equals("gm") || from.equals("grams")) && (to.equals("kg") || to.equals("kgs") || to.equals("kilo"))) {
            return qty.divide(BigDecimal.valueOf(1000), 3, RoundingMode.HALF_UP);
        }
        // Weight: kg to g
        if ((from.equals("kg") || from.equals("kgs") || from.equals("kilo")) && (to.equals("g") || to.equals("gm") || to.equals("grams"))) {
            return qty.multiply(BigDecimal.valueOf(1000)).setScale(3, RoundingMode.HALF_UP);
        }

        // Volume: ml to l
        if (from.equals("ml") && (to.equals("l") || to.equals("ltr") || to.equals("litre") || to.equals("litres"))) {
            return qty.divide(BigDecimal.valueOf(1000), 3, RoundingMode.HALF_UP);
        }
        // Volume: l to ml
        if ((from.equals("l") || from.equals("ltr") || from.equals("litre") || to.equals("litres")) && to.equals("ml")) {
            return qty.multiply(BigDecimal.valueOf(1000)).setScale(3, RoundingMode.HALF_UP);
        }

        return qty;
    }

    private double calculateSimilarity(String s1, String s2, String brand1, String brand2, String raw1, String raw2) {
        if (s1 == null || s2 == null) return 0.0;
        if (s1.equalsIgnoreCase(s2) || (raw1 != null && raw2 != null && raw1.equalsIgnoreCase(raw2))) {
            return 1.0;
        }

        java.util.Set<String> stopWords = java.util.Set.of("THE", "A", "AN", "AND", "OF", "PACK", "PKT", "PCS", "PIECE", "BOTTLE", "BOX", "POUCH", "PREMIUM", "SUPERIOR", "FRESH", "SHUDH", "SPECIAL");

        java.util.Set<String> tokens1 = java.util.Arrays.stream(s1.toUpperCase().split("\\s+"))
                .filter(t -> !t.isBlank() && !stopWords.contains(t))
                .collect(java.util.stream.Collectors.toSet());
        java.util.Set<String> tokens2 = java.util.Arrays.stream(s2.toUpperCase().split("\\s+"))
                .filter(t -> !t.isBlank() && !stopWords.contains(t))
                .collect(java.util.stream.Collectors.toSet());

        if (tokens1.isEmpty() || tokens2.isEmpty()) {
            return ProductMatchingEngine.jaroWinkler(s1.toUpperCase(), s2.toUpperCase());
        }

        java.util.Set<String> intersection = new java.util.HashSet<>(tokens1);
        intersection.retainAll(tokens2);

        double minTokens = Math.min(tokens1.size(), tokens2.size());
        double tokenScore = minTokens > 0 ? (double) intersection.size() / minTokens : 0.0;
        boolean isContained = intersection.size() == (int) minTokens;

        double textScore = ProductMatchingEngine.jaroWinkler(s1.toUpperCase(), s2.toUpperCase());

        double combinedScore;
        if (isContained) {
            combinedScore = 0.88 + (textScore * 0.08);
        } else {
            combinedScore = (textScore * 0.35) + (tokenScore * 0.65);
        }

        if (brand1 != null && brand2 != null) {
            if (brand1.equalsIgnoreCase(brand2)) {
                combinedScore = Math.min(0.99, combinedScore + 0.10);
            } else {
                combinedScore = Math.max(0.20, combinedScore - 0.15);
            }
        }

        return Math.min(1.0, Math.max(0.0, combinedScore));
    }
}
