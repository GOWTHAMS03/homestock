package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StoreOfferDto {
    private String storeName;
    private BigDecimal price;
    private BigDecimal mrp;
    private BigDecimal deliveryFee;
    private String estimatedDelivery;
    private String availability;
    private String productUrl;
    private String canonicalProductUrl;
    private ProductUrlType urlType;
    private boolean urlVerified;
    @Builder.Default
    private boolean directProductUrlAvailable = true;
    private String affiliateUrl;
    private String deepLink;
    private Double rating;
    private Integer reviewCount;
}
