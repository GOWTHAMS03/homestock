package com.homestock.modules.dashboard.service;

import com.homestock.core.redis.RedisResilienceService;
import com.homestock.modules.dashboard.dto.DashboardSummaryDto;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Optional;
import java.util.UUID;

/**
 * Cache-aside service for Dashboard summaries.
 * Aggregated dashboard statistics (low stock, expiring soon, pending shopping) are cached
 * with a 5-minute TTL and immediately invalidated on any inventory, stock, or shopping mutation,
 * guaranteeing zero stale inventory data.
 */
@Service
@RequiredArgsConstructor
public class DashboardCacheService {

    private static final Logger log = LoggerFactory.getLogger(DashboardCacheService.class);
    private static final String CACHE_NAME = "dashboard";
    private static final String KEY_PREFIX = "homestock:dashboard:summary:";

    private final RedisResilienceService resilienceService;

    @Value("${app.redis.cache.dashboard-ttl-seconds:300}")
    private long ttlSeconds = 300;

    public Optional<DashboardSummaryDto> get(UUID homeId) {
        if (homeId == null) {
            return Optional.empty();
        }
        String key = KEY_PREFIX + homeId;
        return resilienceService.get(key, DashboardSummaryDto.class, CACHE_NAME);
    }

    public void put(UUID homeId, DashboardSummaryDto summary) {
        if (homeId == null || summary == null) {
            return;
        }
        String key = KEY_PREFIX + homeId;
        resilienceService.set(key, summary, Duration.ofSeconds(ttlSeconds), CACHE_NAME);
        log.debug("Cached dashboard summary for home: {} (TTL: {}s)", homeId, ttlSeconds);
    }

    /**
     * Immediately evicts the cached dashboard summary for the given home.
     * Must be invoked on any inventory mutation, stock update, shopping item change, or purchase.
     */
    public void evict(UUID homeId) {
        if (homeId == null) {
            return;
        }
        String key = KEY_PREFIX + homeId;
        resilienceService.delete(key, CACHE_NAME);
        log.debug("Evicted dashboard summary cache for home: {}", homeId);
    }
}
