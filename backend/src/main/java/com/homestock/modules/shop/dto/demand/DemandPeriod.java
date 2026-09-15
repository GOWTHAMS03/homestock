package com.homestock.modules.shop.dto.demand;

public enum DemandPeriod {
    TODAY(1),
    LAST_7_DAYS(7),
    LAST_30_DAYS(30),
    LAST_90_DAYS(90);

    private final int days;

    DemandPeriod(int days) {
        this.days = days;
    }

    public int getDays() {
        return days;
    }

    public static DemandPeriod fromString(String val) {
        if (val == null || val.isBlank()) {
            return LAST_7_DAYS;
        }
        try {
            return DemandPeriod.valueOf(val.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return LAST_7_DAYS;
        }
    }
}
