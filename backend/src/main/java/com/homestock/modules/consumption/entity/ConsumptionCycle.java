package com.homestock.modules.consumption.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.product.entity.Product;
import com.homestock.modules.purchase.entity.Purchase;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "consumption_cycles", indexes = {
        @Index(name = "idx_cycles_home_item", columnList = "home_id, inventory_item_id"),
        @Index(name = "idx_cycles_current_date", columnList = "current_purchase_date")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConsumptionCycle extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "home_id", nullable = false)
    private Home home;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "inventory_item_id", nullable = false)
    private InventoryItem inventoryItem;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id")
    private Product product;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "previous_purchase_id")
    private Purchase previousPurchase;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "current_purchase_id")
    private Purchase currentPurchase;

    @Column(name = "previous_purchase_date", nullable = false)
    private LocalDate previousPurchaseDate;

    @Column(name = "current_purchase_date", nullable = false)
    private LocalDate currentPurchaseDate;

    @Column(name = "quantity", nullable = false, precision = 10, scale = 3)
    private BigDecimal quantity;

    @Column(name = "interval_days", nullable = false)
    private Integer intervalDays;

    @Column(name = "estimated_daily_consumption", nullable = false, precision = 12, scale = 4)
    private BigDecimal estimatedDailyConsumption;

    @Builder.Default
    @Column(name = "is_anomaly", nullable = false)
    private Boolean isAnomaly = false;

    @Column(name = "anomaly_reason", length = 255)
    private String anomalyReason;

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(name = "confidence", nullable = false, length = 20)
    private ConfidenceLevel confidence = ConfidenceLevel.MEDIUM;
}
