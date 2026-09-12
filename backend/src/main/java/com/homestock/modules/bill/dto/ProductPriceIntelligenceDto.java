package com.homestock.modules.bill.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductPriceIntelligenceDto {
    private UUID productId;
    private UUID inventoryItemId;
    private String productName;
    private String unit;
    private BigDecimal currentPrice;
    private BigDecimal previousPrice;
    private BigDecimal priceChangePercent;
    private BigDecimal averagePrice;
    private BigDecimal minPrice;
    private BigDecimal maxPrice;
    private boolean isHigherThanUsual;
    private String recommendedStore;
    @Builder.Default
    private List<ProductPriceHistoryDto> recentPurchases = new ArrayList<>();
    @Builder.Default
    private List<StorePriceComparisonDto> storeComparisons = new ArrayList<>();
}
