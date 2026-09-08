package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BasketOptionDto {
    private String optionType; // OPTION_A_INDIVIDUAL_BEST, OPTION_B_SINGLE_STORE, OPTION_C_LOWEST_NET_DELIVERY
    private String title;
    private String storeName;
    private BigDecimal itemsSubtotal;
    private BigDecimal deliveryFeesTotal;
    private BigDecimal netTotal;
    private BigDecimal potentialSavings;
    private String recommendationReason;
    private List<BasketItemDto> items;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BasketItemDto {
        private UUID shoppingItemId;
        private String itemName;
        private BigDecimal quantity;
        private String unit;
        private String provider;
        private String providerProductId;
        private String productTitle;
        private BigDecimal price;
        private BigDecimal deliveryCharge;
        private BigDecimal effectivePrice;
        private BigDecimal pricePerUnit;
        private String pricePerUnitLabel;
        private String matchType;
        private Double matchConfidence;
        private String freshness;
        private String affiliateUrl;
        private String productUrl;
        private String imageUrl;
    }
}
