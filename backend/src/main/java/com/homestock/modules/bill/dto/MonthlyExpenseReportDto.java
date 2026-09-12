package com.homestock.modules.bill.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MonthlyExpenseReportDto {
    private int year;
    private int month;
    private String monthName;
    private BigDecimal totalSpend;
    private long billsCount;
    private long itemsPurchasedCount;
    private BigDecimal totalItemsQuantity;
    private BigDecimal averageBillAmount;
    private BigDecimal previousMonthSpend;
    private BigDecimal spendingTrendPercent; // e.g. +8.20% vs August
    @Builder.Default
    private List<CategoryExpenseDto> categoryBreakdown = new ArrayList<>();
    @Builder.Default
    private List<ShopExpenseDto> shopBreakdown = new ArrayList<>();
}
