package com.homestock.modules.analytics.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AnalyticsOverviewDto {
    private BigDecimal monthlySpending;
    private String currency;
    private List<CategorySpendingDto> categorySpending;
    private List<StoreSpendingDto> storeSpending;
    private List<TopItemDto> mostPurchasedItems;
    private List<TopItemDto> mostConsumedItems;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CategorySpendingDto {
        private String categoryName;
        private BigDecimal amount;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class StoreSpendingDto {
        private String storeName;
        private BigDecimal amount;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TopItemDto {
        private String name;
        private BigDecimal quantity;
        private long count;
    }
}
