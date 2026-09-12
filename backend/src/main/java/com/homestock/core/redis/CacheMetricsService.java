package com.homestock.core.redis;

import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Tags;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

/**
 * Observability service tracking Redis cache hit/miss rates, fallbacks to PostgreSQL,
 * distributed lock operations, and rate limiting actions.
 */
@Service
public class CacheMetricsService {

    private final MeterRegistry meterRegistry;

    @Autowired
    public CacheMetricsService(@Autowired(required = false) MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
    }

    public void recordHit(String cacheName) {
        if (meterRegistry != null) {
            meterRegistry.counter("homestock.cache.hit", Tags.of("cache", cacheName)).increment();
        }
    }

    public void recordMiss(String cacheName) {
        if (meterRegistry != null) {
            meterRegistry.counter("homestock.cache.miss", Tags.of("cache", cacheName)).increment();
        }
    }

    public void recordFallback(String cacheName, String reason) {
        if (meterRegistry != null) {
            meterRegistry.counter("homestock.cache.fallback",
                    Tags.of("cache", cacheName, "reason", reason)).increment();
        }
    }

    public void recordLock(String resource, boolean acquired) {
        if (meterRegistry != null) {
            String metric = acquired ? "homestock.lock.acquired" : "homestock.lock.failed";
            meterRegistry.counter(metric, Tags.of("resource", resource)).increment();
        }
    }

    public void recordRateLimit(String endpoint, boolean allowed) {
        if (meterRegistry != null) {
            String metric = allowed ? "homestock.ratelimit.allowed" : "homestock.ratelimit.rejected";
            meterRegistry.counter(metric, Tags.of("endpoint", endpoint)).increment();
        }
    }
}
