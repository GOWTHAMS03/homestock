package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductDealDto {
    private String id;
    private String productName;
    private String brand;
    private String variantType;
    private String category;
    private String packageSize;
    private String unit;
    private BigDecimal bestPrice;
    private BigDecimal mrp;
    private Double discountPercent;
    private String bestProvider;
    private BigDecimal unitPrice;
    private String unitPriceLabel;
    private BigDecimal savingsVsHighest;
    private String comparisonStore;
    private String imageUrl;
    private String productUrl;
    private String deepLink;
    private Double rating;
    private Integer reviewCount;
    private boolean isLowestPrice;
    private boolean isBestValue;
    private boolean isPopular;
    private boolean isExactMatch;
    private Double matchConfidence;
    private List<StoreOfferDto> storeOffers;
}
