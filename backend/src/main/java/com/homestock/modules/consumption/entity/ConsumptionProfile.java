package com.homestock.modules.consumption.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.product.entity.Product;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

@Entity
@Table(name = "consumption_profiles", uniqueConstraints = {
        @UniqueConstraint(name = "uq_consumption_item", columnNames = {"home_id", "inventory_item_id"})
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConsumptionProfile extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "home_id", nullable = false)
    private Home home;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "inventory_item_id", nullable = false)
    private InventoryItem inventoryItem;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id")
    private Product product;

    @Builder.Default
    @Column(name = "average_daily_consumption", nullable = false, precision = 12, scale = 4)
    private BigDecimal averageDailyConsumption = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "weighted_daily_consumption", nullable = false, precision = 12, scale = 4)
    private BigDecimal weightedDailyConsumption = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "min_daily_consumption", nullable = false, precision = 12, scale = 4)
    private BigDecimal minDailyConsumption = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "max_daily_consumption", nullable = false, precision = 12, scale = 4)
    private BigDecimal maxDailyConsumption = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "consumption_variability", nullable = false, precision = 8, scale = 4)
    private BigDecimal consumptionVariability = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "average_purchase_interval", nullable = false, precision = 8, scale = 2)
    private BigDecimal averagePurchaseInterval = BigDecimal.ZERO;

    @Column(name = "last_purchase_date")
    private LocalDate lastPurchaseDate;

    @Column(name = "last_purchase_quantity", precision = 10, scale = 3)
    private BigDecimal lastPurchaseQuantity;

    @Column(name = "estimated_days_remaining")
    private Integer estimatedDaysRemaining;

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(name = "confidence", nullable = false, length = 20)
    private ConfidenceLevel confidence = ConfidenceLevel.LOW;

    @Builder.Default
    @Column(name = "sample_count", nullable = false)
    private Integer sampleCount = 0;

    @Builder.Default
    @Column(name = "last_calculated_at", nullable = false)
    private Instant lastCalculatedAt = Instant.now();
}
