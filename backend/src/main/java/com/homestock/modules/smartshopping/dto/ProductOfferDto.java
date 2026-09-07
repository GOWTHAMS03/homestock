package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Normalized product offer DTO consumed by Flutter.
 * <p>
 * Every provider's response is transformed into this common model
 * so the frontend never deals with provider-specific data structures.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductOfferDto {

    private String provider;
    private String providerProductId;
    private String productName;
    private String brand;
    private String description;
    private String imageUrl;
    private String productUrl;
    private String affiliateUrl;

    private BigDecimal price;
    private String currency;
    private BigDecimal deliveryCharge;
    private BigDecimal effectivePrice;

    private String availability;
    private String estimatedDelivery;

    private String packageSize;
    private String unit;
    private BigDecimal rating;
    private Integer reviewCount;

    private Double matchConfidence;
    private String matchType; // EXACT, SIMILAR, NO_MATCH

    private BigDecimal pricePerUnit;
    private String pricePerUnitLabel; // e.g. "₹50/kg"

    private Instant lastCheckedAt;

    /** Whether this offer came from cache and may be stale */
    @Builder.Default
    private boolean fromCache = false;
}
