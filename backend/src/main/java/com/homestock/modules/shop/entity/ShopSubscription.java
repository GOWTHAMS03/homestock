package com.homestock.modules.shop.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.deals.entity.NearbyShop;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;

/**
 * Active subscription linking a shop to a subscription plan.
 */
@Entity
@Table(name = "shop_subscriptions", indexes = {
        @Index(name = "idx_shop_sub_status", columnList = "status"),
        @Index(name = "idx_shop_sub_expires", columnList = "expires_at")
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopSubscription extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shop_id", nullable = false)
    private NearbyShop shop;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "plan_id", nullable = false)
    private SubscriptionPlan plan;

    @Builder.Default
    @Column(name = "status", nullable = false, length = 20)
    private String status = "ACTIVE"; // TRIAL, ACTIVE, PAST_DUE, CANCELLED, EXPIRED

    @Builder.Default
    @Column(name = "started_at", nullable = false)
    private Instant startedAt = Instant.now();

    @Column(name = "expires_at")
    private Instant expiresAt;

    @Column(name = "cancelled_at")
    private Instant cancelledAt;

    @Column(name = "payment_provider", length = 30)
    private String paymentProvider;

    @Column(name = "payment_reference", length = 200)
    private String paymentReference;

    public boolean isActiveSubscription() {
        if (!"ACTIVE".equals(status) && !"TRIAL".equals(status)) return false;
        if (expiresAt != null && Instant.now().isAfter(expiresAt)) return false;
        return true;
    }
}
