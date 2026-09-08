package com.homestock.modules.smartshopping.provider;

import com.homestock.modules.smartshopping.dto.ProductOfferDto;

import java.util.List;
import java.util.Optional;
import java.util.Set;

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
     * Unique provider identifier (e.g. "AMAZON", "FLIPKART", "MOCK", "LOCAL").
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
     * Declared capabilities for this provider.
     * Capabilities are never assumed.
     */
    Set<ProviderCapability> getCapabilities();

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
     * Build an affiliate link for the given product.
     * The returned URL includes any affiliate tags, partner IDs, etc.
     *
     * @param providerProductId the provider-specific product identifier
     * @param originalUrl       the original product URL
     * @return the affiliate-tagged URL
     */
    String buildAffiliateUrl(String providerProductId, String originalUrl);

    /**
     * Build a deep link directly opening the provider's mobile app if installed,
     * falling back to the web affiliate URL.
     *
     * @param providerProductId the provider-specific product identifier
     * @param fallbackUrl       the web affiliate URL fallback
     * @return deep link URI scheme or fallback URL
     */
    default String buildDeepLink(String providerProductId, String fallbackUrl) {
        return fallbackUrl;
    }
}

