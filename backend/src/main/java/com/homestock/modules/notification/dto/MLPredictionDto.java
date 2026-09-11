package com.homestock.modules.notification.dto;

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
public class MLPredictionDto {

    private UUID itemId;
    private String itemName;
    private BigDecimal currentQuantity;
    private String unit;
    private BigDecimal predictedDaysRemaining;
    private Double probabilityWithin1Day;
    private Double probabilityWithin3Days;
    private Double probabilityWithin7Days;
    private String confidence; // LOW, MEDIUM, HIGH
    private String modelName;
    private String recommendedAction;
    private boolean urgent;
}
