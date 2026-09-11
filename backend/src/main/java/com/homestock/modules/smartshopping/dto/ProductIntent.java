package com.homestock.modules.smartshopping.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.Map;

/**
 * Comprehensive Product Intent representation extracted from user input.
 * Preserves all original user signals and separates product pack size
 * from requested user quantity.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductIntent {

    /** Original raw user text */
    private String rawInput;

    /** Normalized product name */
    private String productName;

    /** Generic / common category product name (e.g. "Sunflower Oil", "Toor Dal") */
    private String genericName;

    /** Fully qualified exact product name */
    private String exactProductName;

    /** Extracted brand (e.g. "Fortune", "Surf Excel", "Tata Sampann") */
    private String brand;

    /** Extracted product variant / subtype (e.g. "Matic Top Load", "Zero Sugar") */
    private String variant;

    /** Model number or identifier if applicable */
    private String model;

    /** User-requested quantity (e.g. 2 for "2 bottles") */
    private BigDecimal quantity;

    /** Quantity unit for user purchase (e.g. "bottle", "pack", "kg") */
    private String unit;

    /** Product packaging / pack size (e.g. "1L", "2kg", "500g") */
    private String packSize;

    /** Normalized weight value if applicable */
    private BigDecimal weight;

    /** Normalized volume value if applicable */
    private BigDecimal volume;

    /** Product flavor if applicable */
    private String flavor;

    /** Physical size specification if applicable */
    private String size;

    /** Product color if applicable */
    private String color;

    /** High-level product category (e.g. "Cooking Oil", "Rice & Grains") */
    private String category;

    /** Granular sub-category */
    private String subCategory;

    /** Barcode / GTIN string if provided or detected */
    private String barcode;

    /** Classified search intent category */
    private SearchIntent searchIntent;

    /** Overall confidence score (0.0 to 1.0) */
    private Double confidence;

    /** Confidence score for individual extracted fields */
    @Builder.Default
    private Map<String, Double> fieldConfidences = Collections.emptyMap();
}
