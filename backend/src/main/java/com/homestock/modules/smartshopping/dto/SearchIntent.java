package com.homestock.modules.smartshopping.dto;

/**
 * High-level intent classification for shopping searches.
 */
public enum SearchIntent {
    /**
     * User specified a clear product with identifying brand, variant, or size
     * (e.g. "Surf Excel Matic Top Load 2kg", "Fortune Sunflower Oil 1L").
     */
    EXACT_PRODUCT,

    /**
     * User specified brand and item without exhaustive variant/pack details
     * (e.g. "Parle-G 800g", "Amul Butter").
     */
    BRANDED_PRODUCT,

    /**
     * User specified a specific sub-type or variant without a brand constraint
     * (e.g. "Coca Cola Zero Sugar 750ml", "Cold Pressed Groundnut Oil").
     */
    SPECIFIC_VARIANT,

    /**
     * Genuinely generic grocery item without a specified brand
     * (e.g. "Sunflower oil", "Toor dal", "Bath soap", "Dishwash liquid").
     */
    GENERIC_PRODUCT,

    /**
     * Category level search.
     */
    CATEGORY_SEARCH,

    /**
     * Alias / Generic search.
     */
    GENERIC_SEARCH,

    /**
     * Exact barcode search.
     */
    BARCODE_SEARCH,

    /**
     * Ambiguous single-token input that cannot be resolved safely to a single product type
     * (e.g. "oil", "soap", "rice").
     */
    INSUFFICIENT_INFORMATION
}
