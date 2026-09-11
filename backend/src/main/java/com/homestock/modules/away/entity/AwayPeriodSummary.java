package com.homestock.modules.away.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "away_period_summaries", indexes = {
        @Index(name = "idx_away_summary_home_user", columnList = "home_id, user_id, is_reviewed"),
        @Index(name = "idx_away_summary_created", columnList = "created_at DESC")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AwayPeriodSummary extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "home_id", nullable = false)
    private Home home;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "away_days", nullable = false)
    private Integer awayDays;

    @Column(name = "from_date", nullable = false)
    private Instant fromDate;

    @Column(name = "to_date", nullable = false)
    private Instant toDate;

    @Builder.Default
    @Column(name = "important_changes", nullable = false)
    private Integer importantChanges = 0;

    @Builder.Default
    @Column(name = "predicted_low_stock", nullable = false)
    private Integer predictedLowStock = 0;

    @Builder.Default
    @Column(name = "predicted_finished", nullable = false)
    private Integer predictedFinished = 0;

    @Builder.Default
    @Column(name = "expiry_risks", nullable = false)
    private Integer expiryRisks = 0;

    @Builder.Default
    @Column(name = "is_reviewed", nullable = false)
    private Boolean isReviewed = false;

    @Builder.Default
    @OneToMany(mappedBy = "summary", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<AwayPrediction> predictions = new ArrayList<>();
}
