package com.homestock.modules.deals.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * Structured output of query normalization.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NormalizedProductQuery {
    private String rawQuery;
    private String normalizedQuery;
    private String brand;
    private String category;
    private String product;
    private String variant;
    private BigDecimal canonicalQuantity;
    private String canonicalUnit; // ML, G, PCS
    @Builder.Default
    private Integer packCount = 1;
    private String displayPackSize; // e.g. "1 L", "500 ml"
}
