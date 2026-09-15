package com.homestock.modules.shop.dto;

import com.homestock.modules.shop.entity.SubscriptionPlan;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SubscriptionPlanResponse {

    private UUID id;
    private String name;
    private String displayName;
    private String description;
    private Integer maxProducts;
    private Boolean analyticsEnabled;
    private Boolean featuredEnabled;
    private BigDecimal priceMonthly;
    private BigDecimal priceYearly;
    private String currency;
    private Integer sortOrder;

    public static SubscriptionPlanResponse fromEntity(SubscriptionPlan plan) {
        if (plan == null) return null;
        return SubscriptionPlanResponse.builder()
                .id(plan.getId())
                .name(plan.getName())
                .displayName(plan.getDisplayName())
                .description(plan.getDescription())
                .maxProducts(plan.getMaxProducts())
                .analyticsEnabled(plan.getAnalyticsEnabled())
                .featuredEnabled(plan.getFeaturedEnabled())
                .priceMonthly(plan.getPriceMonthly())
                .priceYearly(plan.getPriceYearly())
                .currency(plan.getCurrency())
                .sortOrder(plan.getSortOrder())
                .build();
    }
}
