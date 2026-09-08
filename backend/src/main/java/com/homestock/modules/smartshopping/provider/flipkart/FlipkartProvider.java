package com.homestock.modules.smartshopping.provider.flipkart;

import com.homestock.modules.smartshopping.dto.ProductOfferDto;
import com.homestock.modules.smartshopping.provider.ProductSearchRequest;
import com.homestock.modules.smartshopping.provider.ProviderCapability;
import com.homestock.modules.smartshopping.provider.ShoppingProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.Set;

/**
 * Flipkart Affiliate API provider.
 * Declares supported capabilities. Multi-item cart is not supported.
 */
@Component
public class FlipkartProvider implements ShoppingProvider {

    private static final Logger log = LoggerFactory.getLogger(FlipkartProvider.class);

    private static final Set<ProviderCapability> CAPABILITIES = Set.of(
            ProviderCapability.SEARCH,
            ProviderCapability.PRODUCT_DETAILS,
            ProviderCapability.OFFERS,
            ProviderCapability.PRICE,
            ProviderCapability.AVAILABILITY,
            ProviderCapability.DEEP_LINK,
            ProviderCapability.AFFILIATE_LINK
    );

    @Value("${app.smart-shopping.providers.flipkart.enabled:false}")
    private boolean enabled;

    @Value("${app.smart-shopping.providers.flipkart.affiliate-id:}")
    private String affiliateId;

    @Override
    public String getProviderName() {
        return "FLIPKART";
    }

    @Override
    public String getDisplayName() {
        return "Flipkart";
    }

    @Override
    public boolean isEnabled() {
        return enabled && affiliateId != null && !affiliateId.isBlank();
    }

    @Override
    public Set<ProviderCapability> getCapabilities() {
        return CAPABILITIES;
    }

    @Override
    public List<ProductOfferDto> searchProducts(ProductSearchRequest request) {
        if (!isEnabled()) {
            log.debug("[FlipkartProvider] Provider is disabled, skipping search");
            return Collections.emptyList();
        }

        log.info("[FlipkartProvider] Flipkart API query for: '{}'", request.getItemName());
        return Collections.emptyList();
    }

    @Override
    public Optional<ProductOfferDto> getProduct(String providerProductId) {
        if (!isEnabled()) return Optional.empty();
        return Optional.empty();
    }

    @Override
    public String buildAffiliateUrl(String providerProductId, String originalUrl) {
        if (originalUrl == null || originalUrl.isBlank()) {
            originalUrl = "https://www.flipkart.com/product/p/" + providerProductId;
        }
        if (affiliateId != null && !affiliateId.isBlank()) {
            String separator = originalUrl.contains("?") ? "&" : "?";
            return originalUrl + separator + "affid=" + affiliateId;
        }
        return originalUrl;
    }

    @Override
    public String buildDeepLink(String providerProductId, String fallbackUrl) {
        if (providerProductId != null && !providerProductId.isBlank()) {
            return "flipkart://dl/product/" + providerProductId;
        }
        return fallbackUrl;
    }
}
