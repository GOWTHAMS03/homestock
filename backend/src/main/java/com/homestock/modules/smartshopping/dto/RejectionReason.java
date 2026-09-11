package com.homestock.modules.smartshopping.dto;

/**
 * Explicit reasons for candidate rejection during Product Identity Resolution.
 */
public enum RejectionReason {
    /** Candidate brand does not match requested brand */
    WRONG_BRAND,

    /** Candidate is a different product within or across categories */
    WRONG_PRODUCT,

    /** Mutually exclusive variant clash (e.g. Mustard vs Sunflower, Brown rice vs Basmati) */
    WRONG_VARIANT,

    /** Pack size discrepancy in exact product search (e.g. 1kg vs 2kg) */
    WRONG_PACK_SIZE,

    /** Candidate does not belong to requested taxonomy category */
    WRONG_CATEGORY,

    /** Candidate barcode conflicts with requested barcode */
    BARCODE_MISMATCH,

    /** Identity match confidence below minimum threshold */
    LOW_CONFIDENCE,

    /** Price could not be verified from active product source */
    PRICE_UNVERIFIED,

    /** Image belongs to a different product */
    IMAGE_MISMATCH,

    /** Product is permanently out of stock or unavailable */
    UNAVAILABLE,

    /** Redundant duplicate offer */
    DUPLICATE
}
