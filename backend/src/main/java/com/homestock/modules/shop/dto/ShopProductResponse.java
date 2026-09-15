package com.homestock.modules.shop.dto;

import com.homestock.modules.deals.entity.ShopProductOffer;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopProductResponse {
    private UUID id;
    private UUID shopId;
    private UUID productId;
    private String productName;
    private String brand;
    private BigDecimal packageSize;
    private String unit;
    private BigDecimal price;
    private BigDecimal mrp;
    private BigDecimal effectivePrice;
    private BigDecimal offerPrice;
    private Instant offerStart;
    private Instant offerEnd;
    private Boolean hasActiveOffer;
    private String stockStatus;
    private String availabilityStatus;
    private String stockVisibility;
    private BigDecimal stockQuantity;
    private BigDecimal pricePerUnit;
    private String pricePerUnitLabel;
    private Instant lastVerifiedAt;
    private String imageUrl;

    // Customer discovery fields
    private String shopName;
    private Double distanceKm;

    public static ShopProductResponse fromEntity(ShopProductOffer offer) {
        return ShopProductResponse.builder()
                .id(offer.getId())
                .shopId(offer.getShop() != null ? offer.getShop().getId() : null)
                .productId(offer.getProduct() != null ? offer.getProduct().getId() : null)
                .productName(offer.getRawProductName())
                .brand(offer.getBrand())
                .packageSize(offer.getPackageSize())
                .unit(offer.getUnit())
                .price(offer.getPrice())
                .mrp(offer.getMrp())
                .effectivePrice(offer.getEffectivePrice())
                .offerPrice(offer.getOfferPrice())
                .offerStart(offer.getOfferStart())
                .offerEnd(offer.getOfferEnd())
                .hasActiveOffer(offer.hasActiveOffer())
                .stockStatus(offer.getStockStatus())
                .availabilityStatus(offer.getAvailabilityStatus())
                .stockVisibility(offer.getStockVisibility())
                .pricePerUnit(offer.getPricePerUnit())
                .pricePerUnitLabel(offer.getPricePerUnitLabel())
                .lastVerifiedAt(offer.getLastVerifiedAt())
                .shopName(offer.getShop() != null ? offer.getShop().getName() : null)
                .build();
    }
}
