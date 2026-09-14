package com.homestock.modules.bill.service;

import com.homestock.modules.bill.dto.*;
import com.homestock.modules.bill.entity.ProductPriceHistory;
import com.homestock.modules.bill.entity.PurchasedBill;
import com.homestock.modules.bill.entity.PurchasedBillItem;
import com.homestock.modules.bill.repository.ProductPriceHistoryRepository;
import com.homestock.modules.bill.repository.PurchasedBillItemRepository;
import com.homestock.modules.bill.repository.PurchasedBillRepository;
import com.homestock.modules.purchase.entity.Purchase;
import com.homestock.modules.purchase.entity.PurchaseItem;
import com.homestock.modules.purchase.repository.PurchaseItemRepository;
import com.homestock.modules.purchase.repository.PurchaseRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.Month;
import java.time.YearMonth;
import java.time.format.TextStyle;
import java.util.*;

@Service
public class ExpenseIntelligenceService {

    private final PurchasedBillRepository billRepository;
    private final PurchasedBillItemRepository billItemRepository;
    private final ProductPriceHistoryRepository priceHistoryRepository;
    private final PurchaseRepository purchaseRepository;
    private final PurchaseItemRepository purchaseItemRepository;

    public ExpenseIntelligenceService(
            PurchasedBillRepository billRepository,
            PurchasedBillItemRepository billItemRepository,
            ProductPriceHistoryRepository priceHistoryRepository,
            PurchaseRepository purchaseRepository,
            PurchaseItemRepository purchaseItemRepository
    ) {
        this.billRepository = billRepository;
        this.billItemRepository = billItemRepository;
        this.priceHistoryRepository = priceHistoryRepository;
        this.purchaseRepository = purchaseRepository;
        this.purchaseItemRepository = purchaseItemRepository;
    }

    @Transactional(readOnly = true)
    public MonthlyExpenseReportDto getMonthlyReport(UUID homeId, int year, int month) {
        YearMonth ym = YearMonth.of(year, month);
        LocalDate startDate = ym.atDay(1);
        LocalDate endDate = ym.atEndOfMonth();

        // 1. Fetch all Confirmed PurchasedBills in Period
        List<PurchasedBill> scannedBills = billRepository.findBillsInPeriod(homeId, startDate, endDate);
        List<MonthlyBillSummaryDto> monthlyBills = new ArrayList<>();
        Set<UUID> scannedBillIds = new HashSet<>();
        Set<String> matchedPurchaseIdentifiers = new HashSet<>();
        Set<String> scannedBillRefPrefixes = new HashSet<>();

        for (PurchasedBill b : scannedBills) {
            scannedBillIds.add(b.getId());
            scannedBillRefPrefixes.add(b.getId().toString().toLowerCase());
            scannedBillRefPrefixes.add("rec-" + b.getId().toString().substring(0, Math.min(8, b.getId().toString().length())).toLowerCase());

            List<PurchasedBillItem> items = billItemRepository.findByBillId(b.getId());
            List<BillItemSummaryDto> itemSummaries = new ArrayList<>();
            for (PurchasedBillItem item : items) {
                String cleanItemName = (item.getNormalizedItemName() != null && !item.getNormalizedItemName().isBlank())
                        ? item.getNormalizedItemName()
                        : ((item.getRawItemName() != null && !item.getRawItemName().isBlank())
                                ? item.getRawItemName()
                                : (item.getProduct() != null ? item.getProduct().getName() : "Item"));

                String cat = null;
                if (item.getInventoryItem() != null && item.getInventoryItem().getCategory() != null) {
                    cat = item.getInventoryItem().getCategory().getName();
                } else if (item.getProduct() != null) {
                    if (item.getProduct().getCategory() != null) {
                        cat = item.getProduct().getCategory().getName();
                    } else if (item.getProduct().getCategoryName() != null && !item.getProduct().getCategoryName().isBlank()) {
                        cat = item.getProduct().getCategoryName();
                    }
                }

                if (cat == null || cat.isBlank() || "Groceries".equalsIgnoreCase(cat)) {
                    cat = com.homestock.modules.bill.matching.ProductMatchingEngine.inferCategory(cleanItemName);
                }

                itemSummaries.add(BillItemSummaryDto.builder()
                        .id(item.getId())
                        .itemName(cleanItemName)
                        .quantity(item.getQuantity() != null ? item.getQuantity() : BigDecimal.ONE)
                        .unit(item.getUnit() != null ? item.getUnit() : "pcs")
                        .unitPrice(item.getUnitPrice() != null ? item.getUnitPrice() : BigDecimal.ZERO)
                        .finalPrice(item.getFinalPrice() != null ? item.getFinalPrice() : BigDecimal.ZERO)
                        .category(cat)
                        .build());
            }

            monthlyBills.add(MonthlyBillSummaryDto.builder()
                    .id(b.getId())
                    .shopName(b.getShopName() != null ? b.getShopName() : "Retail Store")
                    .billNumber(b.getBillNumber() != null ? b.getBillNumber() : "N/A")
                    .billDate(b.getBillDate())
                    .createdAt(b.getCreatedAt())
                    .totalAmount(b.getTotalAmount() != null ? b.getTotalAmount() : BigDecimal.ZERO)
                    .subtotal(b.getSubtotal() != null ? b.getSubtotal() : b.getTotalAmount())
                    .taxAmount(b.getTaxAmount() != null ? b.getTaxAmount() : BigDecimal.ZERO)
                    .discountAmount(b.getDiscountAmount() != null ? b.getDiscountAmount() : BigDecimal.ZERO)
                    .itemsCount(items.size())
                    .status(b.getStatus())
                    .source("AI_SCANNED")
                    .items(itemSummaries)
                    .build());

            if (b.getBillNumber() != null && !b.getBillNumber().isBlank() && !b.getBillNumber().equalsIgnoreCase("N/A")) {
                matchedPurchaseIdentifiers.add(b.getBillNumber().trim().toLowerCase());
            }
        }

        // 2. Fetch Household Purchases in Period and deduplicate against scanned bills
        List<Purchase> purchases = purchaseRepository.findAllByHomeIdAndPurchaseDateBetween(homeId, startDate, endDate);

        for (Purchase p : purchases) {
            boolean isDuplicateOfScannedBill = false;
            String notes = p.getNotes() != null ? p.getNotes().toLowerCase() : "";

            // Check 0: Explicit [BILL:<uuid>] tag
            if (notes.contains("[bill:")) {
                int start = notes.indexOf("[bill:") + 6;
                int end = notes.indexOf("]", start);
                if (end > start) {
                    String billIdStr = notes.substring(start, end).trim();
                    try {
                        UUID billId = UUID.fromString(billIdStr);
                        if (scannedBillIds.contains(billId)) {
                            isDuplicateOfScannedBill = true;
                        } else {
                            Optional<PurchasedBill> optB = billRepository.findById(billId);
                            if (optB.isPresent() && "CONFIRMED".equalsIgnoreCase(optB.get().getStatus())) {
                                isDuplicateOfScannedBill = true;
                            }
                        }
                    } catch (Exception ignored) {}
                }
            }

            // Check 1: Bill Number or UUID reference prefix in purchase notes
            if (!isDuplicateOfScannedBill && !notes.isBlank()) {
                for (String billNum : matchedPurchaseIdentifiers) {
                    if (notes.contains(billNum)) {
                        isDuplicateOfScannedBill = true;
                        break;
                    }
                }
                if (!isDuplicateOfScannedBill) {
                    for (String prefix : scannedBillRefPrefixes) {
                        if (notes.contains(prefix)) {
                            isDuplicateOfScannedBill = true;
                            break;
                        }
                    }
                }
            }

            // Check 2: Note indicates generation from a bill and matches scanned bills by date and tolerance
            if (!isDuplicateOfScannedBill && notes.contains("generated from bill")) {
                for (PurchasedBill b : scannedBills) {
                    boolean dateMatches = b.getBillDate() != null && b.getBillDate().equals(p.getPurchaseDate());
                    boolean amountMatches = b.getTotalAmount() != null && p.getTotalAmount() != null
                            && b.getTotalAmount().subtract(p.getTotalAmount()).abs().compareTo(BigDecimal.valueOf(0.05)) < 0;
                    if (dateMatches && amountMatches) {
                        isDuplicateOfScannedBill = true;
                        break;
                    }
                }

                // If note explicitly says generated from bill and any scanned bill exists for the same date
                if (!isDuplicateOfScannedBill && !scannedBills.isEmpty()) {
                    for (PurchasedBill b : scannedBills) {
                        if (b.getBillDate() != null && b.getBillDate().equals(p.getPurchaseDate())) {
                            isDuplicateOfScannedBill = true;
                            break;
                        }
                    }
                }
            }

            if (!isDuplicateOfScannedBill) {
                List<PurchaseItem> pItems = purchaseItemRepository.findAllByPurchaseId(p.getId());
                List<BillItemSummaryDto> itemSummaries = new ArrayList<>();
                for (PurchaseItem pi : pItems) {
                    String cat = null;
                    if (pi.getCategory() != null) {
                        cat = pi.getCategory().getName();
                    } else if (pi.getInventoryItem() != null && pi.getInventoryItem().getCategory() != null) {
                        cat = pi.getInventoryItem().getCategory().getName();
                    }

                    if (cat == null || cat.isBlank() || "Groceries".equalsIgnoreCase(cat)) {
                        cat = com.homestock.modules.bill.matching.ProductMatchingEngine.inferCategory(pi.getItemName());
                    }

                    itemSummaries.add(BillItemSummaryDto.builder()
                            .id(pi.getId())
                            .itemName(pi.getItemName() != null ? pi.getItemName() : "Item")
                            .quantity(pi.getQuantity() != null ? pi.getQuantity() : BigDecimal.ONE)
                            .unit(pi.getUnit() != null ? pi.getUnit() : "pcs")
                            .unitPrice(pi.getUnitPrice() != null ? pi.getUnitPrice() : BigDecimal.ZERO)
                            .finalPrice(pi.getTotalPrice() != null ? pi.getTotalPrice() : BigDecimal.ZERO)
                            .category(cat)
                            .build());
                }

                String storeName = p.getStore() != null ? p.getStore().getName() : "Retail Store";
                String billRef = p.getNotes() != null && p.getNotes().contains("#")
                        ? p.getNotes().substring(p.getNotes().indexOf("#"))
                        : "REC-" + p.getId().toString().substring(0, 8).toUpperCase();

                monthlyBills.add(MonthlyBillSummaryDto.builder()
                        .id(p.getId())
                        .shopName(storeName)
                        .billNumber(billRef)
                        .billDate(p.getPurchaseDate())
                        .createdAt(p.getCreatedAt())
                        .totalAmount(p.getTotalAmount() != null ? p.getTotalAmount() : BigDecimal.ZERO)
                        .subtotal(p.getTotalAmount() != null ? p.getTotalAmount() : BigDecimal.ZERO)
                        .taxAmount(BigDecimal.ZERO)
                        .discountAmount(BigDecimal.ZERO)
                        .itemsCount(pItems.size())
                        .status("CONFIRMED")
                        .source("HOUSEHOLD_PURCHASE")
                        .items(itemSummaries)
                        .build());
            }
        }

        // Sort bills by date descending
        monthlyBills.sort((b1, b2) -> {
            if (b1.getBillDate() == null && b2.getBillDate() == null) return 0;
            if (b1.getBillDate() == null) return 1;
            if (b2.getBillDate() == null) return -1;
            int dateComp = b2.getBillDate().compareTo(b1.getBillDate());
            if (dateComp != 0) return dateComp;
            if (b1.getCreatedAt() != null && b2.getCreatedAt() != null) {
                return b2.getCreatedAt().compareTo(b1.getCreatedAt());
            }
            return 0;
        });

        // Compute total spend from unified bills list
        BigDecimal totalSpend = monthlyBills.stream()
                .map(MonthlyBillSummaryDto::getTotalAmount)
                .filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Long billsCount = (long) monthlyBills.size();

        long itemsCount = monthlyBills.stream()
                .mapToLong(MonthlyBillSummaryDto::getItemsCount)
                .sum();

        BigDecimal totalQuantity = monthlyBills.stream()
                .filter(b -> b.getItems() != null)
                .flatMap(b -> b.getItems().stream())
                .map(BillItemSummaryDto::getQuantity)
                .filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal avgBill = (billsCount > 0)
                ? totalSpend.divide(BigDecimal.valueOf(billsCount), 2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        // 4. Previous Month Comparison
        YearMonth prevYm = ym.minusMonths(1);
        BigDecimal prevSpend = billRepository.calculateTotalSpendInPeriod(homeId, prevYm.atDay(1), prevYm.atEndOfMonth());
        if (prevSpend == null) prevSpend = BigDecimal.ZERO;

        BigDecimal trendPercent = BigDecimal.ZERO;
        if (prevSpend.compareTo(BigDecimal.ZERO) > 0) {
            trendPercent = totalSpend.subtract(prevSpend)
                    .divide(prevSpend, 4, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100))
                    .setScale(2, RoundingMode.HALF_UP);
        }

        // 5. Category Breakdown computed directly from unified monthlyBills line items
        Map<String, CategoryAccumulator> catMap = new LinkedHashMap<>();
        for (MonthlyBillSummaryDto b : monthlyBills) {
            if (b.getItems() != null) {
                for (BillItemSummaryDto item : b.getItems()) {
                    String cName = (item.getCategory() != null && !item.getCategory().isBlank())
                            ? item.getCategory() : "Other";
                    BigDecimal price = item.getFinalPrice() != null ? item.getFinalPrice() : BigDecimal.ZERO;
                    BigDecimal q = item.getQuantity() != null ? item.getQuantity() : BigDecimal.ZERO;
                    catMap.computeIfAbsent(cName, CategoryAccumulator::new).add(price, 1, q);
                }
            }
        }

        List<CategoryExpenseDto> categoryList = new ArrayList<>();
        for (CategoryAccumulator acc : catMap.values()) {
            BigDecimal pct = BigDecimal.ZERO;
            if (totalSpend.compareTo(BigDecimal.ZERO) > 0) {
                pct = acc.totalAmount.divide(totalSpend, 4, RoundingMode.HALF_UP)
                        .multiply(BigDecimal.valueOf(100))
                        .setScale(1, RoundingMode.HALF_UP);
            }
            categoryList.add(CategoryExpenseDto.builder()
                    .categoryName(acc.name)
                    .totalAmount(acc.totalAmount.setScale(2, RoundingMode.HALF_UP))
                    .spendingPercentage(pct)
                    .purchaseCount(acc.count)
                    .quantityPurchased(acc.quantity.setScale(2, RoundingMode.HALF_UP))
                    .build());
        }

        // Reconcile any unitemized spend into General & Other to ensure exact 100% total
        BigDecimal catSum = categoryList.stream()
                .map(CategoryExpenseDto::getTotalAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        if (totalSpend.compareTo(catSum) > 0) {
            BigDecimal diff = totalSpend.subtract(catSum);
            BigDecimal pct = diff.divide(totalSpend, 4, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100))
                    .setScale(1, RoundingMode.HALF_UP);
            categoryList.add(CategoryExpenseDto.builder()
                    .categoryName("Other Groceries")
                    .totalAmount(diff.setScale(2, RoundingMode.HALF_UP))
                    .spendingPercentage(pct)
                    .purchaseCount(1L)
                    .quantityPurchased(BigDecimal.ONE)
                    .build());
        }
        categoryList.sort((c1, c2) -> c2.getTotalAmount().compareTo(c1.getTotalAmount()));

        // 6. Shop Breakdown computed directly from unified monthlyBills
        Map<String, ShopAccumulator> shopMap = new LinkedHashMap<>();
        for (MonthlyBillSummaryDto b : monthlyBills) {
            String sName = (b.getShopName() != null && !b.getShopName().isBlank())
                    ? b.getShopName() : "Retail Store";
            BigDecimal amt = b.getTotalAmount() != null ? b.getTotalAmount() : BigDecimal.ZERO;
            shopMap.computeIfAbsent(sName, ShopAccumulator::new).add(amt, 1);
        }

        List<ShopExpenseDto> shopList = new ArrayList<>();
        for (ShopAccumulator acc : shopMap.values()) {
            BigDecimal pct = BigDecimal.ZERO;
            if (totalSpend.compareTo(BigDecimal.ZERO) > 0) {
                pct = acc.totalAmount.divide(totalSpend, 4, RoundingMode.HALF_UP)
                        .multiply(BigDecimal.valueOf(100))
                        .setScale(1, RoundingMode.HALF_UP);
            }
            shopList.add(ShopExpenseDto.builder()
                    .shopName(acc.name)
                    .totalAmount(acc.totalAmount.setScale(2, RoundingMode.HALF_UP))
                    .spendingPercentage(pct)
                    .billsCount(acc.count)
                    .build());
        }
        shopList.sort((s1, s2) -> s2.getTotalAmount().compareTo(s1.getTotalAmount()));

        // 7. Calculate Price Anomalies / Inflation Spikes
        List<PriceAnomalyDto> priceAnomalies = calculatePriceAnomalies(homeId, startDate, endDate);

        // 8. Available Statement Periods with Bills
        List<BillingPeriodDto> availablePeriods = getAvailablePeriods(homeId);

        String monthName = Month.of(month).getDisplayName(TextStyle.FULL, Locale.ENGLISH);

        return MonthlyExpenseReportDto.builder()
                .year(year)
                .month(month)
                .monthName(monthName)
                .totalSpend(totalSpend)
                .billsCount(billsCount)
                .itemsPurchasedCount(itemsCount)
                .totalItemsQuantity(totalQuantity)
                .averageBillAmount(avgBill)
                .previousMonthSpend(prevSpend)
                .spendingTrendPercent(trendPercent)
                .categoryBreakdown(categoryList)
                .shopBreakdown(shopList)
                .priceAnomalies(priceAnomalies)
                .availablePeriods(availablePeriods)
                .bills(monthlyBills)
                .build();
    }

    public List<BillingPeriodDto> getAvailablePeriods(UUID homeId) {
        Map<String, BillingPeriodDto> periodMap = new TreeMap<>(Collections.reverseOrder());

        List<Object[]> rawList = billRepository.getAvailableBillingPeriods(homeId);
        if (rawList != null) {
            for (Object[] row : rawList) {
                if (row[0] != null && row[1] != null) {
                    int y = ((Number) row[0]).intValue();
                    int m = ((Number) row[1]).intValue();
                    long count = row[2] != null ? ((Number) row[2]).longValue() : 0L;
                    BigDecimal sum = row[3] != null
                            ? BigDecimal.valueOf(((Number) row[3]).doubleValue()).setScale(2, RoundingMode.HALF_UP)
                            : BigDecimal.ZERO;
                    String mName = Month.of(m).getDisplayName(TextStyle.FULL, Locale.ENGLISH);
                    String key = String.format("%04d-%02d", y, m);

                    periodMap.put(key, BillingPeriodDto.builder()
                            .year(y)
                            .month(m)
                            .monthName(mName)
                            .billsCount(count)
                            .totalSpend(sum)
                            .build());
                }
            }
        }

        List<Purchase> allPurchases = purchaseRepository.findAllByHomeIdAndPurchaseDateBetween(
                homeId, LocalDate.of(2020, 1, 1), LocalDate.now().plusYears(1)
        );
        for (Purchase p : allPurchases) {
            if (p.getPurchaseDate() != null) {
                int y = p.getPurchaseDate().getYear();
                int m = p.getPurchaseDate().getMonthValue();
                String key = String.format("%04d-%02d", y, m);
                long pCount = allPurchases.stream().filter(x -> x.getPurchaseDate() != null && x.getPurchaseDate().getYear() == y && x.getPurchaseDate().getMonthValue() == m).count();
                BigDecimal pSum = allPurchases.stream().filter(x -> x.getPurchaseDate() != null && x.getPurchaseDate().getYear() == y && x.getPurchaseDate().getMonthValue() == m)
                        .map(Purchase::getTotalAmount).reduce(BigDecimal.ZERO, BigDecimal::add);

                BillingPeriodDto existing = periodMap.get(key);
                if (existing == null) {
                    String mName = Month.of(m).getDisplayName(TextStyle.FULL, Locale.ENGLISH);
                    periodMap.put(key, BillingPeriodDto.builder()
                            .year(y)
                            .month(m)
                            .monthName(mName)
                            .billsCount(pCount)
                            .totalSpend(pSum)
                            .build());
                } else if (pCount > existing.getBillsCount()) {
                    periodMap.put(key, BillingPeriodDto.builder()
                            .year(y)
                            .month(m)
                            .monthName(existing.getMonthName())
                            .billsCount(pCount)
                            .totalSpend(existing.getTotalSpend().max(pSum))
                            .build());
                }
            }
        }

        return new ArrayList<>(periodMap.values());
    }

    private List<PriceAnomalyDto> calculatePriceAnomalies(UUID homeId, LocalDate startDate, LocalDate endDate) {
        List<ProductPriceHistory> inPeriod = priceHistoryRepository.findInPeriod(homeId, startDate, endDate);
        if (inPeriod == null || inPeriod.isEmpty()) {
            return Collections.emptyList();
        }

        List<PriceAnomalyDto> anomalies = new ArrayList<>();
        Set<UUID> inspectedProducts = new HashSet<>();
        Set<UUID> inspectedItems = new HashSet<>();

        for (ProductPriceHistory h : inPeriod) {
            UUID prodId = h.getProduct() != null ? h.getProduct().getId() : null;
            UUID itemId = h.getInventoryItem() != null ? h.getInventoryItem().getId() : null;

            if (prodId != null && inspectedProducts.contains(prodId)) continue;
            if (itemId != null && inspectedItems.contains(itemId)) continue;

            if (prodId != null) inspectedProducts.add(prodId);
            if (itemId != null) inspectedItems.add(itemId);

            List<ProductPriceHistory> priorList = priceHistoryRepository.findPriorPurchase(
                    homeId, prodId, itemId, h.getPurchaseDate(), PageRequest.of(0, 1)
            );

            if (!priorList.isEmpty()) {
                ProductPriceHistory prior = priorList.get(0);
                BigDecimal currentStandard = h.getStandardUnitPrice();
                BigDecimal priorStandard = prior.getStandardUnitPrice();

                if (currentStandard != null && priorStandard != null && priorStandard.compareTo(BigDecimal.ZERO) > 0) {
                    BigDecimal changePct = currentStandard.subtract(priorStandard)
                            .divide(priorStandard, 4, RoundingMode.HALF_UP)
                            .multiply(BigDecimal.valueOf(100))
                            .setScale(1, RoundingMode.HALF_UP);

                    String productName = h.getProduct() != null ? h.getProduct().getName()
                            : (h.getInventoryItem() != null ? h.getInventoryItem().getName() : "Item");
                    String category = h.getInventoryItem() != null && h.getInventoryItem().getCategory() != null
                            ? h.getInventoryItem().getCategory().getName() : "Groceries";

                    if (changePct.compareTo(BigDecimal.valueOf(10.0)) >= 0) {
                        anomalies.add(PriceAnomalyDto.builder()
                                .productId(prodId)
                                .inventoryItemId(itemId)
                                .productName(productName)
                                .category(category)
                                .currentPrice(currentStandard)
                                .previousPrice(priorStandard)
                                .percentageChange(changePct)
                                .unit(h.getUnit() != null ? h.getUnit() : "pcs")
                                .alertType("PRICE_HIKE")
                                .storeName(h.getStoreName() != null ? h.getStoreName() : "Local Store")
                                .detectedAt(h.getPurchaseDate().toString())
                                .build());
                    } else if (changePct.compareTo(BigDecimal.valueOf(-10.0)) <= 0) {
                        anomalies.add(PriceAnomalyDto.builder()
                                .productId(prodId)
                                .inventoryItemId(itemId)
                                .productName(productName)
                                .category(category)
                                .currentPrice(currentStandard)
                                .previousPrice(priorStandard)
                                .percentageChange(changePct)
                                .unit(h.getUnit() != null ? h.getUnit() : "pcs")
                                .alertType("PRICE_DROP")
                                .storeName(h.getStoreName() != null ? h.getStoreName() : "Local Store")
                                .detectedAt(h.getPurchaseDate().toString())
                                .build());
                    }
                }
            }
        }
        return anomalies;
    }

    public List<CategoryExpenseDto> getCategoryBreakdown(UUID homeId, int year, int month) {
        return getMonthlyReport(homeId, year, month).getCategoryBreakdown();
    }

    public List<ShopExpenseDto> getShopBreakdown(UUID homeId, int year, int month) {
        return getMonthlyReport(homeId, year, month).getShopBreakdown();
    }

    private static class CategoryAccumulator {
        final String name;
        BigDecimal totalAmount = BigDecimal.ZERO;
        long count = 0;
        BigDecimal quantity = BigDecimal.ZERO;

        CategoryAccumulator(String name) {
            this.name = name;
        }

        void add(BigDecimal amount, long c, BigDecimal qty) {
            if (amount != null) this.totalAmount = this.totalAmount.add(amount);
            this.count += c;
            if (qty != null) this.quantity = this.quantity.add(qty);
        }
    }

    private static class ShopAccumulator {
        final String name;
        BigDecimal totalAmount = BigDecimal.ZERO;
        long count = 0;

        ShopAccumulator(String name) {
            this.name = name;
        }

        void add(BigDecimal amount, long c) {
            if (amount != null) this.totalAmount = this.totalAmount.add(amount);
            this.count += c;
        }
    }
}
