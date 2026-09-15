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
public class ProductDemandItemDto {
    private String productName;
    private String categoryName;
    private UUID canonicalProductId;
    private UUID shopOfferId;
    private long totalSignals;
    private double demandScore;
    private DemandTrend trend;
    private Double percentageGrowth;
    private boolean inShopCatalog;
    private String shopStockStatus;
    private BigDecimal shopPrice;
    private BigDecimal minCompetitorPrice;
    private BigDecimal avgCompetitorPrice;
    private boolean lowDataWarning;
    private String topZone;
}
