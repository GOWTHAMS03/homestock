package com.homestock.core.redis;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Duration;

/**
 * Distributed rate limiter using atomic Redis counters with TTL sliding windows.
 * Fails open (allows requests) when Redis is unreachable so legitimate users are not blocked.
 */
@Service
@RequiredArgsConstructor
public class RateLimitingService {

    private static final Logger log = LoggerFactory.getLogger(RateLimitingService.class);

    private final RedisResilienceService resilienceService;
    private final CacheMetricsService cacheMetricsService;

    @Value("${app.redis.rate-limit.enabled:true}")
    private boolean rateLimitEnabled = true;

    /**
     * Checks whether an action for the given client identifier is within the rate limit.
     *
     * @param keyPrefix     Prefix describing the endpoint category (e.g., "voice")
     * @param identifier    Client identifier (user ID or client IP)
     * @param limit         Max requests allowed
     * @param windowSeconds Window duration in seconds
     * @return true if request is permitted; false if rate limit exceeded
     */
    public boolean isAllowed(String keyPrefix, String identifier, int limit, int windowSeconds) {
        if (!rateLimitEnabled) {
            return true;
        }

        String key = String.format("homestock:ratelimit:%s:%s", keyPrefix, identifier);
        Long currentCount = resilienceService.incrementAndExpire(key, Duration.ofSeconds(windowSeconds));

        if (currentCount == null) {
            // Redis unavailable -> Fail open gracefully to keep services operational
            log.debug("Redis rate limiting unavailable for key '{}'. Failing open.", key);
            cacheMetricsService.recordRateLimit(keyPrefix, true);
            return true;
        }

        boolean allowed = currentCount <= limit;
        cacheMetricsService.recordRateLimit(keyPrefix, allowed);

        if (!allowed) {
            log.warn("Rate limit exceeded for client '{}' on '{}'. Count: {} / Limit: {}",
                    identifier, keyPrefix, currentCount, limit);
        }

        return allowed;
    }
}
