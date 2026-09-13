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

        // 1. Fetch all PurchasedBills in Period
        List<PurchasedBill> scannedBills = billRepository.findBillsInPeriod(homeId, startDate, endDate);
        List<MonthlyBillSummaryDto> monthlyBills = new ArrayList<>();
        Set<String> matchedPurchaseIdentifiers = new HashSet<>();

        for (PurchasedBill b : scannedBills) {
            List<PurchasedBillItem> items = billItemRepository.findByBillId(b.getId());
            List<BillItemSummaryDto> itemSummaries = new ArrayList<>();
            for (PurchasedBillItem item : items) {
                itemSummaries.add(BillItemSummaryDto.builder()
                        .id(item.getId())
                        .itemName(item.getNormalizedItemName() != null ? item.getNormalizedItemName() : item.getRawItemName())
                        .quantity(item.getQuantity())
                        .unit(item.getUnit())
                        .unitPrice(item.getUnitPrice())
                        .finalPrice(item.getFinalPrice())
                        .category(item.getProduct() != null && item.getProduct().getCategory() != null ? item.getProduct().getCategory().getName() : "Groceries")
                        .build());
            }

            monthlyBills.add(MonthlyBillSummaryDto.builder()
                    .id(b.getId())
                    .shopName(b.getShopName() != null ? b.getShopName() : "Retail Store")
                    .billNumber(b.getBillNumber() != null ? b.getBillNumber() : "N/A")
                    .billDate(b.getBillDate())
                    .totalAmount(b.getTotalAmount() != null ? b.getTotalAmount() : BigDecimal.ZERO)
                    .subtotal(b.getSubtotal())
                    .taxAmount(b.getTaxAmount())
                    .discountAmount(b.getDiscountAmount())
                    .itemsCount(items.size())
                    .status(b.getStatus())
                    .source("AI_SCANNED")
                    .items(itemSummaries)
                    .build());

            if (b.getBillNumber() != null) {
                matchedPurchaseIdentifiers.add(b.getBillNumber().trim().toLowerCase());
            }
        }

        // 2. Fetch Household Purchases in Period
        List<Purchase> purchases = purchaseRepository.findAllByHomeIdAndPurchaseDateBetween(homeId, startDate, endDate);
        int matchedScannedCount = 0;

        for (Purchase p : purchases) {
            boolean isFirstMatchingDuplicate = false;
            if (p.getNotes() != null) {
                for (String billNum : matchedPurchaseIdentifiers) {
                    if (p.getNotes().toLowerCase().contains(billNum)) {
                        if (matchedScannedCount == 0 && !scannedBills.isEmpty()) {
                            isFirstMatchingDuplicate = true;
                            matchedScannedCount++;
                        }
                        break;
                    }
                }
            }

            if (!isFirstMatchingDuplicate) {
                List<PurchaseItem> pItems = purchaseItemRepository.findAllByPurchaseId(p.getId());
                List<BillItemSummaryDto> itemSummaries = new ArrayList<>();
                for (PurchaseItem pi : pItems) {
                    itemSummaries.add(BillItemSummaryDto.builder()
                            .id(pi.getId())
                            .itemName(pi.getItemName())
                            .quantity(pi.getQuantity())
                            .unit(pi.getUnit())
                            .unitPrice(pi.getUnitPrice())
                            .finalPrice(pi.getTotalPrice())
                            .category(pi.getCategory() != null ? pi.getCategory().getName() : "Groceries")
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
                        .totalAmount(p.getTotalAmount())
                        .subtotal(p.getTotalAmount())
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
            return b2.getBillDate().compareTo(b1.getBillDate());
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

        BigDecimal totalQuantity = BigDecimal.valueOf(itemsCount);

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

        // 5. Category Breakdown
        List<CategoryExpenseDto> categoryList = getCategoryBreakdown(homeId, year, month, totalSpend);

        // 6. Shop Breakdown
        List<ShopExpenseDto> shopList = getShopBreakdown(homeId, year, month, totalSpend);

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
        YearMonth ym = YearMonth.of(year, month);
        BigDecimal totalSpend = billRepository.calculateTotalSpendInPeriod(homeId, ym.atDay(1), ym.atEndOfMonth());
        return getCategoryBreakdown(homeId, year, month, totalSpend != null ? totalSpend : BigDecimal.ZERO);
    }

    private List<CategoryExpenseDto> getCategoryBreakdown(UUID homeId, int year, int month, BigDecimal totalSpend) {
        YearMonth ym = YearMonth.of(year, month);
        List<Object[]> rawList = billItemRepository.getCategorySpendingBreakdown(homeId, ym.atDay(1), ym.atEndOfMonth());
        List<CategoryExpenseDto> result = new ArrayList<>();

        for (Object[] row : rawList) {
            if (row[0] != null && row[1] != null) {
                String catName = (String) row[0];
                BigDecimal amount = BigDecimal.valueOf(((Number) row[1]).doubleValue()).setScale(2, RoundingMode.HALF_UP);
                long count = row[2] != null ? ((Number) row[2]).longValue() : 0L;
                BigDecimal qty = row[3] != null ? BigDecimal.valueOf(((Number) row[3]).doubleValue()).setScale(2, RoundingMode.HALF_UP) : BigDecimal.ZERO;

                BigDecimal pct = BigDecimal.ZERO;
                if (totalSpend.compareTo(BigDecimal.ZERO) > 0) {
                    pct = amount.divide(totalSpend, 4, RoundingMode.HALF_UP)
                            .multiply(BigDecimal.valueOf(100))
                            .setScale(1, RoundingMode.HALF_UP);
                }

                result.add(CategoryExpenseDto.builder()
                        .categoryName(catName)
                        .totalAmount(amount)
                        .spendingPercentage(pct)
                        .purchaseCount(count)
                        .quantityPurchased(qty)
                        .build());
            }
        }
        return result;
    }

    public List<ShopExpenseDto> getShopBreakdown(UUID homeId, int year, int month) {
        YearMonth ym = YearMonth.of(year, month);
        BigDecimal totalSpend = billRepository.calculateTotalSpendInPeriod(homeId, ym.atDay(1), ym.atEndOfMonth());
        return getShopBreakdown(homeId, year, month, totalSpend != null ? totalSpend : BigDecimal.ZERO);
    }

    private List<ShopExpenseDto> getShopBreakdown(UUID homeId, int year, int month, BigDecimal totalSpend) {
        YearMonth ym = YearMonth.of(year, month);
        List<Object[]> rawList = billRepository.getShopSpendingBreakdown(homeId, ym.atDay(1), ym.atEndOfMonth());
        List<ShopExpenseDto> result = new ArrayList<>();

        for (Object[] row : rawList) {
            if (row[0] != null && row[1] != null) {
                String shop = (String) row[0];
                BigDecimal amount = BigDecimal.valueOf(((Number) row[1]).doubleValue()).setScale(2, RoundingMode.HALF_UP);
                long count = row[2] != null ? ((Number) row[2]).longValue() : 0L;

                BigDecimal pct = BigDecimal.ZERO;
                if (totalSpend.compareTo(BigDecimal.ZERO) > 0) {
                    pct = amount.divide(totalSpend, 4, RoundingMode.HALF_UP)
                            .multiply(BigDecimal.valueOf(100))
                            .setScale(1, RoundingMode.HALF_UP);
                }

                result.add(ShopExpenseDto.builder()
                        .shopName(shop)
                        .totalAmount(amount)
                        .spendingPercentage(pct)
                        .billsCount(count)
                        .build());
            }
        }
        return result;
    }
}
