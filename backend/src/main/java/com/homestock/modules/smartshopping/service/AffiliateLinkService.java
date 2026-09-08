package com.homestock.modules.smartshopping.service;

import com.homestock.core.util.SecurityUtils;
import com.homestock.modules.smartshopping.dto.AffiliateClickRequest;
import com.homestock.modules.smartshopping.dto.AffiliateClickResponse;
import com.homestock.modules.smartshopping.dto.ProductOfferDto;
import com.homestock.modules.smartshopping.entity.AffiliateClick;
import com.homestock.modules.smartshopping.provider.ShoppingProvider;
import com.homestock.modules.smartshopping.repository.AffiliateClickRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Manages affiliate link generation and click tracking.
 * <p>
 * Never exposes raw affiliate credentials to the frontend.
 * Never influences price ranking based on commission.
 */
@Service
@RequiredArgsConstructor
public class AffiliateLinkService {

    private static final Logger log = LoggerFactory.getLogger(AffiliateLinkService.class);

    private final List<ShoppingProvider> providers;
    private final AffiliateClickRepository clickRepository;

    /**
     * Record an affiliate click and return the affiliate URL.
     */
    @Transactional
    public AffiliateClickResponse recordClickAndGetUrl(UUID homeId, AffiliateClickRequest request) {
        UUID userId = SecurityUtils.getCurrentUserId();

        // Find the provider
        Optional<ShoppingProvider> provider = providers.stream()
                .filter(p -> p.getProviderName().equalsIgnoreCase(request.getProvider()))
                .findFirst();

        String affiliateUrl;
        if (provider.isPresent()) {
            // Get the original product to build affiliate URL
            Optional<ProductOfferDto> product = provider.get().getProduct(request.getProviderProductId());
            String originalUrl = product.map(ProductOfferDto::getProductUrl)
                    .orElse("https://" + request.getProvider().toLowerCase() + ".in");

            affiliateUrl = provider.get().buildAffiliateUrl(request.getProviderProductId(), originalUrl);
        } else {
            log.warn("[AffiliateLinkService] Unknown provider: {}", request.getProvider());
            affiliateUrl = null;
        }

        // Record the click
        AffiliateClick click = AffiliateClick.builder()
                .userId(userId)
                .homeId(homeId)
                .shoppingItemId(request.getShoppingItemId())
                .provider(request.getProvider())
                .providerProductId(request.getProviderProductId())
                .sessionId(request.getSessionId())
                .sourceScreen(request.getSourceScreen())
                .clickedAt(Instant.now())
                .build();

        clickRepository.save(click);
        log.info("[AffiliateLinkService] Recorded click: provider={}, product={}, user={}", 
                request.getProvider(), request.getProviderProductId(), userId);

        return AffiliateClickResponse.builder()
                .affiliateUrl(affiliateUrl)
                .provider(request.getProvider())
                .providerProductId(request.getProviderProductId())
                .build();
    }
}
