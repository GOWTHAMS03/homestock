package com.homestock.modules.shop.dto.demand;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DemandOpportunityDto {
    private String id;
    private OpportunityType type;
    private String title;
    private String description;
    private String productName;
    private String categoryName;
    private UUID productId;
    private UUID shopOfferId;
    private double priorityScore;
    private String suggestedAction;
    private BigDecimal currentShopPrice;
    private BigDecimal competitorPrice;
    private long localDemandCount;
}
