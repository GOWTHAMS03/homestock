package com.homestock.modules.smartshopping.provider.flipkart;

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
 * Flipkart Affiliate API provider stub.
 * <p>
 * This provider is disabled by default and will return empty results until
 * valid Flipkart Affiliate credentials are configured via environment variables:
 * <ul>
 *   <li>FLIPKART_AFFILIATE_ID</li>
 *   <li>FLIPKART_AFFILIATE_TOKEN</li>
 * </ul>
 */
@Component
public class FlipkartProvider implements ShoppingProvider {

    private static final Logger log = LoggerFactory.getLogger(FlipkartProvider.class);

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
    public List<ProductOfferDto> searchProducts(ProductSearchRequest request) {
        if (!isEnabled()) {
            log.debug("[FlipkartProvider] Provider is disabled, skipping search");
            return Collections.emptyList();
        }

        // TODO: Implement Flipkart Affiliate API integration
        log.info("[FlipkartProvider] Real Flipkart API integration pending — returning empty results");
        return Collections.emptyList();
    }

    @Override
    public Optional<ProductOfferDto> getProduct(String providerProductId) {
        if (!isEnabled()) return Optional.empty();

        // TODO: Implement Flipkart product lookup
        return Optional.empty();
    }

    @Override
    public String buildAffiliateUrl(String providerProductId, String originalUrl) {
        if (affiliateId != null && !affiliateId.isBlank()) {
            String separator = originalUrl.contains("?") ? "&" : "?";
            return originalUrl + separator + "affid=" + affiliateId;
        }
        return originalUrl;
    }
}
