package com.homestock.modules.smartshopping.entity;

import com.homestock.core.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Tracks a smart shopping comparison and checkout decision lifecycle.
 */
@Entity
@Table(name = "shopping_sessions", indexes = {
        @Index(name = "idx_ss_home_user", columnList = "home_id, user_id"),
        @Index(name = "idx_ss_status", columnList = "status"),
        @Index(name = "idx_ss_started_at", columnList = "started_at")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShoppingSession extends BaseEntity {

    @Column(name = "home_id", nullable = false)
    private UUID homeId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Builder.Default
    @Column(name = "started_at", nullable = false)
    private Instant startedAt = Instant.now();

    @Column(name = "completed_at")
    private Instant completedAt;

    @Builder.Default
    @Column(name = "status", nullable = false, length = 30)
    private String status = "CREATED"; // CREATED, COMPLETED, ABANDONED

    @Column(name = "selected_providers", length = 200)
    private String selectedProviders;

    @Column(name = "estimated_total", precision = 12, scale = 2)
    private BigDecimal estimatedTotal;

    @Column(name = "actual_total", precision = 12, scale = 2)
    private BigDecimal actualTotal;

    @Column(name = "potential_savings", precision = 12, scale = 2)
    private BigDecimal potentialSavings;

    @Column(name = "recommended_option", length = 50)
    private String recommendedOption;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;
}
