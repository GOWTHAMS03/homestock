package com.homestock.modules.deals.model;

/**
 * Strict segregation of deal matches.
 * The main Deals section must prioritize EXACT_MATCH.
 */
public enum DealMatchCategory {
    EXACT_MATCH,
    SIMILAR_ALTERNATIVE,
    REJECTED
}
