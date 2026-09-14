package com.homestock.modules.deals.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.homestock.core.redis.RedisResilienceService;
import com.homestock.modules.deals.dto.NearbyShopDto;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.*;

/**
 * Unified Resilient Cache Service for Nearby Shops.
 * Orchestrates Redis (optional acceleration layer) with In-Memory fallback.
 * Operates flawlessly and quietly when Redis is offline.
 */
@Service
public class ShopCacheService {

    private static final Logger log = LoggerFactory.getLogger(ShopCacheService.class);
    private static final String CACHE_PREFIX = "shops:grid:";

    private final RedisResilienceService redisResilienceService;
    private final NearbyShopCache inMemoryCache;
    private final ObjectMapper objectMapper;

    @Value("${app.redis.cache.nearby-shops-ttl-seconds:1800}")
    private long redisTtlSeconds = 1800; // 30 minutes

    @Autowired
    public ShopCacheService(RedisResilienceService redisResilienceService,
                            NearbyShopCache inMemoryCache,
                            ObjectMapper objectMapper) {
        this.redisResilienceService = redisResilienceService;
        this.inMemoryCache = inMemoryCache != null ? inMemoryCache : new NearbyShopCache();
        this.objectMapper = objectMapper != null ? objectMapper : new ObjectMapper();
    }

    public ShopCacheService(NearbyShopCache inMemoryCache) {
        this(null, inMemoryCache, new ObjectMapper());
    }

    /**
     * Retrieve cached shops by grid key. Checks Redis first (if enabled), then in-memory cache.
     */
    public Optional<List<NearbyShopDto>> get(String gridKey) {
        if (gridKey == null || gridKey.isBlank()) {
            return Optional.empty();
        }

        // 1. Try Redis if enabled
        if (redisResilienceService != null && redisResilienceService.isRedisEnabled()) {
            try {
                Optional<Object> rawVal = redisResilienceService.get(CACHE_PREFIX + gridKey, Object.class, "nearby_shops");
                if (rawVal.isPresent()) {
                    List<NearbyShopDto> deserialized = objectMapper.convertValue(
                            rawVal.get(), new TypeReference<List<NearbyShopDto>>() {});
                    log.debug("[SHOP_CACHE] Redis HIT for grid: {}", gridKey);
                    return Optional.of(deserialized);
                }
            } catch (Exception e) {
                log.debug("[SHOP_CACHE] Redis read bypassed for grid {}: {}", gridKey, e.getMessage());
            }
        }

        // 2. Fall back to In-Memory cache
        Optional<List<NearbyShopDto>> memHit = inMemoryCache.get(gridKey);
        if (memHit.isPresent()) {
            log.debug("[SHOP_CACHE] In-Memory HIT for grid: {}", gridKey);
            return memHit;
        }

        return Optional.empty();
    }

    /**
     * Stores shops in both Redis (if enabled) and in-memory cache.
     */
    public void put(String gridKey, List<NearbyShopDto> shops) {
        if (gridKey == null || shops == null) return;

        // In-memory cache store
        inMemoryCache.put(gridKey, shops, Duration.ofSeconds(redisTtlSeconds));

        // Redis store (if enabled)
        if (redisResilienceService != null && redisResilienceService.isRedisEnabled()) {
            try {
                redisResilienceService.set(
                        CACHE_PREFIX + gridKey,
                        shops,
                        Duration.ofSeconds(redisTtlSeconds),
                        "nearby_shops"
                );
                log.debug("[SHOP_CACHE] Stored {} shops in Redis for grid: {}", shops.size(), gridKey);
            } catch (Exception e) {
                log.debug("[SHOP_CACHE] Failed writing to Redis for grid {}: {}", gridKey, e.getMessage());
            }
        }
    }

    /**
     * Invalidate cached data for a grid key across all cache tiers.
     */
    public void evict(String gridKey) {
        if (gridKey == null) return;

        inMemoryCache.clear(); // Or specific key if supported

        if (redisResilienceService != null && redisResilienceService.isRedisEnabled()) {
            try {
                redisResilienceService.delete(CACHE_PREFIX + gridKey, "nearby_shops");
            } catch (Exception ignored) {
            }
        }
    }

    public void clear() {
        inMemoryCache.clear();
        if (redisResilienceService != null && redisResilienceService.isRedisEnabled()) {
            try {
                redisResilienceService.deletePattern(CACHE_PREFIX + "*", "nearby_shops");
            } catch (Exception ignored) {
            }
        }
    }
}
