package com.homestock.modules.consumption.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HomeMemoryInsightDto {
    private UUID homeId;
    private String primaryInsight;
    private List<String> bulletInsights;
    private BigDecimal weeklySpent;
    private Integer weeklyPurchasesCount;
    private Integer itemsSavedFromDuplicate;
    private String topCategory;
    private String mostFrequentStaple;
}
