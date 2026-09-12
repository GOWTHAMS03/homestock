package com.homestock.core.redis;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.RedisScript;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Resilient Redis service that wraps Redis interactions with circuit-breaking,
 * throttled error logging, metrics tracking, and graceful fallback to PostgreSQL.
 */
@Service
@RequiredArgsConstructor
public class RedisResilienceService {

    private static final Logger log = LoggerFactory.getLogger(RedisResilienceService.class);
    private static final long LOG_THROTTLE_INTERVAL_MS = 30_000L; // 30 seconds

    private final RedisTemplate<String, Object> redisTemplate;
    private final StringRedisTemplate stringRedisTemplate;
    private final CacheMetricsService cacheMetricsService;

    @Value("${app.redis.enabled:true}")
    private boolean redisEnabled = true;

    // Track last logged warning time to prevent console log flooding when Redis is offline
    private final Map<String, AtomicLong> lastWarningTimeMap = new ConcurrentHashMap<>();

    public boolean isRedisEnabled() {
        return redisEnabled;
    }

    /**
     * Resilient GET: Attempts to fetch and cast cached object.
     * Returns empty if missing, disabled, or if Redis is unreachable.
     */
    @SuppressWarnings("unchecked")
    public <T> Optional<T> get(String key, Class<T> clazz, String cacheName) {
        if (!redisEnabled) {
            return Optional.empty();
        }

        try {
            Object val = redisTemplate.opsForValue().get(key);
            if (val != null) {
                cacheMetricsService.recordHit(cacheName);
                if (clazz.isInstance(val)) {
                    return Optional.of((T) val);
                }
            } else {
                cacheMetricsService.recordMiss(cacheName);
            }
            return Optional.empty();
        } catch (Exception ex) {
            logThrottledWarning("get", cacheName, ex);
            cacheMetricsService.recordFallback(cacheName, "read_failure");
            return Optional.empty();
        }
    }

    /**
     * Resilient SET with TTL.
     * Fails silently if Redis is unreachable, ensuring database operations succeed.
     */
    public void set(String key, Object value, Duration ttl, String cacheName) {
        if (!redisEnabled || value == null) {
            return;
        }

        try {
            redisTemplate.opsForValue().set(key, value, ttl);
        } catch (Exception ex) {
            logThrottledWarning("set", cacheName, ex);
            cacheMetricsService.recordFallback(cacheName, "write_failure");
        }
    }

    /**
     * Resilient DELETE: Evicts cache key immediately.
     */
    public void delete(String key, String cacheName) {
        if (!redisEnabled) {
            return;
        }

        try {
            redisTemplate.delete(key);
        } catch (Exception ex) {
            logThrottledWarning("delete", cacheName, ex);
            cacheMetricsService.recordFallback(cacheName, "evict_failure");
        }
    }

    /**
     * Resilient multi-key eviction by pattern.
     */
    public void deletePattern(String pattern, String cacheName) {
        if (!redisEnabled) {
            return;
        }

        try {
            Set<String> keys = stringRedisTemplate.keys(pattern);
            if (keys != null && !keys.isEmpty()) {
                stringRedisTemplate.delete(keys);
            }
        } catch (Exception ex) {
            logThrottledWarning("deletePattern", cacheName, ex);
            cacheMetricsService.recordFallback(cacheName, "evict_pattern_failure");
        }
    }

    /**
     * Atomic SETNX with PX TTL for distributed lock acquisition.
     */
    public Boolean setIfAbsent(String key, String value, Duration ttl) {
        if (!redisEnabled) {
            return null;
        }

        try {
            return stringRedisTemplate.opsForValue().setIfAbsent(key, value, ttl);
        } catch (Exception ex) {
            logThrottledWarning("setIfAbsent", "lock", ex);
            return null;
        }
    }

    /**
     * Execute Redis Script (e.g. Lua script for safe lock release).
     */
    public <T> T executeScript(RedisScript<T> script, List<String> keys, Object... args) {
        if (!redisEnabled) {
            return null;
        }

        try {
            return stringRedisTemplate.execute(script, keys, args);
        } catch (Exception ex) {
            logThrottledWarning("executeScript", "lock", ex);
            return null;
        }
    }

    /**
     * Resilient increment with TTL for sliding/rolling rate limiter counters.
     * Returns null if Redis is unavailable (allowing fail-open behavior).
     */
    public Long incrementAndExpire(String key, Duration window) {
        if (!redisEnabled) {
            return null;
        }

        try {
            Long count = stringRedisTemplate.opsForValue().increment(key);
            if (count != null && count == 1L) {
                stringRedisTemplate.expire(key, window);
            }
            return count;
        } catch (Exception ex) {
            logThrottledWarning("incrementAndExpire", "ratelimit", ex);
            return null;
        }
    }

    private void logThrottledWarning(String operation, String cacheName, Exception ex) {
        String logKey = operation + ":" + cacheName;
        AtomicLong lastLogged = lastWarningTimeMap.computeIfAbsent(logKey, k -> new AtomicLong(0));
        long now = System.currentTimeMillis();
        long previous = lastLogged.get();

        if (now - previous > LOG_THROTTLE_INTERVAL_MS) {
            if (lastLogged.compareAndSet(previous, now)) {
                log.warn("Redis unavailable or error during {} for cache '{}'. Falling back to PostgreSQL gracefully. Cause: {}",
                        operation, cacheName, ex.getMessage());
            }
        }
    }
}
