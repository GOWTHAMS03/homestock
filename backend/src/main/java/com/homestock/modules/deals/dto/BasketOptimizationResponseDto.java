package com.homestock.modules.deals.dto;

import lombok.*;

import java.math.BigDecimal;
import java.util.List;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BasketOptimizationResponseDto {

    private Integer totalItems;
    private Integer availableItems;
    private BasketOptionDto bestSingleStoreOption;
    private BasketOptionDto maximumSavingsOption;
    private String tradeOffExplanation;
    private String geminiAiRecommendation;
    private List<ItemDealComparisonDto> itemComparisons;

    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BasketOptionDto {
        private String optionType; // "SINGLE_STORE" vs "MAXIMUM_SAVINGS"
        private String title; // "Buy everything from Local Supermarket" vs "Buy from 2 stores"
        private String subtitle;
        private List<String> storeNames;
        private Integer storeCount;
        private BigDecimal basketItemsTotal;
        private BigDecimal estimatedDeliveryOrTravelCost;
        private BigDecimal effectiveGrandTotal;
        private BigDecimal potentialSavings;
        private Double totalTravelDistanceKm;
        private List<BasketItemAssignmentDto> assignments;
    }

    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BasketItemAssignmentDto {
        private String itemName;
        private String storeName;
        private String storeType; // "LOCAL_SHOP" or "ONLINE"
        private BigDecimal quantity;
        private String unit;
        private BigDecimal price;
        private BigDecimal unitPrice;
        private String unitPriceLabel;
        private String availability;
    }

    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ItemDealComparisonDto {
        private String itemName;
        private BigDecimal requestedQuantity;
        private String requestedUnit;
        private ShopDealDto bestNearbyDeal;
        private List<OnlineDealOfferDto> onlineOffers;
        private List<ShopDealDto> alternativeLocalDeals;
        private String billHistoryBenchmark; // "Last purchased at ₹245 on 12 Sep"
    }

    @Getter
    @Setter
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class OnlineDealOfferDto {
        private String provider; // "Amazon", "Flipkart", "Blinkit", "BigBasket", "Zepto"
        private String title;
        private BigDecimal price;
        private BigDecimal deliveryCharge;
        private BigDecimal effectivePrice;
        private BigDecimal pricePerUnit;
        private String pricePerUnitLabel;
        private String productUrl;
        private String stockStatus;
        private String estimatedDelivery;
    }
}
