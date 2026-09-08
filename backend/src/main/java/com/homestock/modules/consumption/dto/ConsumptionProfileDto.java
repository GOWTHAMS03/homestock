package com.homestock.modules.consumption.dto;

import com.homestock.modules.consumption.entity.ConfidenceLevel;
import com.homestock.modules.consumption.entity.ConsumptionProfile;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConsumptionProfileDto {
    private UUID id;
    private UUID homeId;
    private UUID inventoryItemId;
    private String itemName;
    private String unit;
    private BigDecimal averageDailyConsumption;
    private BigDecimal weightedDailyConsumption;
    private BigDecimal minDailyConsumption;
    private BigDecimal maxDailyConsumption;
    private BigDecimal consumptionVariability;
    private BigDecimal averagePurchaseInterval;
    private LocalDate lastPurchaseDate;
    private BigDecimal lastPurchaseQuantity;
    private Integer estimatedDaysRemaining;
    private ConfidenceLevel confidence;
    private String confidenceExplanation;
    private Integer sampleCount;
    private String typicalRangeText;
    private Instant lastCalculatedAt;

    public static ConsumptionProfileDto fromEntity(ConsumptionProfile entity, String explanation, String typicalRangeText) {
        if (entity == null) return null;
        return ConsumptionProfileDto.builder()
                .id(entity.getId())
                .homeId(entity.getHome() != null ? entity.getHome().getId() : null)
                .inventoryItemId(entity.getInventoryItem() != null ? entity.getInventoryItem().getId() : null)
                .itemName(entity.getInventoryItem() != null ? entity.getInventoryItem().getName() : null)
                .unit(entity.getInventoryItem() != null ? entity.getInventoryItem().getUnit() : "pcs")
                .averageDailyConsumption(entity.getAverageDailyConsumption())
                .weightedDailyConsumption(entity.getWeightedDailyConsumption())
                .minDailyConsumption(entity.getMinDailyConsumption())
                .maxDailyConsumption(entity.getMaxDailyConsumption())
                .consumptionVariability(entity.getConsumptionVariability())
                .averagePurchaseInterval(entity.getAveragePurchaseInterval())
                .lastPurchaseDate(entity.getLastPurchaseDate())
                .lastPurchaseQuantity(entity.getLastPurchaseQuantity())
                .estimatedDaysRemaining(entity.getEstimatedDaysRemaining())
                .confidence(entity.getConfidence())
                .confidenceExplanation(explanation)
                .sampleCount(entity.getSampleCount())
                .typicalRangeText(typicalRangeText)
                .lastCalculatedAt(entity.getLastCalculatedAt())
                .build();
    }
}
