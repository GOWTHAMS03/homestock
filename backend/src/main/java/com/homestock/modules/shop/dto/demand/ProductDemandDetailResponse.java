package com.homestock.modules.shop.dto.demand;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductDemandDetailResponse {
    private String queryText;
    private UUID canonicalProductId;
    private String categoryName;
    private long totalSignals;
    private double demandScore;
    private DemandTrend trend;
    private Map<String, Long> signalsByType;
    private List<DemandZoneDto> breakdownByZone;
    private boolean inShopCatalog;
    private UUID shopOfferId;
    private String shopStockStatus;
    private BigDecimal shopPrice;
    private BigDecimal minCompetitorPrice;
    private BigDecimal avgCompetitorPrice;
    private DemandOpportunityDto opportunity;
}
