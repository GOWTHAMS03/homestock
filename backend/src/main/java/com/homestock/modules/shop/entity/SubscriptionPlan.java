package com.homestock.modules.shop.entity;

import com.homestock.core.common.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

/**
 * Subscription plan definition for Shop Owner tiers.
 */
@Entity
@Table(name = "subscription_plans")
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SubscriptionPlan extends BaseEntity {

    @Column(name = "name", nullable = false, unique = true, length = 30)
    private String name; // FREE, STARTER, BUSINESS, PREMIUM

    @Column(name = "display_name", nullable = false, length = 60)
    private String displayName;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Builder.Default
    @Column(name = "max_products", nullable = false)
    private Integer maxProducts = 50;

    @Builder.Default
    @Column(name = "analytics_enabled", nullable = false)
    private Boolean analyticsEnabled = false;

    @Builder.Default
    @Column(name = "featured_enabled", nullable = false)
    private Boolean featuredEnabled = false;

    @Builder.Default
    @Column(name = "price_monthly", precision = 10, scale = 2, nullable = false)
    private BigDecimal priceMonthly = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "price_yearly", precision = 10, scale = 2, nullable = false)
    private BigDecimal priceYearly = BigDecimal.ZERO;

    @Builder.Default
    @Column(name = "currency", nullable = false, length = 3)
    private String currency = "INR";

    @Builder.Default
    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Builder.Default
    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder = 0;
}
