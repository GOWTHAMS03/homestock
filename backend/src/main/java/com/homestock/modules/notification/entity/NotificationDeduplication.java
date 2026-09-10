package com.homestock.modules.notification.entity;

import com.homestock.core.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "notification_deduplications", indexes = {
    @Index(name = "idx_notif_dedup_key", columnList = "dedup_key", unique = true),
    @Index(name = "idx_notif_dedup_home", columnList = "home_id")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationDeduplication extends BaseEntity {

    @Column(name = "dedup_key", nullable = false, length = 255, unique = true)
    private String dedupKey;

    @Column(name = "home_id", nullable = false)
    private UUID homeId;

    @Column(name = "last_sent_at", nullable = false)
    private Instant lastSentAt;

    @Column(name = "last_quantity", precision = 12, scale = 3)
    private BigDecimal lastQuantity;

    @Column(name = "last_status", length = 50)
    private String lastStatus;
}

