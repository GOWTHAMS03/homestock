package com.homestock.modules.deals.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopDealDto {
    private UUID id;
    private UUID shopId;
    private String shopName;
    private String shopType;
    private Double distanceKm;
    private String distanceLabel;
    private UUID productId;
    private String productName;
    private String rawProductName;
    private String brand;
    private BigDecimal packageSize;
    private String unit;
    private BigDecimal price;
    private BigDecimal mrp;
    private BigDecimal effectivePrice;
    private BigDecimal pricePerUnit;
    private String pricePerUnitLabel;
    private String stockStatus; // IN_STOCK, LOW_STOCK, OUT_OF_STOCK, UNCONFIRMED
    private String source; // SHOP_CATALOG, USER_REPORTED, BILL_HISTORY, PARTNER_FEED
    private String confidence; // HIGH, MEDIUM, LOW
    private Instant lastVerifiedAt;
    private String freshnessStatus; // LIVE (<1h), RECENT (1-6h), OLDER (6-24h), STALE (>24h)
    private String freshnessLabel; // "Verified 30 mins ago"
    private Boolean isAvailable;

    // User Bill Intelligence: historical benchmark if available
    private BigDecimal userPreviousPrice;
    private Instant userPreviousPurchaseDate;
    private String userPreviousStoreName;
    private String priceComparisonNote; // "Your previous price was ₹245. Current best is ₹229."
}
