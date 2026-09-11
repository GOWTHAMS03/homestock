package com.homestock.modules.smartshopping.dto;

/**
 * Verification status of offer pricing.
 */
public enum PriceStatus {
    /**
     * Verified directly from current product page / active live inventory.
     */
    PRICE_VERIFIED,

    /**
     * Price derived only from search snippet or unconfirmed index; not guaranteed.
     */
    PRICE_UNVERIFIED,

    /**
     * Suspicious price diverging abnormally from benchmark market range (e.g. ₹29 vs ₹150).
     */
    PRICE_ANOMALY
}
