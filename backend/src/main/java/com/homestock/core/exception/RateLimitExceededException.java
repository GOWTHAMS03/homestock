package com.homestock.core.exception;

import lombok.Getter;

/**
 * Exception thrown when an API request exceeds the configured rate limit.
 * Maps to HTTP 429 Too Many Requests.
 */
@Getter
public class RateLimitExceededException extends RuntimeException {

    private final String keyPrefix;
    private final int limit;
    private final int windowSeconds;

    public RateLimitExceededException(String keyPrefix, int limit, int windowSeconds) {
        super(String.format("Rate limit exceeded for %s. Limit is %d requests per %d seconds. Please slow down.",
                keyPrefix, limit, windowSeconds));
        this.keyPrefix = keyPrefix;
        this.limit = limit;
        this.windowSeconds = windowSeconds;
    }
}
