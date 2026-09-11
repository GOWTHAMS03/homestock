package com.homestock.modules.away.ml;

import lombok.Builder;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

/**
 * Native Java statistical machine learning model for estimating household consumption
 * during periods of app inactivity.
 *
 * Implements:
 * - Weighted daily consumption velocity
 * - Day-of-week seasonality (weekday vs weekend consumption patterns)
 * - Historical feedback calibration adjustment
 * - Cold-start fallback handling
 */
@Slf4j
@Component
public class StatisticalAwayPredictor {

    private static final BigDecimal WEEKEND_MULTIPLIER = new BigDecimal("1.25");
    private static final BigDecimal DEFAULT_FEEDBACK_SCALE = BigDecimal.ONE;

    @Data
    @Builder
    public static class AwayPredictionInput {
        private String itemName;
        private BigDecimal currentStockBeforeAway;
        private BigDecimal baselineDailyConsumption;
        private BigDecimal consumptionVariability;
        private Integer sampleCount;
        private LocalDate awayStartDate;
        private LocalDate awayEndDate;
        private BigDecimal feedbackCalibrationFactor; // learned from previous user corrections
    }

    @Data
    @Builder
    public static class AwayPredictionResult {
        private BigDecimal estimatedConsumption;
        private BigDecimal estimatedRemainingStock;
        private Double confidence;
        private String confidenceLabel;
        private String rationale;
        private boolean isColdStart;
    }

    public AwayPredictionResult predict(AwayPredictionInput input) {
        if (input == null || input.getAwayStartDate() == null || input.getAwayEndDate() == null) {
            return AwayPredictionResult.builder()
                    .estimatedConsumption(BigDecimal.ZERO)
                    .estimatedRemainingStock(BigDecimal.ZERO)
                    .confidence(0.10)
                    .confidenceLabel("10% confidence")
                    .rationale("Insufficient date parameters for prediction.")
                    .isColdStart(true)
                    .build();
        }

        long awayDays = ChronoUnit.DAYS.between(input.getAwayStartDate(), input.getAwayEndDate());
        if (awayDays <= 0) {
            awayDays = 1;
        }

        BigDecimal stockBefore = input.getCurrentStockBeforeAway() != null ? input.getCurrentStockBeforeAway() : BigDecimal.ZERO;
        BigDecimal baseVelocity = input.getBaselineDailyConsumption() != null ? input.getBaselineDailyConsumption() : BigDecimal.ZERO;
        int samples = input.getSampleCount() != null ? input.getSampleCount() : 0;

        // 1. Cold-start detection (< 3 samples or negligible velocity)
        if (samples < 3 || baseVelocity.compareTo(BigDecimal.ZERO) <= 0) {
            return AwayPredictionResult.builder()
                    .estimatedConsumption(BigDecimal.ZERO)
                    .estimatedRemainingStock(stockBefore)
                    .confidence(0.20)
                    .confidenceLabel("20% confidence")
                    .rationale("Still learning your household's usage pattern.")
                    .isColdStart(true)
                    .build();
        }

        // 2. Seasonality & Day-of-Week Adjustment
        // Count weekdays vs weekend days during the away period
        int weekdayCount = 0;
        int weekendCount = 0;
        LocalDate current = input.getAwayStartDate();
        while (!current.isAfter(input.getAwayEndDate())) {
            DayOfWeek dow = current.getDayOfWeek();
            if (dow == DayOfWeek.SATURDAY || dow == DayOfWeek.SUNDAY) {
                weekendCount++;
            } else {
                weekdayCount++;
            }
            current = current.plusDays(1);
        }

        // Total effective days weighted by weekend multiplier
        BigDecimal effectiveDays = BigDecimal.valueOf(weekdayCount)
                .add(BigDecimal.valueOf(weekendCount).multiply(WEEKEND_MULTIPLIER));

        // 3. User Feedback Calibration Multiplier
        BigDecimal calibrationFactor = (input.getFeedbackCalibrationFactor() != null &&
                input.getFeedbackCalibrationFactor().compareTo(BigDecimal.ZERO) > 0)
                ? input.getFeedbackCalibrationFactor()
                : DEFAULT_FEEDBACK_SCALE;

        // 4. Calculate Predicted Consumption
        BigDecimal adjustedVelocity = baseVelocity.multiply(calibrationFactor);
        BigDecimal predictedConsumption = adjustedVelocity.multiply(effectiveDays)
                .setScale(3, RoundingMode.HALF_UP);

        // 5. Estimated Remaining Stock (clamped to 0)
        BigDecimal estimatedRemaining = stockBefore.subtract(predictedConsumption);
        if (estimatedRemaining.compareTo(BigDecimal.ZERO) < 0) {
            estimatedRemaining = BigDecimal.ZERO;
        }
        estimatedRemaining = estimatedRemaining.setScale(3, RoundingMode.HALF_UP);

        // 6. Confidence Score Calculation
        // - Sample size score: min(1.0, samples / 8.0)
        double sampleScore = Math.min(1.0, samples / 8.0);

        // - Inactivity degradation: confidence decays gracefully as away days increase
        double durationDecay = 1.0;
        if (awayDays > 3) {
            durationDecay = Math.exp(-0.03 * (awayDays - 3));
        }

        // - Variability factor
        double variability = input.getConsumptionVariability() != null
                ? input.getConsumptionVariability().doubleValue()
                : 0.3;
        double consistencyScore = 1.0 / (1.0 + Math.min(1.0, variability));

        double rawConfidence = (0.40 * sampleScore + 0.35 * consistencyScore + 0.25 * durationDecay);
        double finalConfidence = Math.min(0.95, Math.max(0.25, rawConfidence));

        long confPct = Math.round(finalConfidence * 100);
        String confLabel = confPct + "% confidence";

        String rationale = String.format(
                "Based on average consumption (~%s/day) across %d days away with %d samples",
                baseVelocity.setScale(2, RoundingMode.HALF_UP),
                awayDays,
                samples
        );

        return AwayPredictionResult.builder()
                .estimatedConsumption(predictedConsumption)
                .estimatedRemainingStock(estimatedRemaining)
                .confidence(finalConfidence)
                .confidenceLabel(confLabel)
                .rationale(rationale)
                .isColdStart(false)
                .build();
    }
}
