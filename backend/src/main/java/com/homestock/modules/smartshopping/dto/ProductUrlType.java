package com.homestock.modules.smartshopping.dto;

/**
 * Categorization of URLs encountered in product discovery and deals.
 * Conforms to Section 43 & Section 55:
 * Only PRODUCT_DETAIL_PAGE is valid for direct product page navigation ("View Deal").
 */
public enum ProductUrlType {
    /**
     * Direct product detail page of the specific product item.
     * Contains product specifications, direct buy/cart actions, and specific SKU/ASIN.
     */
    PRODUCT_DETAIL_PAGE,

    /**
     * Generic search query or search result page (e.g. /search?q=..., /s?k=...).
     * Strictly REJECTED for direct product deal navigation.
     */
    SEARCH_PAGE,

    /**
     * Category, department, aisle, or taxonomy browse page.
     * Strictly REJECTED for direct product deal navigation.
     */
    CATEGORY_PAGE,

    /**
     * Retailer homepage or root landing page.
     * Strictly REJECTED for direct product deal navigation.
     */
    HOMEPAGE,

    /**
     * Malformed, blank, unsupported protocol, or unparseable URL.
     * Strictly REJECTED.
     */
    INVALID_URL;

    /**
     * Whether this URL type represents a direct product detail page.
     */
    public boolean isDirectProductDetail() {
        return this == PRODUCT_DETAIL_PAGE;
    }
}
