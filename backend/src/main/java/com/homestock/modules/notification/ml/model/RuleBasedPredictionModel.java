package com.homestock.modules.notification.ml.model;

import com.homestock.modules.notification.dto.MLFeatureVectorDto;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * RuleBasedPredictionModel:
 * Cold-start fallback predictor when fewer than 5 historical consumption points exist.
 * Uses category consumption baselines and stock thresholds to ensure the system
 * remains 100% reliable on Day 1.
 */
@Component
public class RuleBasedPredictionModel implements PredictionModel {

    @Override
    public String getModelName() {
        return "RULE_BASED";
    }

    @Override
    public boolean canHandle(MLFeatureVectorDto features) {
        // Fallback model can handle any feature vector
        return true;
    }

    @Override
    public StockPredictionResult predict(MLFeatureVectorDto features) {
        BigDecimal currentStock = features.getCurrentStock() != null ? features.getCurrentStock() : BigDecimal.ZERO;
        BigDecimal dailyRate = features.getAverageConsumptionPerDay();

        if (dailyRate == null || dailyRate.compareTo(BigDecimal.ZERO) <= 0) {
            dailyRate = estimateBaselineDailyRate(features.getItemName(), features.getUnit());
        }

        BigDecimal daysUntilEmpty;
        if (currentStock.compareTo(BigDecimal.ZERO) <= 0) {
            daysUntilEmpty = BigDecimal.ZERO;
        } else if (dailyRate.compareTo(BigDecimal.ZERO) > 0) {
            daysUntilEmpty = currentStock.divide(dailyRate, 1, RoundingMode.HALF_UP);
        } else {
            daysUntilEmpty = new BigDecimal("30.0");
        }

        double days = daysUntilEmpty.doubleValue();
        double prob1d;
        double prob3d;
        double prob7d;

        if (days <= 0.5) {
            prob1d = 0.98;
            prob3d = 0.99;
            prob7d = 1.00;
        } else if (days <= 1.5) {
            prob1d = 0.85;
            prob3d = 0.96;
            prob7d = 0.99;
        } else if (days <= 3.5) {
            prob1d = 0.30;
            prob3d = 0.82;
            prob7d = 0.95;
        } else if (days <= 7.0) {
            prob1d = 0.08;
            prob3d = 0.35;
            prob7d = 0.80;
        } else {
            prob1d = 0.01;
            prob3d = 0.05;
            prob7d = Math.max(0.05, Math.min(0.50, 7.0 / days));
        }

        String explanation = String.format(
                "Estimated ~%.1f days remaining based on current stock (%.2f %s) and category usage velocity (%.2f %s/day).",
                days, currentStock.doubleValue(), features.getUnit() != null ? features.getUnit() : "units",
                dailyRate.doubleValue(), features.getUnit() != null ? features.getUnit() : "units"
        );

        return StockPredictionResult.builder()
                .daysUntilEmpty(daysUntilEmpty)
                .probabilityWithin1Day(prob1d)
                .probabilityWithin3Days(prob3d)
                .probabilityWithin7Days(prob7d)
                .confidence("LOW")
                .modelUsed(getModelName())
                .explanation(explanation)
                .build();
    }

    private BigDecimal estimateBaselineDailyRate(String name, String unit) {
        String lower = name != null ? name.toLowerCase() : "";
        if (lower.contains("oil") || lower.contains("ghee")) {
            return new BigDecimal("0.08"); // ~2.4L/month
        } else if (lower.contains("rice")) {
            return new BigDecimal("0.16"); // ~5kg/month
        } else if (lower.contains("atta") || lower.contains("flour")) {
            return new BigDecimal("0.16"); // ~5kg/month
        } else if (lower.contains("dal") || lower.contains("lentil")) {
            return new BigDecimal("0.08"); // ~2.5kg/month
        } else if (lower.contains("milk")) {
            return new BigDecimal("0.50"); // 500ml/day
        } else if (lower.contains("sugar") || lower.contains("salt")) {
            return new BigDecimal("0.04"); // ~1.2kg/month
        } else if (lower.contains("soap") || lower.contains("paste") || lower.contains("brush")) {
            return new BigDecimal("0.03"); // ~1 per month
        }

        // Generic default based on unit
        if ("l".equalsIgnoreCase(unit) || "kg".equalsIgnoreCase(unit)) {
            return new BigDecimal("0.10");
        }
        return new BigDecimal("0.05");
    }
}
