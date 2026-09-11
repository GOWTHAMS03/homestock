package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.Map;

/**
 * Canonical representation of resolved product identity.
 * Represents the exact real-world product intended by the user.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductIdentity {

    /** Original raw user text */
    private String rawInput;

    /** Canonical brand name (e.g. "Fortune", "Surf Excel") */
    private String brand;

    /** Canonical product name (e.g. "Sunflower Oil", "Matic") */
    private String product;

    /** Common generic grocery term (e.g. "Sunflower Oil", "Toor Dal") */
    private String genericName;

    /** Canonical variant/flavor if specified (e.g. "Top Load", "Zero Sugar") */
    private String variant;

    /** Pack size raw number (e.g. 1.0) */
    private BigDecimal packSize;

    /** Pack size raw unit (e.g. "L", "kg", "ml", "g") */
    private String packUnit;

    /** Normalized pack size value for mathematical comparisons (e.g. 1000.0 for 1L) */
    private BigDecimal normalizedPackSizeValue;

    /** Normalized pack unit: "ML" for volume, "G" for weight, "COUNT" for pieces */
    private String normalizedPackSizeUnit;

    /** User-requested quantity (e.g. 2 for "2 bottles") */
    private BigDecimal requestedQuantity;

    /** User purchase unit (e.g. "bottle", "pack", "bag") */
    private String requestedQuantityUnit;

    /** Primary taxonomy category (e.g. "Cooking Oil", "Laundry") */
    private String category;

    /** Sub-category / variant taxonomy classification */
    private String subCategory;

    /** Product type description (e.g. "Branded Product", "Generic Product") */
    private String productType;

    /** Classified search mode */
    private SearchIntent searchMode;

    /** Hard requirement constraints */
    private IdentityConstraints constraints;

    /** Barcode / GTIN string */
    private String barcode;

    /** Overall confidence score (0.0 to 1.0) */
    private Double confidence;

    /** Field-level confidence scores */
    @Builder.Default
    private Map<String, Double> fieldConfidences = Collections.emptyMap();
}
