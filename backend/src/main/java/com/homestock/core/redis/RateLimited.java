package com.homestock.core.redis;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Annotation to enforce Redis-backed distributed rate limiting on sensitive or resource-intensive endpoints.
 */
@Target({ElementType.METHOD, ElementType.TYPE})
@Retention(RetentionPolicy.RUNTIME)
public @interface RateLimited {

    /**
     * Identifying category for the rate limit bucket (e.g. "voice", "deals", "barcode", "auth").
     */
    String keyPrefix();

    /**
     * Maximum allowed requests in the given window.
     */
    int limit();

    /**
     * Time window in seconds (defaults to 60 seconds).
     */
    int windowSeconds() default 60;
}
