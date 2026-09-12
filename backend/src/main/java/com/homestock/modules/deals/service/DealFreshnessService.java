package com.homestock.modules.deals.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;

/**
 * Manages configuration-driven TTL and freshness rules for deals.
 * Phase 7 — Price Freshness / TTL.
 */
@Service
public class DealFreshnessService {

    @Value("${deals.ttl.active-seconds:60}")
    private long activeTtlSeconds = 60;

    @Value("${deals.ttl.shopping-list-seconds:180}")
    private long shoppingListTtlSeconds = 180;

    @Value("${deals.ttl.popular-seconds:600}")
    private long popularTtlSeconds = 600;

    @Value("${deals.ttl.default-seconds:1800}")
    private long defaultTtlSeconds = 1800;

    public enum PriorityContext {
        ACTIVE_VIEW,
        SHOPPING_LIST,
        POPULAR,
        DEFAULT
    }

    public long getTtlSeconds(PriorityContext context) {
        return switch (context) {
            case ACTIVE_VIEW -> activeTtlSeconds;
            case SHOPPING_LIST -> shoppingListTtlSeconds;
            case POPULAR -> popularTtlSeconds;
            case DEFAULT -> defaultTtlSeconds;
        };
    }

    public Instant calculateExpiration(PriorityContext context) {
        return Instant.now().plusSeconds(getTtlSeconds(context));
    }

    public boolean isFresh(Instant lastVerifiedAt, PriorityContext context) {
        if (lastVerifiedAt == null) return false;
        Instant cutoff = Instant.now().minusSeconds(getTtlSeconds(context));
        return lastVerifiedAt.isAfter(cutoff);
    }

    public String formatFreshnessLabel(Instant lastVerifiedAt) {
        if (lastVerifiedAt == null) return "Unknown";
        long seconds = Duration.between(lastVerifiedAt, Instant.now()).getSeconds();
        if (seconds < 60) {
            return seconds + " sec ago";
        }
        long minutes = seconds / 60;
        if (minutes < 60) {
            return minutes + " min ago";
        }
        long hours = minutes / 60;
        return hours + " hr ago";
    }
}
