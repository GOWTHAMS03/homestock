package com.homestock.modules.consumption.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReturnSummaryDto {
    private String greeting;
    private String subtitle;
    private int itemsLikelyLowCount;
    private List<PredictionDto> itemsLikelyLow;
    private int itemsExpiringCount;
    private List<String> expiringItemNames;
    private int pendingShoppingCount;
    private int recentFamilyPurchasesCount;
    private boolean hasUpdates;
}
