package com.homestock.modules.inventory.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.category.entity.Category;
import com.homestock.modules.home.entity.Home;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

@Entity
@Table(name = "inventory_items")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InventoryItem extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "home_id", nullable = false)
    private Home home;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Category category;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id")
    private com.homestock.modules.product.entity.Product product;

    @Column(name = "barcode", length = 50)
    private String barcode;

    @Column(name = "name", nullable = false, length = 150)
    private String name;

    @Column(name = "brand", length = 100)
    private String brand;

    @Builder.Default
    @Column(name = "quantity", nullable = false, precision = 12, scale = 3)
    private BigDecimal quantity = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "unit", nullable = false, length = 20)
    private String unit = "pcs";

    @Builder.Default
    @Column(name = "minimum_quantity", nullable = false, precision = 12, scale = 3)
    private BigDecimal minimumQuantity = BigDecimal.ONE;

    @Column(name = "maximum_quantity", precision = 12, scale = 3)
    private BigDecimal maximumQuantity;

    @Column(name = "storage_location", length = 80)
    private String storageLocation;

    @Column(name = "purchase_price", precision = 10, scale = 2)
    private BigDecimal purchasePrice;

    @Column(name = "purchase_date")
    private LocalDate purchaseDate;

    @Column(name = "expiry_date")
    private LocalDate expiryDate;

    @Column(name = "image_url", length = 512)
    private String imageUrl;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @Builder.Default
    @Column(name = "is_archived", nullable = false)
    private Boolean isArchived = false;

    @Enumerated(EnumType.STRING)
    @Column(name = "quantity_status", length = 30)
    private com.homestock.modules.consumption.entity.QuantityStatus quantityStatus;

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(name = "quantity_source", length = 20)
    private com.homestock.modules.consumption.entity.QuantitySource quantitySource = com.homestock.modules.consumption.entity.QuantitySource.VERIFIED;

    @Column(name = "last_verified_at")
    private java.time.Instant lastVerifiedAt;

    @Column(name = "last_estimated_at")
    private java.time.Instant lastEstimatedAt;

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(name = "confidence", length = 20)
    private com.homestock.modules.consumption.entity.ConfidenceLevel confidence = com.homestock.modules.consumption.entity.ConfidenceLevel.HIGH;

    public StockStatus calculateStockStatus() {
        if (quantity.compareTo(BigDecimal.ZERO) == 0) {
            return StockStatus.OUT_OF_STOCK;
        } else if (quantity.compareTo(minimumQuantity) <= 0) {
            return StockStatus.LOW_STOCK;
        } else {
            return StockStatus.IN_STOCK;
        }
    }

    public ExpiryStatus calculateExpiryStatus() {
        if (expiryDate == null) {
            return ExpiryStatus.SAFE;
        }
        LocalDate today = LocalDate.now();
        if (expiryDate.isBefore(today)) {
            return ExpiryStatus.EXPIRED;
        }
        long daysUntil = ChronoUnit.DAYS.between(today, expiryDate);
        if (daysUntil <= 7) {
            return ExpiryStatus.EXPIRING_SOON;
        }
        return ExpiryStatus.SAFE;
    }

    public Long getDaysUntilExpiry() {
        if (expiryDate == null) return null;
        return ChronoUnit.DAYS.between(LocalDate.now(), expiryDate);
    }
}
