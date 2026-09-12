package com.homestock.modules.deals.model;

/**
 * Validation status for real-time deals in HomeStock.
 * Core Principle: NO VALIDATION = NO DEAL.
 */
public enum DealValidationStatus {
    VALID,
    STALE,
    PRICE_CHANGED,
    OUT_OF_STOCK,
    UNAVAILABLE,
    INVALID_URL,
    VARIANT_MISMATCH,
    QUANTITY_MISMATCH,
    VALIDATION_FAILED;

    public boolean isEligibleForBestDeals() {
        return this == VALID || this == PRICE_CHANGED;
    }
}
