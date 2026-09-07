package com.homestock.modules.smartshopping.entity;

import com.homestock.core.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Historical price record for trend analysis.
 * Stores snapshots of product prices over time.
 */
@Entity
@Table(name = "price_history", indexes = {
        @Index(name = "idx_ph_provider_product", columnList = "provider, provider_product_id"),
        @Index(name = "idx_ph_recorded_at", columnList = "recorded_at")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PriceHistory extends BaseEntity {

    @Column(name = "provider", nullable = false, length = 50)
    private String provider;

    @Column(name = "provider_product_id", nullable = false, length = 200)
    private String providerProductId;

    @Column(name = "product_name", length = 300)
    private String productName;

    @Column(name = "price", nullable = false, precision = 12, scale = 2)
    private BigDecimal price;

    @Column(name = "delivery_charge", precision = 12, scale = 2)
    private BigDecimal deliveryCharge;

    @Column(name = "effective_price", precision = 12, scale = 2)
    private BigDecimal effectivePrice;

    @Builder.Default
    @Column(name = "currency", length = 3)
    private String currency = "INR";

    @Column(name = "recorded_at", nullable = false)
    private Instant recordedAt;
}
