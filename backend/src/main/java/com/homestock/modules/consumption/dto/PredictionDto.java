package com.homestock.modules.consumption.dto;

import com.homestock.modules.consumption.entity.ConfidenceLevel;
import com.homestock.modules.consumption.entity.PredictionStatus;
import com.homestock.modules.consumption.entity.QuantitySource;
import com.homestock.modules.consumption.entity.QuantityStatus;
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
public class PredictionDto {
    private UUID itemId;
    private String itemName;
    private String categoryName;
    private BigDecimal currentQuantity;
    private String formattedQuantity;
    private String unit;
    private QuantityStatus quantityStatus;
    private QuantitySource quantitySource;
    private PredictionStatus predictionStatus;
    private Integer estimatedDaysRemaining;
    private String predictionRangeText;
    private ConfidenceLevel confidence;
    private String confidenceText;
    private String suggestedAction; // "ADD_TO_SHOPPING", "CHECK_STOCK", "NONE"
}
