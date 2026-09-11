package com.homestock.modules.notification.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.product.entity.Product;
import com.homestock.modules.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "notification_events", indexes = {
        @Index(name = "idx_notif_events_user", columnList = "user_id, occurred_at DESC"),
        @Index(name = "idx_notif_events_home", columnList = "home_id, occurred_at DESC"),
        @Index(name = "idx_notif_events_type", columnList = "notification_type"),
        @Index(name = "idx_notif_events_event_type", columnList = "event_type"),
        @Index(name = "idx_notif_events_item", columnList = "inventory_item_id"),
        @Index(name = "idx_notif_events_dedup", columnList = "dedup_key")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationEvent extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "notification_id")
    private Notification notification;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "home_id", nullable = false)
    private Home home;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "inventory_item_id")
    private InventoryItem inventoryItem;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id")
    private Product product;

    @Enumerated(EnumType.STRING)
    @Column(name = "notification_type", nullable = false, length = 50)
    private NotificationType notificationType;

    @Enumerated(EnumType.STRING)
    @Column(name = "priority", nullable = false, length = 20)
    private NotificationPriority priority;

    @Enumerated(EnumType.STRING)
    @Column(name = "channel", nullable = false, length = 20)
    @Builder.Default
    private NotificationChannel channel = NotificationChannel.IN_APP;

    @Enumerated(EnumType.STRING)
    @Column(name = "decision", nullable = false, length = 30)
    private NotificationDecisionType decision;

    @Enumerated(EnumType.STRING)
    @Column(name = "event_type", nullable = false, length = 30)
    private NotificationEventType eventType;

    @Enumerated(EnumType.STRING)
    @Column(name = "action_type", length = 40)
    private NotificationUserAction actionType;

    @Builder.Default
    @Column(name = "urgency_score", nullable = false, precision = 5, scale = 4)
    private BigDecimal urgencyScore = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "relevance_score", nullable = false, precision = 5, scale = 4)
    private BigDecimal relevanceScore = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "confidence_score", nullable = false, precision = 5, scale = 4)
    private BigDecimal confidenceScore = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "action_probability", nullable = false, precision = 5, scale = 4)
    private BigDecimal actionProbability = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "fatigue_score", nullable = false, precision = 5, scale = 4)
    private BigDecimal fatigueScore = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "final_score", nullable = false, precision = 5, scale = 4)
    private BigDecimal finalScore = BigDecimal.ZERO;

    @Column(name = "predicted_days_remaining", precision = 6, scale = 2)
    private BigDecimal predictedDaysRemaining;

    @Column(name = "dedup_key", length = 255)
    private String dedupKey;

    @Column(name = "scheduled_for")
    private Instant scheduledFor;

    @Builder.Default
    @Column(name = "occurred_at", nullable = false)
    private Instant occurredAt = Instant.now();
}
