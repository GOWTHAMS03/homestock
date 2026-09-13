package com.homestock.modules.deals.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.product.entity.Product;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Verified product price and stock offering at a physical retail store.
 */
@Entity
@Table(name = "shop_product_offers", indexes = {
        @Index(name = "idx_spo_shop_id", columnList = "shop_id"),
        @Index(name = "idx_spo_product_id", columnList = "product_id"),
        @Index(name = "idx_spo_normalized_name", columnList = "normalized_name"),
        @Index(name = "idx_spo_last_verified", columnList = "last_verified_at")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopProductOffer extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_id", nullable = false)
    private NearbyShop shop;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id")
    private Product product;

    @Column(name = "raw_product_name", nullable = false, length = 255)
    private String rawProductName;

    @Column(name = "normalized_name", nullable = false, length = 255)
    private String normalizedName;

    @Column(name = "brand", length = 100)
    private String brand;

    @Column(name = "package_size", precision = 10, scale = 3)
    private BigDecimal packageSize;

    @Column(name = "unit", length = 30)
    private String unit;

    @Column(name = "price", precision = 12, scale = 2, nullable = false)
    private BigDecimal price;

    @Column(name = "mrp", precision = 12, scale = 2)
    private BigDecimal mrp;

    @Column(name = "effective_price", precision = 12, scale = 2, nullable = false)
    private BigDecimal effectivePrice;

    @Column(name = "price_per_unit", precision = 12, scale = 4)
    private BigDecimal pricePerUnit;

    @Column(name = "price_per_unit_label", length = 50)
    private String pricePerUnitLabel;

    @Builder.Default
    @Column(name = "stock_status", nullable = false, length = 50)
    private String stockStatus = "IN_STOCK"; // IN_STOCK, LOW_STOCK, OUT_OF_STOCK, UNCONFIRMED

    @Builder.Default
    @Column(name = "source", nullable = false, length = 50)
    private String source = "SHOP_CATALOG"; // SHOP_CATALOG, USER_REPORTED, BILL_HISTORY, PARTNER_FEED

    @Builder.Default
    @Column(name = "confidence", nullable = false, length = 20)
    private String confidence = "HIGH"; // HIGH, MEDIUM, LOW

    @Builder.Default
    @Column(name = "last_verified_at", nullable = false)
    private Instant lastVerifiedAt = Instant.now();
}
