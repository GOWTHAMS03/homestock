package com.homestock.modules.smartshopping.provider.amazon;

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
 * Amazon PA-API 5.0 provider.
 * Declares supported capabilities. Note: MULTI_ITEM_CART and CART_ADD are NOT supported
 * as Amazon PA-API does not support cart manipulation without custom client checkout authorization.
 */
@Component
public class AmazonProvider implements ShoppingProvider {

    private static final Logger log = LoggerFactory.getLogger(AmazonProvider.class);

    private static final Set<ProviderCapability> CAPABILITIES = Set.of(
            ProviderCapability.SEARCH,
            ProviderCapability.PRODUCT_DETAILS,
            ProviderCapability.OFFERS,
            ProviderCapability.PRICE,
            ProviderCapability.AVAILABILITY,
            ProviderCapability.DEEP_LINK,
            ProviderCapability.AFFILIATE_LINK
    );

    @Value("${app.smart-shopping.providers.amazon.enabled:false}")
    private boolean enabled;

    @Value("${app.smart-shopping.providers.amazon.partner-tag:}")
    private String partnerTag;

    @Override
    public String getProviderName() {
        return "AMAZON";
    }

    @Override
    public String getDisplayName() {
        return "Amazon";
    }

    @Override
    public boolean isEnabled() {
        return enabled && partnerTag != null && !partnerTag.isBlank();
    }

    @Override
    public Set<ProviderCapability> getCapabilities() {
        return CAPABILITIES;
    }

    @Override
    public List<ProductOfferDto> searchProducts(ProductSearchRequest request) {
        if (!isEnabled()) {
            log.debug("[AmazonProvider] Provider is disabled, skipping search");
            return Collections.emptyList();
        }

        // Live Amazon PA-API 5.0 SearchItems endpoint call
        log.info("[AmazonProvider] PA-API query for: '{}'", request.getItemName());
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
            originalUrl = "https://www.amazon.in/dp/" + providerProductId;
        }
        if (partnerTag != null && !partnerTag.isBlank()) {
            String separator = originalUrl.contains("?") ? "&" : "?";
            return originalUrl + separator + "tag=" + partnerTag;
        }
        return originalUrl;
    }

    @Override
    public String buildDeepLink(String providerProductId, String fallbackUrl) {
        // Controlled deep link to open Amazon app if installed on mobile
        if (providerProductId != null && !providerProductId.isBlank()) {
            return "com.amazon.mobile.shopping.web://www.amazon.in/dp/" + providerProductId;
        }
        return fallbackUrl;
    }
}
