package com.homestock.modules.smartshopping.service;

import com.homestock.modules.smartshopping.dto.ProductOfferDto;
import com.homestock.modules.smartshopping.entity.ProductOfferEntity;
import com.homestock.modules.smartshopping.entity.PriceHistory;
import com.homestock.modules.smartshopping.repository.ProductOfferRepository;
import com.homestock.modules.smartshopping.repository.PriceHistoryRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

/**
 * PostgreSQL-backed price cache service.
 * <p>
 * Stores provider search results in the product_offers table with configurable TTL.
 * Avoids hitting external APIs on every comparison request.
 */
@Service
@RequiredArgsConstructor
public class PriceCacheService {

    private static final Logger log = LoggerFactory.getLogger(PriceCacheService.class);

    private final ProductOfferRepository offerRepository;
    private final PriceHistoryRepository priceHistoryRepository;

    @Value("${app.smart-shopping.cache.ttl-minutes:15}")
    private int cacheTtlMinutes;

    /**
     * Check if we have fresh cached offers for this query.
     *
     * @param canonicalId canonical product identifier
     * @return fresh cached offers, or empty list if cache miss/expired
     */
    public List<ProductOfferDto> getCachedOffers(String canonicalId) {
        Instant cutoff = Instant.now().minus(Duration.ofMinutes(cacheTtlMinutes));
        List<ProductOfferEntity> cached = offerRepository.findFreshOffers(canonicalId, cutoff);

        if (cached.isEmpty()) {
            log.debug("[PriceCache] Cache MISS for canonical ID: {}", canonicalId);
            return List.of();
        }

        log.debug("[PriceCache] Cache HIT for canonical ID: {} ({} offers)", canonicalId, cached.size());
        return cached.stream()
                .map(this::entityToDto)
                .collect(Collectors.toList());
    }

    /**
     * Store offers in the cache and record price history.
     */
    @Transactional
    public void cacheOffers(String canonicalId, List<ProductOfferDto> offers) {
        Instant now = Instant.now();

        for (ProductOfferDto offer : offers) {
            // Upsert offer cache
            ProductOfferEntity entity = offerRepository
                    .findByProviderAndProviderProductId(offer.getProvider(), offer.getProviderProductId())
                    .orElse(new ProductOfferEntity());

            entity.setProvider(offer.getProvider());
            entity.setProviderProductId(offer.getProviderProductId());
            entity.setCanonicalProductId(canonicalId);
            entity.setProductName(offer.getProductName());
            entity.setBrand(offer.getBrand());
            entity.setDescription(offer.getDescription());
            entity.setPackageSize(offer.getPackageSize());
            entity.setUnit(offer.getUnit());
            entity.setProductUrl(offer.getProductUrl());
            entity.setAffiliateUrl(offer.getAffiliateUrl());
            entity.setImageUrl(offer.getImageUrl());
            entity.setPrice(offer.getPrice());
            entity.setDeliveryCharge(offer.getDeliveryCharge());
            entity.setEffectivePrice(offer.getEffectivePrice());
            entity.setCurrency(offer.getCurrency());
            entity.setAvailability(offer.getAvailability());
            entity.setEstimatedDelivery(offer.getEstimatedDelivery());
            entity.setRating(offer.getRating());
            entity.setReviewCount(offer.getReviewCount());
            entity.setMatchConfidence(offer.getMatchConfidence());
            entity.setLastCheckedAt(now);

            offerRepository.save(entity);

            // Record price history snapshot
            PriceHistory history = PriceHistory.builder()
                    .provider(offer.getProvider())
                    .providerProductId(offer.getProviderProductId())
                    .productName(offer.getProductName())
                    .price(offer.getPrice())
                    .deliveryCharge(offer.getDeliveryCharge())
                    .effectivePrice(offer.getEffectivePrice())
                    .currency(offer.getCurrency())
                    .recordedAt(now)
                    .build();
            priceHistoryRepository.save(history);
        }

        log.debug("[PriceCache] Cached {} offers for canonical ID: {}", offers.size(), canonicalId);
    }

    /**
     * Check if a specific offer is still fresh.
     */
    public boolean isFresh(Instant lastCheckedAt) {
        if (lastCheckedAt == null) return false;
        return lastCheckedAt.plus(Duration.ofMinutes(cacheTtlMinutes)).isAfter(Instant.now());
    }

    private ProductOfferDto entityToDto(ProductOfferEntity entity) {
        return ProductOfferDto.builder()
                .provider(entity.getProvider())
                .providerProductId(entity.getProviderProductId())
                .productName(entity.getProductName())
                .brand(entity.getBrand())
                .description(entity.getDescription())
                .imageUrl(entity.getImageUrl())
                .productUrl(entity.getProductUrl())
                .affiliateUrl(entity.getAffiliateUrl())
                .price(entity.getPrice())
                .currency(entity.getCurrency())
                .deliveryCharge(entity.getDeliveryCharge())
                .effectivePrice(entity.getEffectivePrice())
                .availability(entity.getAvailability())
                .estimatedDelivery(entity.getEstimatedDelivery())
                .packageSize(entity.getPackageSize())
                .unit(entity.getUnit())
                .rating(entity.getRating())
                .reviewCount(entity.getReviewCount())
                .matchConfidence(entity.getMatchConfidence())
                .lastCheckedAt(entity.getLastCheckedAt())
                .fromCache(true)
                .build();
    }
}
