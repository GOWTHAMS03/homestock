package com.homestock.modules.away.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

@Slf4j
@Service
public class PredictionConfidenceService {

    @Value("${app.away-summary.confidence-threshold:0.40}")
    private double confidenceThreshold = 0.40;

    public double calculateConfidence(
            int sampleCount,
            BigDecimal consumptionVariability,
            long awayDays,
            boolean hasFeedbackHistory
    ) {
        // 1. Sample Size Weight (max 1.0 at 10 samples)
        double sampleScore = Math.min(1.0, sampleCount / 10.0);

        // 2. Consistency Score (inverse of variability)
        double variability = consumptionVariability != null ? consumptionVariability.doubleValue() : 0.35;
        double consistencyScore = 1.0 / (1.0 + Math.max(0.05, variability));

        // 3. Inactivity Duration Decay: confidence decays as awayDays grows beyond 3
        double durationDecay = 1.0;
        if (awayDays > 3) {
            durationDecay = Math.exp(-0.035 * (awayDays - 3));
        }

        // 4. Historical Feedback Calibration Bonus
        double feedbackBonus = hasFeedbackHistory ? 0.05 : 0.0;

        // Weighted combination: 40% sample, 35% consistency, 25% duration + bonus
        double combined = (0.40 * sampleScore) + (0.35 * consistencyScore) + (0.25 * durationDecay) + feedbackBonus;

        // Clamp to [0.10, 0.98]
        return Math.min(0.98, Math.max(0.10, combined));
    }

    public boolean isProminent(double confidence) {
        return confidence >= confidenceThreshold;
    }

    public String formatConfidenceLabel(double confidence) {
        long pct = Math.round(confidence * 100);
        return pct + "% confidence";
    }
}
