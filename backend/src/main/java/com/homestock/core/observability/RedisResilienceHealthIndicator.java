package com.homestock.core.observability;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.data.redis.connection.RedisConnection;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.stereotype.Component;

/**
 * Health check indicator for Redis caching and distributed locking.
 * Reports UP if connected, or DEGRADED_RESILIENT when graceful PostgreSQL fallback is active.
 */
@Component("redisHealthIndicator")
public class RedisResilienceHealthIndicator implements HealthIndicator {

    @Autowired(required = false)
    private RedisConnectionFactory connectionFactory;

    @Override
    public Health health() {
        if (connectionFactory == null) {
            return Health.up()
                    .withDetail("redis", "DISABLED")
                    .withDetail("fallback", "PostgreSQL Authoritative Storage Active")
                    .build();
        }

        try (RedisConnection connection = connectionFactory.getConnection()) {
            String ping = connection.ping();
            return Health.up()
                    .withDetail("redis", "AVAILABLE")
                    .withDetail("pingResponse", ping)
                    .withDetail("mode", "CACHE_AND_LOCKING_ACTIVE")
                    .build();
        } catch (Exception ex) {
            return Health.up()
                    .withDetail("redis", "DEGRADED")
                    .withDetail("fallback", "Graceful PostgreSQL Fallback Active")
                    .withDetail("reason", ex.getMessage() != null ? ex.getMessage() : "Connection refused")
                    .build();
        }
    }
}
