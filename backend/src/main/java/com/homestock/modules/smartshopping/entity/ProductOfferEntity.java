package com.homestock.modules.smartshopping.entity;

import com.homestock.core.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Cached product offer from a shopping provider.
 * Acts as the price cache — offers are refreshed based on configurable TTL.
 */
@Entity
@Table(name = "product_offers", indexes = {
        @Index(name = "idx_po_provider_product", columnList = "provider, provider_product_id"),
        @Index(name = "idx_po_canonical", columnList = "canonical_product_id"),
        @Index(name = "idx_po_last_checked", columnList = "last_checked_at")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductOfferEntity extends BaseEntity {

    @Column(name = "provider", nullable = false, length = 50)
    private String provider;

    @Column(name = "provider_product_id", nullable = false, length = 200)
    private String providerProductId;

    @Column(name = "canonical_product_id", length = 200)
    private String canonicalProductId;

    @Column(name = "product_name", nullable = false, length = 300)
    private String productName;

    @Column(name = "brand", length = 150)
    private String brand;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "package_size", length = 50)
    private String packageSize;

    @Column(name = "unit", length = 30)
    private String unit;

    @Column(name = "product_url", length = 1000)
    private String productUrl;

    @Column(name = "affiliate_url", length = 1000)
    private String affiliateUrl;

    @Column(name = "image_url", length = 500)
    private String imageUrl;

    @Column(name = "price", precision = 12, scale = 2)
    private BigDecimal price;

    @Column(name = "delivery_charge", precision = 12, scale = 2)
    private BigDecimal deliveryCharge;

    @Column(name = "effective_price", precision = 12, scale = 2)
    private BigDecimal effectivePrice;

    @Builder.Default
    @Column(name = "currency", length = 3)
    private String currency = "INR";

    @Column(name = "availability", length = 50)
    private String availability;

    @Column(name = "estimated_delivery", length = 100)
    private String estimatedDelivery;

    @Column(name = "rating", precision = 3, scale = 1)
    private BigDecimal rating;

    @Column(name = "review_count")
    private Integer reviewCount;

    @Column(name = "match_confidence")
    private Double matchConfidence;

    @Column(name = "last_checked_at")
    private Instant lastCheckedAt;
}
