package com.homestock.modules.deals.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.deals.model.DealSource;
import com.homestock.modules.deals.model.DealValidationStatus;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Validated deal entity reflecting real-time offer from external shopping providers.
 */
@Entity
@Table(name = "deals", indexes = {
        @Index(name = "idx_deals_product_id", columnList = "product_id"),
        @Index(name = "idx_deals_source_ext", columnList = "source, external_product_id"),
        @Index(name = "idx_deals_validation_status", columnList = "validation_status"),
        @Index(name = "idx_deals_last_verified", columnList = "last_verified_at"),
        @Index(name = "idx_deals_final_price", columnList = "final_price"),
        @Index(name = "idx_deals_canonical_id", columnList = "canonical_product_id")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DealEntity extends BaseEntity {

    @Column(name = "product_id")
    private UUID productId;

    @Column(name = "canonical_product_id", length = 200)
    private String canonicalProductId;

    @Enumerated(EnumType.STRING)
    @Column(name = "source", nullable = false, length = 50)
    private DealSource source;

    @Column(name = "external_product_id", nullable = false, length = 200)
    private String externalProductId;

    @Column(name = "product_name", nullable = false, length = 300)
    private String productName;

    @Column(name = "brand", length = 150)
    private String brand;

    @Column(name = "variant", length = 100)
    private String variant;

    @Column(name = "quantity", precision = 12, scale = 3)
    private BigDecimal quantity;

    @Column(name = "unit", length = 30)
    private String unit;

    @Builder.Default
    @Column(name = "pack_count", nullable = false)
    private Integer packCount = 1;

    @Column(name = "price", precision = 12, scale = 2, nullable = false)
    private BigDecimal price;

    @Builder.Default
    @Column(name = "delivery_charge", precision = 12, scale = 2, nullable = false)
    private BigDecimal deliveryCharge = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "discount", precision = 12, scale = 2, nullable = false)
    private BigDecimal discount = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "coupon_discount", precision = 12, scale = 2, nullable = false)
    private BigDecimal couponDiscount = BigDecimal.ZERO;

    @Column(name = "final_price", precision = 12, scale = 2, nullable = false)
    private BigDecimal finalPrice;

    @Builder.Default
    @Column(name = "currency", nullable = false, length = 10)
    private String currency = "INR";

    @Builder.Default
    @Column(name = "stock_status", nullable = false, length = 50)
    private String stockStatus = "IN_STOCK";

    @Column(name = "delivery_status", length = 100)
    private String deliveryStatus;

    @Column(name = "seller_name", length = 150)
    private String sellerName;

    @Column(name = "product_url", nullable = false, length = 1000)
    private String productUrl;

    @Column(name = "affiliate_url", length = 1000)
    private String affiliateUrl;

    @Column(name = "image_url", length = 500)
    private String imageUrl;

    @Builder.Default
    @Column(name = "match_score", nullable = false)
    private Double matchScore = 1.0;

    @Builder.Default
    @Column(name = "confidence_score", nullable = false)
    private Double confidenceScore = 100.0;

    @Enumerated(EnumType.STRING)
    @Column(name = "validation_status", nullable = false, length = 50)
    private DealValidationStatus validationStatus;

    @Column(name = "last_verified_at", nullable = false)
    private Instant lastVerifiedAt;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    public boolean isExpired() {
        return expiresAt != null && Instant.now().isAfter(expiresAt);
    }
}
