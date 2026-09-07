package com.homestock.modules.smartshopping.provider;

import com.homestock.modules.smartshopping.dto.ProductOfferDto;

import java.util.List;
import java.util.Optional;

/**
 * Abstraction for all shopping/affiliate providers.
 * <p>
 * Each provider (Amazon, Flipkart, BigBasket, etc.) implements this interface
 * so the core comparison engine never depends on provider-specific logic.
 * <p>
 * New providers can be added by implementing this interface and registering
 * as a Spring bean — no changes to controllers or services required.
 */
public interface ShoppingProvider {

    /**
     * Unique provider identifier (e.g. "AMAZON", "FLIPKART", "MOCK").
     */
    String getProviderName();

    /**
     * Human-readable display name shown in the UI.
     */
    String getDisplayName();

    /**
     * Whether this provider is currently enabled and operational.
     */
    boolean isEnabled();

    /**
     * Search for products matching the given request.
     *
     * @param request search parameters including item name, brand, quantity, unit
     * @return list of normalized product offers (may be empty, never null)
     */
    List<ProductOfferDto> searchProducts(ProductSearchRequest request);

    /**
     * Get details for a specific product by provider's product ID.
     *
     * @param providerProductId the provider-specific product identifier
     * @return the product offer if found
     */
    Optional<ProductOfferDto> getProduct(String providerProductId);

    /**
     * Build an affiliate/deep link for the given product.
     * The returned URL should include any affiliate tags, partner IDs, etc.
     *
     * @param providerProductId the provider-specific product identifier
     * @param originalUrl       the original product URL
     * @return the affiliate-tagged URL
     */
    String buildAffiliateUrl(String providerProductId, String originalUrl);
}
