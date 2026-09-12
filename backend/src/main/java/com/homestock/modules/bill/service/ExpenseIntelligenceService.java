package com.homestock.modules.bill.service;

import com.homestock.modules.bill.dto.CategoryExpenseDto;
import com.homestock.modules.bill.dto.MonthlyExpenseReportDto;
import com.homestock.modules.bill.dto.ShopExpenseDto;
import com.homestock.modules.bill.repository.PurchasedBillItemRepository;
import com.homestock.modules.bill.repository.PurchasedBillRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.Month;
import java.time.YearMonth;
import java.time.format.TextStyle;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
public class ExpenseIntelligenceService {

    private final PurchasedBillRepository billRepository;
    private final PurchasedBillItemRepository billItemRepository;

    public ExpenseIntelligenceService(
            PurchasedBillRepository billRepository,
            PurchasedBillItemRepository billItemRepository
    ) {
        this.billRepository = billRepository;
        this.billItemRepository = billItemRepository;
    }

    @Transactional(readOnly = true)
    public MonthlyExpenseReportDto getMonthlyReport(UUID homeId, int year, int month) {
        YearMonth ym = YearMonth.of(year, month);
        LocalDate startDate = ym.atDay(1);
        LocalDate endDate = ym.atEndOfMonth();

        // 1. Current Month Spend & Bills Count
        BigDecimal totalSpend = billRepository.calculateTotalSpendInPeriod(homeId, startDate, endDate);
        if (totalSpend == null) totalSpend = BigDecimal.ZERO;

        Long billsCount = billRepository.countBillsInPeriod(homeId, startDate, endDate);
        if (billsCount == null) billsCount = 0L;

        // 2. Item count & quantity
        List<Object[]> itemStats = billItemRepository.getItemCountsInPeriod(homeId, startDate, endDate);
        long itemsCount = 0L;
        BigDecimal totalQuantity = BigDecimal.ZERO;
        if (itemStats != null && !itemStats.isEmpty() && itemStats.get(0) != null) {
            Object[] row = itemStats.get(0);
            if (row[0] != null) itemsCount = ((Number) row[0]).longValue();
            if (row[1] != null) totalQuantity = BigDecimal.valueOf(((Number) row[1]).doubleValue()).setScale(2, RoundingMode.HALF_UP);
        }

        // 3. Average Bill Amount
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
                .build();
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
