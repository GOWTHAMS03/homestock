package com.homestock.modules.smartshopping.engine.url;

import com.homestock.modules.smartshopping.dto.ProductCandidate;
import com.homestock.modules.smartshopping.dto.ProductIdentity;

/**
 * Common interface for resolving, canonicalizing, and validating product URLs.
 * Conforms to Section 56.
 */
public interface ProductUrlResolver {

    /**
     * Resolves the direct product detail page URL for a candidate product.
     * If the candidate only has a search/discovery URL, attempts resolution to a direct product page.
     * Returns the canonical product detail URL, or null if no direct product page is available.
     */
    String resolveProductUrl(ProductCandidate candidate);

    /**
     * Validates a product URL against retailer URL rules.
     */
    ProductUrlValidationResult validateProductUrl(String url);

    /**
     * Validates a product URL against retailer URL rules and ProductIdentity consistency.
     */
    ProductUrlValidationResult validateProductUrl(String url, ProductIdentity identity);

    /**
     * Extracts structured product metadata from a product URL.
     */
    ProductUrlMetadata extractProductMetadata(String url);

    /**
     * Strips tracking/session parameters and standardizes the URL to its canonical form.
     */
    String canonicalizeUrl(String url);
}
