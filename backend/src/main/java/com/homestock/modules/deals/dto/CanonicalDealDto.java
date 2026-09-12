package com.homestock.modules.deals.dto;

import com.homestock.modules.deals.model.DealConfidenceLevel;
import com.homestock.modules.deals.model.DealSource;
import com.homestock.modules.deals.model.DealValidationStatus;
import com.homestock.modules.deals.model.MatchSignal;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * Clean canonical deal card merging multiple store offers for the exact same product.
 * Phases 18, 20 & 21.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CanonicalDealDto {
    private String canonicalId;
    private String productName;
    private String brand;
    private String variant;
    private String packageSize;
    private BigDecimal quantity;
    private String unit;
    @Builder.Default
    private Integer packCount = 1;
    private BigDecimal bestPrice;
    private BigDecimal bestFinalPrice;
    private DealSource bestSource;
    private String bestProductUrl;
    private String bestAffiliateUrl;
    private String imageUrl;
    private boolean exactMatch;
    private double matchScore;
    private double confidenceScore;
    private DealConfidenceLevel confidenceLevel;
    private DealValidationStatus validationStatus;
    private Instant lastVerifiedAt;
    private String freshnessLabel;
    private String category;
    private String sellerName;
    @Builder.Default
    private List<StoreOfferDetailDto> otherStores = new ArrayList<>();
    @Builder.Default
    private List<MatchSignal> signals = new ArrayList<>();
}
