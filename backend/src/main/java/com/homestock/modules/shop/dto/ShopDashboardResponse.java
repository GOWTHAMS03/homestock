package com.homestock.modules.shop.dto;

import lombok.*;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopDashboardResponse {
    private long todayViews;
    private long productViews;
    private long searchMatches;
    private long activeDeals;
    private int totalProducts;
    private String subscriptionPlan;
    private int maxProducts;

    private List<PopularProduct> popularProducts;
    private List<DemandItem> nearbyDemand;
    private List<AttentionItem> productsNeedingAttention;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PopularProduct {
        private String productName;
        private long viewCount;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DemandItem {
        private String query;
        private long searchCount;
        private String demandLevel; // HIGH, MEDIUM, LOW
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AttentionItem {
        private String productName;
        private String reason; // OUT_OF_STOCK, PRICE_NOT_UPDATED, OFFER_EXPIRED
        private String productId;
    }
}
