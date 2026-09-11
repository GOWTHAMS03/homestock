package com.homestock.modules.notification.ml.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StockPredictionResult {

    private BigDecimal daysUntilEmpty;
    private double probabilityWithin1Day;
    private double probabilityWithin3Days;
    private double probabilityWithin7Days;
    private String confidence; // LOW, MEDIUM, HIGH
    private String modelUsed;  // RULE_BASED, STATISTICAL_ML
    private String explanation;
}
