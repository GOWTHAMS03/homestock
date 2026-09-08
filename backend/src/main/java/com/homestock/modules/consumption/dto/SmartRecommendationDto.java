package com.homestock.modules.consumption.dto;

import com.homestock.modules.consumption.entity.ConfidenceLevel;
import com.homestock.modules.consumption.entity.RecommendationUrgency;
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
public class SmartRecommendationDto {
    private UUID itemId;
    private String name;
    private String categoryName;
    private BigDecimal currentQuantity;
    private String formattedCurrentQuantity;
    private BigDecimal recommendedQuantity;
    private String unit;
    private RecommendationUrgency urgency;
    private String rationale;
    private ConfidenceLevel confidence;
}
