package com.homestock.modules.away;

import com.homestock.modules.away.ml.StatisticalAwayPredictor;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;

class StatisticalAwayPredictorTest {

    private StatisticalAwayPredictor predictor;

    @BeforeEach
    void setUp() {
        predictor = new StatisticalAwayPredictor();
    }

    @Test
    @DisplayName("Cold start user (< 3 samples) returns isColdStart = true with safe fallback")
    void testColdStartPrediction() {
        StatisticalAwayPredictor.AwayPredictionInput input = StatisticalAwayPredictor.AwayPredictionInput.builder()
                .itemName("Milk")
                .currentStockBeforeAway(new BigDecimal("2.0"))
                .baselineDailyConsumption(new BigDecimal("0.35"))
                .sampleCount(2) // < 3 samples
                .awayStartDate(LocalDate.of(2026, 9, 1))
                .awayEndDate(LocalDate.of(2026, 9, 7))
                .build();

        StatisticalAwayPredictor.AwayPredictionResult result = predictor.predict(input);

        assertNotNull(result);
        assertTrue(result.isColdStart());
        assertEquals("Still learning your household's usage pattern.", result.getRationale());
        assertEquals(new BigDecimal("2.0"), result.getEstimatedRemainingStock());
    }

    @Test
    @DisplayName("Mature user with 6 days away calculates weekend seasonality and consumption")
    void testMaturePredictionWithSeasonality() {
        // Sep 1, 2026 (Tue) to Sep 7, 2026 (Mon) = 7 days (5 weekdays, 2 weekend days: Sep 5 & 6)
        StatisticalAwayPredictor.AwayPredictionInput input = StatisticalAwayPredictor.AwayPredictionInput.builder()
                .itemName("Sunflower Oil")
                .currentStockBeforeAway(new BigDecimal("2.0"))
                .baselineDailyConsumption(new BigDecimal("0.10"))
                .consumptionVariability(new BigDecimal("0.15"))
                .sampleCount(8)
                .awayStartDate(LocalDate.of(2026, 9, 1))
                .awayEndDate(LocalDate.of(2026, 9, 7))
                .build();

        StatisticalAwayPredictor.AwayPredictionResult result = predictor.predict(input);

        assertNotNull(result);
        assertFalse(result.isColdStart());
        assertTrue(result.getEstimatedConsumption().compareTo(BigDecimal.ZERO) > 0);
        assertTrue(result.getEstimatedRemainingStock().compareTo(new BigDecimal("2.0")) < 0);
        assertTrue(result.getConfidence() >= 0.70);
    }

    @Test
    @DisplayName("Learned feedback calibration factor scales predicted velocity accurately")
    void testFeedbackCalibrationScaling() {
        // User had previously corrected predictions, establishing a 0.80 calibration factor
        StatisticalAwayPredictor.AwayPredictionInput uncalibrated = StatisticalAwayPredictor.AwayPredictionInput.builder()
                .itemName("Milk")
                .currentStockBeforeAway(new BigDecimal("2.0"))
                .baselineDailyConsumption(new BigDecimal("0.40"))
                .sampleCount(8)
                .awayStartDate(LocalDate.of(2026, 9, 1))
                .awayEndDate(LocalDate.of(2026, 9, 6))
                .feedbackCalibrationFactor(BigDecimal.ONE)
                .build();

        StatisticalAwayPredictor.AwayPredictionInput calibrated = StatisticalAwayPredictor.AwayPredictionInput.builder()
                .itemName("Milk")
                .currentStockBeforeAway(new BigDecimal("2.0"))
                .baselineDailyConsumption(new BigDecimal("0.40"))
                .sampleCount(8)
                .awayStartDate(LocalDate.of(2026, 9, 1))
                .awayEndDate(LocalDate.of(2026, 9, 6))
                .feedbackCalibrationFactor(new BigDecimal("0.80"))
                .build();

        var resUncalibrated = predictor.predict(uncalibrated);
        var resCalibrated = predictor.predict(calibrated);

        assertTrue(resCalibrated.getEstimatedConsumption().compareTo(resUncalibrated.getEstimatedConsumption()) < 0,
                "Calibrated consumption with factor 0.80 should be less than uncalibrated");
    }
}
