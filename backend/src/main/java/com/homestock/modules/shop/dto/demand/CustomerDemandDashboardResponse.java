package com.homestock.modules.shop.dto.demand;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerDemandDashboardResponse {
    private UUID shopId;
    private String shopName;
    private String period;
    private double radiusKm;
    private long totalDemandSignals;
    private long uniqueSearchQueries;
    private long missingProductsCount;
    private long restockOpportunitiesCount;
    private long priceOpportunitiesCount;
    private List<ProductDemandItemDto> topDemandedProducts;
    private List<DemandOpportunityDto> opportunities;
    private List<DemandZoneDto> demandZones;
    private boolean isGated;
    private String subscriptionTier;
    private String summaryInsight;
}
