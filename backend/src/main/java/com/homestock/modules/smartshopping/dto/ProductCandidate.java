package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Common normalized candidate model collected across search providers
 * prior to deduplication, verification, and deal ranking.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductCandidate {

    private String candidateId;
    private String provider;
    private String providerProductId;
    private String barcode;

    private String productName;
    private String brand;
    private String canonicalBrand;
    private String canonicalProduct;
    private String variant;
    private String packageSize;
    private String unit;
    private BigDecimal normalizedPackSizeValue;
    private String normalizedPackSizeUnit;

    private String category;
    private String description;

    private BigDecimal price;
    private BigDecimal mrp;
    private String currency;
    private BigDecimal deliveryCharge;
    private BigDecimal effectivePrice;

    private String availability;
    private String estimatedDelivery;

    private String productUrl;
    private String affiliateUrl;
    private String deepLink;
    private String imageUrl;

    private Double rating;
    private Integer reviewCount;

    private Double matchScore;
    private MatchStatus matchStatus;
    private PriceStatus priceStatus;
    private Double priceConfidence;
    private Instant lastVerifiedAt;
    private String imageVerificationTier; // OFFICIAL_PRODUCT_PAGE, TRUSTED_RETAILER, CATALOG, SEARCH_SNIPPET
    private Double imageConfidence;

    @Builder.Default
    private int sourceAgreementCount = 1;
    private DealEvidence evidence;
    private RejectionReason rejectionReason;

    public Double getPriceAsDouble() {
        return price != null ? price.doubleValue() : 0.0;
    }

    public BigDecimal getOriginalPrice() {
        return mrp != null ? mrp : price;
    }

    public Double getScore() {
        return matchScore;
    }

    public void setScore(Double score) {
        this.matchScore = score;
    }

    public boolean isInStock() {
        return availability == null || "IN_STOCK".equalsIgnoreCase(availability);
    }

    public Double getSellerRating() {
        return rating != null ? rating : 4.0;
    }

    public Double getDiscountPercent() {
        if (mrp != null && price != null && mrp.compareTo(BigDecimal.ZERO) > 0) {
            return Math.max(0.0, (mrp.doubleValue() - price.doubleValue()) / mrp.doubleValue() * 100.0);
        }
        return 0.0;
    }
}
