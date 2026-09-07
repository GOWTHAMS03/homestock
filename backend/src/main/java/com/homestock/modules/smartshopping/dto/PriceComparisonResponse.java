package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Map;

/**
 * Full price comparison response returned to Flutter.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PriceComparisonResponse {

    private ShoppingItemSummary shoppingItem;
    private List<ProductOfferDto> offers;
    private ProductOfferDto bestOffer;
    private Map<String, ProviderStatusDto> providerStatuses;
    private LocalEstimateDto localEstimate;
    private Instant lastUpdated;

    /**
     * Summary of the shopping item being compared.
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ShoppingItemSummary {
        private String id;
        private String name;
        private BigDecimal quantity;
        private String unit;
        private String brand;
        private String categoryName;
    }

    /**
     * Status of each provider during the comparison request.
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ProviderStatusDto {
        private String provider;
        private String status; // SUCCESS, FAILED, TIMEOUT, DISABLED
        private String message;
        private int offerCount;
        private long responseTimeMs;
    }

    /**
     * Estimated local price range, if available.
     */
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LocalEstimateDto {
        private BigDecimal minPrice;
        private BigDecimal maxPrice;
        private BigDecimal averagePrice;
        private String source; // e.g. "Historical purchases", "Estimated"
    }
}
