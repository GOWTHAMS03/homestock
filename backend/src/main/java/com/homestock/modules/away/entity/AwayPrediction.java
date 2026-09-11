package com.homestock.modules.away.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.inventory.entity.InventoryItem;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "away_predictions", indexes = {
        @Index(name = "idx_away_pred_summary", columnList = "summary_id"),
        @Index(name = "idx_away_pred_item", columnList = "inventory_item_id")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AwayPrediction extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "summary_id", nullable = false)
    private AwayPeriodSummary summary;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "inventory_item_id", nullable = false)
    private InventoryItem inventoryItem;

    @Column(name = "item_name", nullable = false, length = 150)
    private String itemName;

    @Enumerated(EnumType.STRING)
    @Column(name = "prediction_type", nullable = false, length = 40)
    private AwayPredictionType predictionType;

    @Enumerated(EnumType.STRING)
    @Column(name = "event_classification", nullable = false, length = 30)
    @Builder.Default
    private PredictionEventClassification eventClassification = PredictionEventClassification.PREDICTED_EVENT;

    @Column(name = "stock_before_away", precision = 12, scale = 3)
    private BigDecimal stockBeforeAway;

    @Column(name = "estimated_quantity", nullable = false, precision = 12, scale = 3)
    private BigDecimal estimatedQuantity;

    @Column(name = "estimated_consumed", nullable = false, precision = 12, scale = 3)
    private BigDecimal estimatedConsumed;

    @Column(name = "unit", nullable = false, length = 20)
    private String unit;

    @Column(name = "confidence", nullable = false, precision = 5, scale = 4)
    private BigDecimal confidence;

    @Column(name = "reason", nullable = false, length = 255)
    private String reason;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 30)
    @Builder.Default
    private PredictionStatus status = PredictionStatus.PENDING;

    @Builder.Default
    @Column(name = "is_top_priority", nullable = false)
    private Boolean isTopPriority = false;
}
