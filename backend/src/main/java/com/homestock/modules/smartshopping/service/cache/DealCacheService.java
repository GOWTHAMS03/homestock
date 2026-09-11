package com.homestock.modules.smartshopping.service.cache;

import com.homestock.modules.smartshopping.dto.ProductDealSearchResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * High-performance concurrent cache with TTL for deals search queries.
 */
@Service
public class DealCacheService {

    private static final Logger log = LoggerFactory.getLogger(DealCacheService.class);

    @Value("${app.smart-shopping.cache.ttl-seconds:900}")
    private long ttlSeconds = 900; // 15 minutes default

    private final Map<String, CacheEntry> cache = new ConcurrentHashMap<>();

    public Optional<ProductDealSearchResponse> get(String cacheKey) {
        CacheEntry entry = cache.get(cacheKey);
        if (entry == null) {
            return Optional.empty();
        }

        if (Instant.now().isAfter(entry.expiresAt())) {
            cache.remove(cacheKey);
            log.debug("[DealCacheService] Cache entry expired for key '{}'", cacheKey);
            return Optional.empty();
        }

        log.debug("[DealCacheService] Cache hit for key '{}'", cacheKey);
        return Optional.of(entry.response());
    }

    public void put(String cacheKey, ProductDealSearchResponse response) {
        if (cacheKey == null || response == null) return;
        Instant expiresAt = Instant.now().plusSeconds(ttlSeconds);
        cache.put(cacheKey, new CacheEntry(response, expiresAt));
        log.debug("[DealCacheService] Cached deals response for key '{}', expires at {}", cacheKey, expiresAt);
    }

    public void evict(String cacheKey) {
        cache.remove(cacheKey);
    }

    public void clear() {
        cache.clear();
    }

    private record CacheEntry(ProductDealSearchResponse response, Instant expiresAt) {}
}
