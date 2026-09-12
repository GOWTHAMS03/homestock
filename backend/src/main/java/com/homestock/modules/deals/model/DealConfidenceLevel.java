package com.homestock.modules.deals.model;

/**
 * Confidence grading for deals.
 * 95–100: EXCELLENT
 * 85–94: HIGH
 * 70–84: MEDIUM
 * Below 70: REJECTED (Do not show as Best Deal)
 */
public enum DealConfidenceLevel {
    EXCELLENT(95.0, "Excellent"),
    HIGH(85.0, "High confidence"),
    MEDIUM(70.0, "Medium confidence"),
    REJECTED(0.0, "Low confidence");

    private final double minimumScore;
    private final String label;

    DealConfidenceLevel(double minimumScore, String label) {
        this.minimumScore = minimumScore;
        this.label = label;
    }

    public double getMinimumScore() {
        return minimumScore;
    }

    public String getLabel() {
        return label;
    }

    public static DealConfidenceLevel fromScore(double score) {
        if (score >= 95.0) return EXCELLENT;
        if (score >= 85.0) return HIGH;
        if (score >= 70.0) return MEDIUM;
        return REJECTED;
    }
}
