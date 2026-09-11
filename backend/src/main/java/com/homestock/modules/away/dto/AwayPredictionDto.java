package com.homestock.modules.away.dto;

import com.homestock.modules.away.entity.AwayPredictionType;
import com.homestock.modules.away.entity.PredictionEventClassification;
import com.homestock.modules.away.entity.PredictionStatus;
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
public class AwayPredictionDto {

    private UUID id;
    private UUID inventoryItemId;
    private String itemName;
    private AwayPredictionType type;
    private PredictionEventClassification eventClassification;
    private BigDecimal stockBeforeAway;
    private BigDecimal estimatedQuantity;
    private BigDecimal estimatedConsumed;
    private String unit;
    private Double confidence;
    private String confidenceLabel;
    private Boolean isPrediction;
    private String reason;
    private String displayTitle;
    private String displaySubtitle;
    private String actionLabel;
    private PredictionStatus status;
    private Boolean isTopPriority;
}
