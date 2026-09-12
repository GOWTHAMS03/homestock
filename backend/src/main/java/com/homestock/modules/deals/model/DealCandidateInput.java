package com.homestock.modules.deals.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Standard candidate input evaluated by the Product Matching Engine and Validation Engine.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DealCandidateInput {
    private UUID productId;
    private DealSource source;
    private String externalProductId;
    private String title;
    private String brand;
    private String category;
    private String variant;
    private BigDecimal quantity;
    private String unit;
    @Builder.Default
    private Integer packCount = 1;
    private BigDecimal price;
    private BigDecimal mrp;
    private BigDecimal deliveryCharge;
    private BigDecimal discount;
    private BigDecimal couponDiscount;
    private String currency;
    private String availability;
    private String deliveryStatus;
    private String sellerName;
    private String productUrl;
    private String affiliateUrl;
    private String imageUrl;
    private Double sellerRating;
    private Double confidence;
}
