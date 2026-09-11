package com.homestock.modules.notification.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.home.entity.Home;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(name = "notification_digests", indexes = {
        @Index(name = "idx_notif_digests_home", columnList = "home_id, created_at DESC")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationDigest extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "home_id", nullable = false)
    private Home home;

    @Column(name = "title", nullable = false, length = 150)
    private String title;

    @Column(name = "summary_text", nullable = false, columnDefinition = "TEXT")
    private String summaryText;

    @Builder.Default
    @Column(name = "item_count", nullable = false)
    private Integer itemCount = 0;

    @Builder.Default
    @Column(name = "estimated_total_cost", precision = 12, scale = 2)
    private BigDecimal estimatedTotalCost = BigDecimal.ZERO;

    @Column(name = "item_ids_json", columnDefinition = "TEXT")
    private String itemIdsJson;

    @Column(name = "item_names_json", columnDefinition = "TEXT")
    private String itemNamesJson;

    @Builder.Default
    @Column(name = "status", nullable = false, length = 30)
    private String status = "ACTIVE";
}
