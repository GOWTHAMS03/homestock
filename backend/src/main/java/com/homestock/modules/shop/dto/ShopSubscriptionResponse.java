package com.homestock.modules.shop.dto;

import com.homestock.modules.shop.entity.ShopSubscription;
import lombok.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShopSubscriptionResponse {

    private UUID subscriptionId;
    private UUID shopId;
    private String planName;
    private String planDisplayName;
    private String description;
    private Integer maxProducts;
    private Boolean analyticsEnabled;
    private Boolean featuredEnabled;
    private BigDecimal priceMonthly;
    private String currency;
    private String status;
    private Instant startedAt;
    private Instant expiresAt;
    private long currentProductCount;
    private boolean canAddMoreProducts;

    public static ShopSubscriptionResponse fromEntity(ShopSubscription sub, long currentProductCount) {
        if (sub == null) return null;
        var plan = sub.getPlan();
        int max = plan != null ? plan.getMaxProducts() : 50;
        return ShopSubscriptionResponse.builder()
                .subscriptionId(sub.getId())
                .shopId(sub.getShop() != null ? sub.getShop().getId() : null)
                .planName(plan != null ? plan.getName() : "FREE")
                .planDisplayName(plan != null ? plan.getDisplayName() : "Free Plan")
                .description(plan != null ? plan.getDescription() : null)
                .maxProducts(max)
                .analyticsEnabled(plan != null && Boolean.TRUE.equals(plan.getAnalyticsEnabled()))
                .featuredEnabled(plan != null && Boolean.TRUE.equals(plan.getFeaturedEnabled()))
                .priceMonthly(plan != null ? plan.getPriceMonthly() : BigDecimal.ZERO)
                .currency(plan != null ? plan.getCurrency() : "INR")
                .status(sub.getStatus())
                .startedAt(sub.getStartedAt())
                .expiresAt(sub.getExpiresAt())
                .currentProductCount(currentProductCount)
                .canAddMoreProducts(currentProductCount < max)
                .build();
    }
}
