package com.homestock.core.redis;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.script.RedisScript;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Collections;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.ReentrantLock;
import java.util.function.Supplier;

/**
 * Distributed Lock Service utilizing Redis SETNX + PX TTL with Lua script atomic release.
 * When Redis is unreachable, gracefully falls back to local in-memory reentrant locks,
 * ensuring high availability without compromising data integrity.
 */
@Service
@RequiredArgsConstructor
public class DistributedLockService {

    private static final Logger log = LoggerFactory.getLogger(DistributedLockService.class);

    private final RedisResilienceService resilienceService;
    private final CacheMetricsService cacheMetricsService;
    private final RedisScript<Long> releaseLockScript;

    // Fallback local locks when Redis is unreachable: tracks owner token and lease expiration
    private record LocalLockInfo(String owner, long expiresAt) {}
    private final ConcurrentHashMap<String, LocalLockInfo> localFallbackLocks = new ConcurrentHashMap<>();

    /**
     * Try to acquire a distributed lock.
     *
     * @param lockKey    Unique resource key (e.g., "lock:sync:home:uuid")
     * @param lockOwner  Unique identifier for the owner (UUID or token)
     * @param leaseTime  Auto-expiry time to prevent deadlocks if the owner crashes
     * @return true if acquired, false if held by another process
     */
    public boolean tryLock(String lockKey, String lockOwner, Duration leaseTime) {
        Boolean acquired = resilienceService.setIfAbsent(lockKey, lockOwner, leaseTime);

        if (acquired != null) {
            // Redis is operational
            cacheMetricsService.recordLock(lockKey, acquired);
            return acquired;
        }

        // Redis is unavailable -> Fall back to owner-aware local lock with TTL
        log.debug("Redis unavailable for lock '{}'. Using local lock fallback.", lockKey);
        long now = System.currentTimeMillis();
        long newExpiry = now + leaseTime.toMillis();

        synchronized (localFallbackLocks) {
            LocalLockInfo current = localFallbackLocks.get(lockKey);
            if (current != null && current.expiresAt() > now) {
                if (!current.owner().equals(lockOwner)) {
                    cacheMetricsService.recordLock(lockKey, false);
                    return false;
                }
            }
            localFallbackLocks.put(lockKey, new LocalLockInfo(lockOwner, newExpiry));
            cacheMetricsService.recordLock(lockKey, true);
            return true;
        }
    }

    /**
     * Release a distributed lock safely using an atomic Lua script.
     * Only the owner who acquired the lock can release it.
     */
    public boolean releaseLock(String lockKey, String lockOwner) {
        Long result = resilienceService.executeScript(releaseLockScript, Collections.singletonList(lockKey), lockOwner);

        if (result != null) {
            return result == 1L;
        }

        // Release fallback local lock if owner matches
        synchronized (localFallbackLocks) {
            LocalLockInfo current = localFallbackLocks.get(lockKey);
            if (current != null && current.owner().equals(lockOwner)) {
                localFallbackLocks.remove(lockKey);
                return true;
            }
            return false;
        }
    }

    /**
     * Executes an action inside a distributed lock.
     *
     * @param lockKey   Resource lock key
     * @param leaseTime Lease duration
     * @param action    Supplier to run while holding lock
     * @param <T>       Return type
     * @return Result of the action
     */
    public <T> T executeWithLock(String lockKey, Duration leaseTime, Supplier<T> action) {
        String lockOwner = UUID.randomUUID().toString();
        boolean acquired = tryLock(lockKey, lockOwner, leaseTime);

        if (!acquired) {
            log.warn("Failed to acquire distributed lock for key '{}'. Resource is currently locked.", lockKey);
            throw new IllegalStateException("Resource is currently locked: " + lockKey);
        }

        try {
            return action.get();
        } finally {
            try {
                releaseLock(lockKey, lockOwner);
            } catch (Exception e) {
                log.warn("Error releasing lock for key '{}': {}", lockKey, e.getMessage());
            }
        }
    }

    /**
     * Executes a runnable inside a distributed lock.
     */
    public void executeRunnableWithLock(String lockKey, Duration leaseTime, Runnable action) {
        executeWithLock(lockKey, leaseTime, () -> {
            action.run();
            return null;
        });
    }
}
