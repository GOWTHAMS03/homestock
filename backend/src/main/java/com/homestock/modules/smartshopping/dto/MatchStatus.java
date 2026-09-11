package com.homestock.modules.smartshopping.dto;

/**
 * Confidence level and matching resolution status for candidate products.
 */
public enum MatchStatus {
    /**
     * Score 95 - 100: Verified exact identity, brand, variant, and pack size.
     */
    VERIFIED_EXACT,

    /**
     * Score 85 - 94: High confidence match with identical brand and core specifications.
     */
    HIGH_CONFIDENCE,

    /**
     * Score 70 - 84: Possible match with slight attribute differences (e.g. close size or minor variant).
     */
    POSSIBLE_MATCH,

    /**
     * Score < 70: Rejected match due to brand mismatch, wrong product, or severe attribute conflict.
     */
    REJECT,

    /**
     * No trustworthy products found for exact specifications.
     */
    NOT_FOUND,

    /**
     * Ambiguous query with multiple candidate product categories.
     */
    AMBIGUOUS
}
