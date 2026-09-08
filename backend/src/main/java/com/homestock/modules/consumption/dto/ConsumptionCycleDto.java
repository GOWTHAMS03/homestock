package com.homestock.modules.consumption.dto;

import com.homestock.modules.consumption.entity.ConfidenceLevel;
import com.homestock.modules.consumption.entity.ConsumptionCycle;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConsumptionCycleDto {
    private UUID id;
    private UUID inventoryItemId;
    private String itemName;
    private LocalDate previousPurchaseDate;
    private LocalDate currentPurchaseDate;
    private BigDecimal quantity;
    private Integer intervalDays;
    private BigDecimal estimatedDailyConsumption;
    private Boolean isAnomaly;
    private String anomalyReason;
    private ConfidenceLevel confidence;

    public static ConsumptionCycleDto fromEntity(ConsumptionCycle entity) {
        if (entity == null) return null;
        return ConsumptionCycleDto.builder()
                .id(entity.getId())
                .inventoryItemId(entity.getInventoryItem() != null ? entity.getInventoryItem().getId() : null)
                .itemName(entity.getInventoryItem() != null ? entity.getInventoryItem().getName() : null)
                .previousPurchaseDate(entity.getPreviousPurchaseDate())
                .currentPurchaseDate(entity.getCurrentPurchaseDate())
                .quantity(entity.getQuantity())
                .intervalDays(entity.getIntervalDays())
                .estimatedDailyConsumption(entity.getEstimatedDailyConsumption())
                .isAnomaly(entity.getIsAnomaly())
                .anomalyReason(entity.getAnomalyReason())
                .confidence(entity.getConfidence())
                .build();
    }
}
