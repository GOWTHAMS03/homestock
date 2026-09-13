package com.homestock.modules.deals.service;

import com.homestock.modules.deals.dto.NearbyShopDto;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * In-Memory Geospatial Cache for Nearby Shop Discovery.
 * Caches nearby POI query results using spatial rounded keys:
 * "lat_lon_radius" with a 15-minute TTL.
 * Avoids hammering public Overpass infrastructure on repeated screen openings or slight coordinate jitters.
 */
@Component
public class NearbyShopCache {

    private static final Logger log = LoggerFactory.getLogger(NearbyShopCache.class);
    private static final Duration DEFAULT_TTL = Duration.ofMinutes(15);

    private final Map<String, CacheEntry> cache = new ConcurrentHashMap<>();

    public record CacheEntry(List<NearbyShopDto> shops, Instant expiresAt) {
        public boolean isExpired() {
            return Instant.now().isAfter(expiresAt);
        }
    }

    /**
     * Generates a spatial cache key rounded to 3 decimal places (~110 meters precision).
     */
    public String generateKey(double latitude, double longitude, int radiusMeters) {
        return String.format(Locale.US, "%.3f_%.3f_%d", latitude, longitude, radiusMeters);
    }

    /**
     * Retrieve cached shops if key exists and is not expired.
     */
    public Optional<List<NearbyShopDto>> get(String key) {
        CacheEntry entry = cache.get(key);
        if (entry != null) {
            if (!entry.isExpired()) {
                log.debug("[NEARBY_CACHE] Cache HIT for key: {}", key);
                return Optional.of(entry.shops());
            } else {
                log.debug("[NEARBY_CACHE] Cache EXPIRED for key: {}", key);
                cache.remove(key);
            }
        }
        return Optional.empty();
    }

    /**
     * Store shops in cache with 15-minute validity.
     */
    public void put(String key, List<NearbyShopDto> shops) {
        put(key, shops, DEFAULT_TTL);
    }

    public void put(String key, List<NearbyShopDto> shops, Duration ttl) {
        if (key == null || shops == null) return;
        cache.put(key, new CacheEntry(new ArrayList<>(shops), Instant.now().plus(ttl)));
        log.debug("[NEARBY_CACHE] Cached {} shops under key: {} (TTL: {} mins)",
                shops.size(), key, ttl.toMinutes());
    }

    /**
     * Clear all cached entries (useful for testing or manual flush).
     */
    public void clear() {
        cache.clear();
    }

    /**
     * Returns the number of currently active entries in cache.
     */
    public int size() {
        // Evict expired entries during size calculation
        cache.entrySet().removeIf(e -> e.getValue().isExpired());
        return cache.size();
    }
}

