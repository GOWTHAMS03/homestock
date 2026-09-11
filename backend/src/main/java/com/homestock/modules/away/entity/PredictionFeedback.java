package com.homestock.modules.away.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "prediction_feedback", indexes = {
        @Index(name = "idx_pred_feedback_item", columnList = "inventory_item_id, created_at DESC"),
        @Index(name = "idx_pred_feedback_home", columnList = "home_id")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PredictionFeedback extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "prediction_id")
    private AwayPrediction prediction;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "inventory_item_id", nullable = false)
    private InventoryItem inventoryItem;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "home_id", nullable = false)
    private Home home;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "feedback_type", nullable = false, length = 30)
    private FeedbackSignalType feedbackType;

    @Column(name = "predicted_quantity", nullable = false, precision = 12, scale = 3)
    private BigDecimal predictedQuantity;

    @Column(name = "actual_quantity", precision = 12, scale = 3)
    private BigDecimal actualQuantity;

    @Column(name = "error_delta", precision = 12, scale = 3)
    private BigDecimal errorDelta;

    @Builder.Default
    @Column(name = "learning_adjustment_factor", nullable = false, precision = 8, scale = 4)
    private BigDecimal learningAdjustmentFactor = BigDecimal.ONE;
}
