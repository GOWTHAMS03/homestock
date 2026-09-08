package com.homestock.modules.consumption.entity;

import java.math.BigDecimal;

public enum QuantityStatus {
    ALMOST_FULL("Almost full", new BigDecimal("0.90")),
    MORE_THAN_HALF("More than half", new BigDecimal("0.70")),
    ABOUT_HALF("About half", new BigDecimal("0.50")),
    LESS_THAN_HALF("Less than half", new BigDecimal("0.30")),
    ALMOST_EMPTY("Almost empty", new BigDecimal("0.10")),
    EMPTY("Empty", BigDecimal.ZERO);

    private final String displayName;
    private final BigDecimal approximateRatio;

    QuantityStatus(String displayName, BigDecimal approximateRatio) {
        this.displayName = displayName;
        this.approximateRatio = approximateRatio;
    }

    public String getDisplayName() {
        return displayName;
    }

    public BigDecimal getApproximateRatio() {
        return approximateRatio;
    }

    public static QuantityStatus fromRatio(BigDecimal ratio) {
        if (ratio == null || ratio.compareTo(BigDecimal.ZERO) <= 0) return EMPTY;
        if (ratio.compareTo(new BigDecimal("0.20")) <= 0) return ALMOST_EMPTY;
        if (ratio.compareTo(new BigDecimal("0.40")) <= 0) return LESS_THAN_HALF;
        if (ratio.compareTo(new BigDecimal("0.60")) <= 0) return ABOUT_HALF;
        if (ratio.compareTo(new BigDecimal("0.80")) <= 0) return MORE_THAN_HALF;
        return ALMOST_FULL;
    }
}
