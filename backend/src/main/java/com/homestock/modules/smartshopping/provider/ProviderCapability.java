package com.homestock.modules.smartshopping.provider;

/**
 * Declared capabilities for shopping providers.
 * <p>
 * Capabilities are never assumed. Every provider explicitly declares what it officially supports.
 * If a provider does not support a capability (e.g. MULTI_ITEM_CART), the architecture
 * gracefully falls back to individual product or deep links without pretending or faking cart manipulation.
 */
public enum ProviderCapability {
    SEARCH,
    PRODUCT_DETAILS,
    OFFERS,
    PRICE,
    AVAILABILITY,
    DEEP_LINK,
    AFFILIATE_LINK,
    MULTI_ITEM_CART,
    CART_ADD,
    CART_CHECKOUT
}
