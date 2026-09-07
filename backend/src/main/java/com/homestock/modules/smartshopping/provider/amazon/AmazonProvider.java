package com.homestock.modules.smartshopping.provider.amazon;

import com.homestock.modules.smartshopping.dto.ProductOfferDto;
import com.homestock.modules.smartshopping.provider.ProductSearchRequest;
import com.homestock.modules.smartshopping.provider.ShoppingProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Collections;
import java.util.List;
import java.util.Optional;

/**
 * Amazon PA-API 5.0 provider stub.
 * <p>
 * This provider is disabled by default and will return empty results until
 * valid Amazon Associates API credentials are configured via environment variables:
 * <ul>
 *   <li>AMAZON_PARTNER_TAG</li>
 *   <li>AMAZON_ACCESS_KEY</li>
 *   <li>AMAZON_SECRET_KEY</li>
 * </ul>
 * <p>
 * Implementation will use Amazon's Product Advertising API 5.0 for
 * SearchItems and GetItems operations when activated.
 */
@Component
public class AmazonProvider implements ShoppingProvider {

    private static final Logger log = LoggerFactory.getLogger(AmazonProvider.class);

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
    public List<ProductOfferDto> searchProducts(ProductSearchRequest request) {
        if (!isEnabled()) {
            log.debug("[AmazonProvider] Provider is disabled, skipping search");
            return Collections.emptyList();
        }

        // TODO: Implement Amazon PA-API 5.0 SearchItems
        log.info("[AmazonProvider] Real Amazon API integration pending — returning empty results");
        return Collections.emptyList();
    }

    @Override
    public Optional<ProductOfferDto> getProduct(String providerProductId) {
        if (!isEnabled()) return Optional.empty();

        // TODO: Implement Amazon PA-API 5.0 GetItems
        return Optional.empty();
    }

    @Override
    public String buildAffiliateUrl(String providerProductId, String originalUrl) {
        if (partnerTag != null && !partnerTag.isBlank()) {
            String separator = originalUrl.contains("?") ? "&" : "?";
            return originalUrl + separator + "tag=" + partnerTag;
        }
        return originalUrl;
    }
}
