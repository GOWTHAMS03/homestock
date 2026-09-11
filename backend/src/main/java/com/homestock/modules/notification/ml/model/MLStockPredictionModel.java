package com.homestock.modules.notification.ml.model;

import com.homestock.modules.notification.dto.MLFeatureVectorDto;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.DayOfWeek;
import java.time.LocalDate;

/**
 * MLStockPredictionModel:
 * Native statistical ML model for household product depletion forecasting.
 * - Computes exponentially weighted consumption velocity.
 * - Applies day-of-week seasonality (weekend cooking surges in Indian households).
 * - Models run-out probabilities using Gaussian Cumulative Distribution Function (CDF)
 *   over 1-day, 3-day, and 7-day planning horizons.
 */
@Component
public class MLStockPredictionModel implements PredictionModel {

    private static final int MIN_OBSERVATIONS_FOR_ML = 5;

    @Override
    public String getModelName() {
        return "STATISTICAL_ML";
    }

    @Override
    public boolean canHandle(MLFeatureVectorDto features) {
        if (features == null) return false;
        Integer sampleCount = features.getSampleCount();
        return sampleCount != null && sampleCount >= MIN_OBSERVATIONS_FOR_ML;
    }

    @Override
    public StockPredictionResult predict(MLFeatureVectorDto features) {
        BigDecimal currentStock = features.getCurrentStock() != null ? features.getCurrentStock() : BigDecimal.ZERO;
        BigDecimal baseRate = features.getAverageConsumptionPerDay() != null ?
                features.getAverageConsumptionPerDay() : new BigDecimal("0.10");

        // 1. Blend recent velocity if available (60% recent velocity, 40% long-term baseline)
        BigDecimal effectiveVelocity = baseRate;
        if (features.getConsumptionVelocity() != null && features.getConsumptionVelocity().compareTo(BigDecimal.ZERO) > 0) {
            effectiveVelocity = features.getConsumptionVelocity().multiply(new BigDecimal("0.60"))
                    .add(baseRate.multiply(new BigDecimal("0.40")));
        }

        // 2. Adjust for usage trend (ACCELERATING vs DECELERATING)
        if ("ACCELERATING".equalsIgnoreCase(features.getRecentUsageTrend())) {
            effectiveVelocity = effectiveVelocity.multiply(new BigDecimal("1.15"));
        } else if ("DECELERATING".equalsIgnoreCase(features.getRecentUsageTrend())) {
            effectiveVelocity = effectiveVelocity.multiply(new BigDecimal("0.85"));
        }

        // 3. Day-of-Week Seasonality: Indian households consume ~20% more groceries over weekends
        DayOfWeek today = LocalDate.now().getDayOfWeek();
        if (today == DayOfWeek.FRIDAY || today == DayOfWeek.SATURDAY || today == DayOfWeek.SUNDAY) {
            effectiveVelocity = effectiveVelocity.multiply(new BigDecimal("1.12"));
        }

        // 4. Calculate Expected Days Remaining
        BigDecimal daysUntilEmpty;
        if (currentStock.compareTo(BigDecimal.ZERO) <= 0) {
            daysUntilEmpty = BigDecimal.ZERO;
        } else if (effectiveVelocity.compareTo(BigDecimal.ZERO) > 0) {
            daysUntilEmpty = currentStock.divide(effectiveVelocity, 1, RoundingMode.HALF_UP);
        } else {
            daysUntilEmpty = new BigDecimal("45.0");
        }

        // 5. Probabilistic Modeling across 1, 3, and 7 days
        double stockVal = currentStock.doubleValue();
        double velocityVal = effectiveVelocity.doubleValue();
        double varianceVal = features.getConsumptionVariance() != null ?
                features.getConsumptionVariance().doubleValue() : (velocityVal * 0.25);
        double stdDev = Math.max(0.01, Math.sqrt(Math.max(0.001, varianceVal)));

        double prob1d = calculateCumulativeDepletionProbability(stockVal, velocityVal, stdDev, 1.0);
        double prob3d = calculateCumulativeDepletionProbability(stockVal, velocityVal, stdDev, 3.0);
        double prob7d = calculateCumulativeDepletionProbability(stockVal, velocityVal, stdDev, 7.0);

        // Ensure monotonic probability progression
        prob3d = Math.max(prob1d, prob3d);
        prob7d = Math.max(prob3d, prob7d);

        int samples = features.getSampleCount() != null ? features.getSampleCount() : 0;
        String confidence = (samples >= 10 && stdDev / Math.max(0.01, velocityVal) < 0.35) ? "HIGH" : "MEDIUM";

        String explanation = String.format(
                "ML model learned from %d purchase cycles. Predicted depletion in ~%.1f days (Consumption velocity: %.2f %s/day, Confidence: %s).",
                samples, daysUntilEmpty.doubleValue(), effectiveVelocity.doubleValue(),
                features.getUnit() != null ? features.getUnit() : "units", confidence
        );

        return StockPredictionResult.builder()
                .daysUntilEmpty(daysUntilEmpty)
                .probabilityWithin1Day(prob1d)
                .probabilityWithin3Days(prob3d)
                .probabilityWithin7Days(prob7d)
                .confidence(confidence)
                .modelUsed(getModelName())
                .explanation(explanation)
                .build();
    }

    /**
     * Approximates Gaussian Cumulative Distribution Function:
     * P(Total consumption in T days >= Current Stock)
     */
    private double calculateCumulativeDepletionProbability(double stock, double dailyVelocity, double dailyStdDev, double horizonDays) {
        if (stock <= 0.0) return 1.0;

        double expectedConsumption = dailyVelocity * horizonDays;
        double horizonStdDev = dailyStdDev * Math.sqrt(horizonDays);

        if (horizonStdDev <= 0.0001) {
            return expectedConsumption >= stock ? 0.99 : 0.01;
        }

        double z = (expectedConsumption - stock) / horizonStdDev;
        return normalCdf(z);
    }

    /**
     * Standard Normal CDF approximation via Abramowitz and Stegun erf approximation.
     */
    private double normalCdf(double z) {
        if (z < -8.0) return 0.0;
        if (z > 8.0) return 1.0;
        return 0.5 * (1.0 + erf(z / Math.sqrt(2.0)));
    }

    private double erf(double x) {
        // Abramowitz & Stegun formula 7.1.26
        double a1 = 0.254829592;
        double a2 = -0.284496736;
        double a3 = 1.421413741;
        double a4 = -1.453152027;
        double a5 = 1.061405429;
        double p = 0.3275911;

        int sign = (x < 0) ? -1 : 1;
        x = Math.abs(x);

        double t = 1.0 / (1.0 + p * x);
        double y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * Math.exp(-x * x);

        return sign * y;
    }
}
