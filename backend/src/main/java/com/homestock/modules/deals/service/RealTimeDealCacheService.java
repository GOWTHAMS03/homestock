package com.homestock.modules.deals.service;

import com.homestock.core.redis.RedisResilienceService;
import com.homestock.modules.deals.dto.DealSearchResponseDto;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Optional;

/**
 * Short-lived Redis Cache-Aside service for real-time deal search queries (15m TTL).
 * Prevents redundant external price scraping and high CPU matching load.
 */
@Service("realTimeDealCacheService")
@RequiredArgsConstructor
public class RealTimeDealCacheService {

    private static final Logger log = LoggerFactory.getLogger(RealTimeDealCacheService.class);
    private static final String CACHE_NAME = "deals";
    private static final String KEY_PREFIX = "homestock:deals:search:";

    private final RedisResilienceService resilienceService;

    @Value("${app.redis.cache.deals-ttl-seconds:900}")
    private long ttlSeconds;

    public Optional<DealSearchResponseDto> getDeals(String query) {
        if (query == null || query.isBlank()) {
            return Optional.empty();
        }
        String normalizedKey = KEY_PREFIX + query.trim().toLowerCase().replaceAll("\\s+", "_");
        return resilienceService.get(normalizedKey, DealSearchResponseDto.class, CACHE_NAME);
    }

    public void putDeals(String query, DealSearchResponseDto response) {
        if (query == null || query.isBlank() || response == null) {
            return;
        }
        String normalizedKey = KEY_PREFIX + query.trim().toLowerCase().replaceAll("\\s+", "_");
        resilienceService.set(normalizedKey, response, Duration.ofSeconds(ttlSeconds), CACHE_NAME);
        log.debug("Cached deals response for query: {} (TTL: {}s)", query, ttlSeconds);
    }
}
