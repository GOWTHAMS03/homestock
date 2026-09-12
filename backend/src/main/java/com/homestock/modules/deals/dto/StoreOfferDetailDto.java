package com.homestock.modules.deals.dto;

import com.homestock.modules.deals.model.DealSource;
import com.homestock.modules.deals.model.DealValidationStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Offer detail from a specific store under a canonical product.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StoreOfferDetailDto {
    private String storeName;
    private DealSource source;
    private BigDecimal price;
    private BigDecimal mrp;
    private BigDecimal deliveryCharge;
    private BigDecimal finalPrice;
    private String availability;
    private String deliveryStatus;
    private String productUrl;
    private String affiliateUrl;
    private DealValidationStatus validationStatus;
    private Instant lastVerifiedAt;
    private String freshnessLabel;
    private boolean isBestPrice;
}
