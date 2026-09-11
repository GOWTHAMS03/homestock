package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductDealDto {
    private String id;
    private String canonicalProductId; // Unique canonical cluster identifier
    private String productName;
    private String brand;
    private String variantType;
    private String category;
    private String packageSize;
    private String packSize; // Alias for packageSize
    private String unit;

    private BigDecimal bestPrice;
    private BigDecimal price; // Alias for bestPrice
    private BigDecimal mrp;
    private Double discountPercent;
    private Double discountPercentage; // Alias for discountPercent

    private String bestProvider;
    private String seller; // Alias for bestProvider
    private String source; // Discovery source provider

    private BigDecimal unitPrice;
    private String unitPriceLabel;
    private BigDecimal pricePerUnit;

    private BigDecimal deliveryCharge;
    private BigDecimal effectivePrice; // price + deliveryCharge
    private BigDecimal requiredQuantityCost; // effectivePrice * requestedQuantity

    private BigDecimal savingsVsHighest;
    private String comparisonStore;

    private String imageUrl;
    private String productUrl;
    private String deepLink;

    private Double rating;
    private Integer reviewCount;
    private String availability;

    private boolean isLowestPrice;
    private boolean isBestValue;
    private boolean isPopular;
    private boolean isExactMatch;

    private Double matchConfidence;
    private Double identityConfidence;
    private Double matchScore; // 0 - 100
    private MatchStatus matchStatus;

    private Double priceConfidence;
    private PriceStatus priceStatus;
    private Instant lastVerifiedAt;

    private Double dealScore; // Combined weighted ranking score
    private int sourceCount; // Number of search engines confirming this product

    private DealEvidence evidence; // Explainable identity and price evidence

    private List<StoreOfferDto> storeOffers;
}
