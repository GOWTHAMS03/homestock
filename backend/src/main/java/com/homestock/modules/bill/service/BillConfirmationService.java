package com.homestock.modules.bill.service;

import com.homestock.core.exception.ResourceNotFoundException;
import com.homestock.modules.bill.dto.*;
import com.homestock.modules.bill.entity.ProductPriceHistory;
import com.homestock.modules.bill.entity.PurchasedBill;
import com.homestock.modules.bill.entity.PurchasedBillItem;
import com.homestock.modules.bill.matching.ProductNormalizationService;
import com.homestock.modules.bill.repository.ProductPriceHistoryRepository;
import com.homestock.modules.bill.repository.PurchasedBillItemRepository;
import com.homestock.modules.bill.repository.PurchasedBillRepository;
import com.homestock.modules.category.entity.Category;
import com.homestock.modules.category.repository.CategoryRepository;
import com.homestock.modules.dashboard.service.DashboardCacheService;
import com.homestock.modules.home.entity.Home;
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
            HomeChangeLogService homeChangeLogService
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
    }

    @Transactional
    public BillResponseDto confirmBill(
            UUID homeId,
            UUID billId,
            ConfirmBillRequest request,
            User currentUser
    ) {
        PurchasedBill bill = billRepository.findById(billId)
                .orElseThrow(() -> new ResourceNotFoundException("Bill not found"));

        if (!bill.getHome().getId().equals(homeId)) {
            throw new org.springframework.security.access.AccessDeniedException("Bill does not belong to this household");
        }

        Home home = bill.getHome();

        // 1. Resolve Store
        Store store = null;
        String shopName = request.getShopName() != null ? request.getShopName() : bill.getShopName();
        if (shopName != null && !shopName.trim().isEmpty()) {
            store = storeRepository.findByHomeIdAndNameIgnoreCase(homeId, shopName.trim())
                    .orElseGet(() -> storeRepository.save(Store.builder()
                            .home(home)
                            .name(shopName.trim())
                            .build()));
        }

        LocalDate billDate = request.getBillDate() != null ? request.getBillDate() : bill.getBillDate();
        String billNumber = request.getBillNumber() != null ? request.getBillNumber() : bill.getBillNumber();
        BigDecimal totalAmount = request.getTotalAmount() != null ? request.getTotalAmount() : bill.getTotalAmount();

        // 2. Update Bill Header
        bill.setStore(store);
        bill.setShopName(shopName);
        bill.setBillNumber(billNumber);
        bill.setBillDate(billDate);
        bill.setSubtotal(request.getSubtotal() != null ? request.getSubtotal() : bill.getSubtotal());
        bill.setTaxAmount(request.getTaxAmount() != null ? request.getTaxAmount() : bill.getTaxAmount());
        bill.setDiscountAmount(request.getDiscountAmount() != null ? request.getDiscountAmount() : bill.getDiscountAmount());
        bill.setTotalAmount(totalAmount);
        bill.setStatus("CONFIRMED");
        bill.setConfirmedAt(Instant.now());
        billRepository.save(bill);

        // 3. Create Permanent Purchase Record
        Purchase purchase = Purchase.builder()
                .home(home)
                .store(store)
                .recordedBy(currentUser)
                .purchaseDate(billDate)
                .totalAmount(totalAmount)
                .currency(bill.getCurrency())
                .receiptImageUrl(bill.getReceiptImageUrl())
                .notes("Generated from Bill #" + billNumber + (shopName != null ? " at " + shopName : ""))
                .items(new ArrayList<>())
                .build();
        purchase = purchaseRepository.save(purchase);

        // Clear draft bill items if any, then insert confirmed items
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
                    inventoryItem = inventoryItemRepository.findByHomeIdAndProductId(homeId, product.getId()).orElse(null);
                }
            }

            // If not found in household inventory, create or link
            if (inventoryItem == null) {
                String cleanName = itemReq.getProductName() != null ? itemReq.getProductName() : itemReq.getRawItemName();
                ProductNormalizationService.NormalizedProductInfo norm = normalizationService.normalize(cleanName);

                if (product == null) {
                    product = productRepository.findByNormalizedName(norm.normalizedName())
                            .orElseGet(() -> productRepository.save(Product.builder()
                                    .name(cleanName)
                                    .normalizedName(norm.normalizedName())
                                    .brand(itemReq.getBrand() != null ? itemReq.getBrand() : norm.detectedBrand())
                                    .unit(unit)
                                    .categoryName(itemReq.getCategoryName() != null ? itemReq.getCategoryName() : "Food & Grocery")
                                    .barcode(itemReq.getBarcode())
                                    .source("BILL_SCAN")
                                    .build()));
                }

                Category category = null;
                if (itemReq.getCategoryName() != null) {
                    category = categoryRepository.findByHomeIdAndNameIgnoreCase(homeId, itemReq.getCategoryName()).orElse(null);
                }

                inventoryItem = InventoryItem.builder()
                        .home(home)
                        .product(product)
                        .name(cleanName)
                        .brand(itemReq.getBrand() != null ? itemReq.getBrand() : norm.detectedBrand())
                        .category(category)
                        .quantity(BigDecimal.ZERO)
                        .unit(unit)
                        .minimumQuantity(BigDecimal.ONE)
                        .purchasePrice(unitPrice)
                        .purchaseDate(billDate)
                        .barcode(itemReq.getBarcode())
                        .build();
                inventoryItem = inventoryItemRepository.save(inventoryItem);
            }

            // B. Increment Inventory Quantity & Record Transaction
            BigDecimal previousQuantity = inventoryItem.getQuantity() != null ? inventoryItem.getQuantity() : BigDecimal.ZERO;
            BigDecimal newQuantity = previousQuantity.add(qty);

            inventoryItem.setQuantity(newQuantity);
            inventoryItem.setPurchasePrice(unitPrice);
            inventoryItem.setPurchaseDate(billDate);
            inventoryItemRepository.save(inventoryItem);

            // Record Stock Transaction
            StockTransaction tx = StockTransaction.builder()
                    .home(home)
                    .item(inventoryItem)
                    .user(currentUser)
                    .transactionType(TransactionType.STOCK_IN)
                    .quantityChange(qty)
                    .previousQuantity(previousQuantity)
                    .newQuantity(newQuantity)
                    .unit(unit)
                    .reason("Purchased via Bill #" + billNumber + " [source: BILL_SCAN]")
                    .build();
            stockTransactionRepository.save(tx);

            // C. Shopping List Integration (Partial vs Full)
            ShoppingListItem shoppingItem = null;
            if (itemReq.getShoppingListItemId() != null) {
                shoppingItem = shoppingListItemRepository.findById(itemReq.getShoppingListItemId()).orElse(null);
            } else {
                // Heuristic match if user didn't explicitly pick one
                List<ShoppingListItem> pending = shoppingListItemRepository.findPendingItemsByHomeId(homeId);
                for (ShoppingListItem p : pending) {
                    if (p.getItemName().equalsIgnoreCase(inventoryItem.getName())) {
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

                if (totalPurchased.compareTo(shoppingItem.getQuantity()) >= 0) {
                    shoppingItem.setIsCompleted(true);
                    shoppingItem.setStatus("PURCHASED");
                    shoppingItem.setCompletedAt(Instant.now());
                    shoppingItem.setCompletedBy(currentUser);
                } else {
                    shoppingItem.setIsCompleted(false);
                    shoppingItem.setStatus("PARTIALLY_PURCHASED");
                }
                shoppingListItemRepository.save(shoppingItem);
            }

            // D. Save Bill Item
            BigDecimal standardPrice = calculateStandardUnitPrice(finalPrice, qty, unit);

            PurchasedBillItem billItem = PurchasedBillItem.builder()
                    .bill(bill)
                    .product(inventoryItem.getProduct())
                    .inventoryItem(inventoryItem)
                    .shoppingListItem(shoppingItem)
                    .rawItemName(itemReq.getRawItemName())
                    .normalizedItemName(inventoryItem.getName())
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

            // E. Save Permanent Purchase Item
            PurchaseItem purchaseItem = PurchaseItem.builder()
                    .purchase(purchase)
                    .inventoryItem(inventoryItem)
                    .itemName(inventoryItem.getName())
                    .category(inventoryItem.getCategory())
                    .quantity(qty)
                    .unit(unit)
                    .unitPrice(unitPrice)
                    .totalPrice(finalPrice)
                    .build();
            purchaseItemRepository.save(purchaseItem);

            // F. Record Product Price History
            ProductPriceHistory priceHistory = ProductPriceHistory.builder()
                    .home(home)
                    .product(inventoryItem.getProduct())
                    .inventoryItem(inventoryItem)
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

        // 4. Invalidate Dashboard Summary Cache & Record Change Log
        dashboardCacheService.evict(homeId);
        homeChangeLogService.recordChange(home, "PURCHASED_BILL", bill.getId(), "INSERT", null, "bill-" + bill.getId());
        homeChangeLogService.recordChange(home, "INVENTORY_ITEM", home.getId(), "UPDATE", null, "stock-bill-" + bill.getId());

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
}
