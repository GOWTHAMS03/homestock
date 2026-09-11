package com.homestock.modules.smartshopping.engine.url;

import com.homestock.modules.smartshopping.dto.ProductUrlType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Structured metadata extracted from a retailer or search engine URL.
 * Conforms to Section 42 & Section 45.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductUrlMetadata {
    private String rawUrl;
    private String canonicalUrl;
    private ProductUrlType urlType;
    private String domain;

    private String retailerProductId; // SKU, ASIN, prid, pd id, pvid
    private String sku;
    private String asin;

    private String urlSlug;
    private String extractedBrand;
    private String extractedVariant;
    private String extractedPackSize;

    @Builder.Default
    private boolean isRedirect = false;
    private String finalRedirectUrl;
}
