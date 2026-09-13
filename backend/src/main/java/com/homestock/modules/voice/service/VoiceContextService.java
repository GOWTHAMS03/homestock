package com.homestock.modules.voice.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.homestock.modules.voice.config.VoiceProperties;
import com.homestock.modules.voice.dto.VoiceIntent;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
public class VoiceContextService {

    private final VoiceProperties voiceProperties;
    private final ObjectMapper objectMapper;
    private final StringRedisTemplate redisTemplate;

    // In-memory fallback if Redis is unavailable or for tests
    private final Map<String, VoiceContext> inMemoryContexts = new ConcurrentHashMap<>();
    private volatile long redisDisabledUntilEpochMs = 0;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class VoiceContext {
        private UUID homeId;
        private UUID userId;
        private VoiceIntent pendingIntent;
        private String pendingProduct;
        private String target;
        private String missingField; // "QUANTITY" or "PRODUCT"
        private long createdAtEpochMs;

        public boolean isExpired(int timeoutSeconds) {
            return (System.currentTimeMillis() - createdAtEpochMs) > (timeoutSeconds * 1000L);
        }
    }

    @Autowired
    public VoiceContextService(VoiceProperties voiceProperties,
                               ObjectMapper objectMapper,
                               @Autowired(required = false) StringRedisTemplate redisTemplate) {
        this.voiceProperties = voiceProperties;
        this.objectMapper = objectMapper;
        this.redisTemplate = redisTemplate;
    }

    public void saveContext(UUID userId, UUID homeId, VoiceContext context) {
        if (userId == null || homeId == null || context == null) return;

        context.setCreatedAtEpochMs(System.currentTimeMillis());
        String key = buildContextKey(userId, homeId);
        int timeoutSeconds = voiceProperties.getContext().getTimeoutSeconds();

        // Always save to memory first (instant)
        inMemoryContexts.put(key, context);

        // Attempt to persist in Redis if not circuit-broken
        if (redisTemplate != null && System.currentTimeMillis() > redisDisabledUntilEpochMs) {
            try {
                String json = objectMapper.writeValueAsString(context);
                redisTemplate.opsForValue().set(key, json, Duration.ofSeconds(timeoutSeconds));
            } catch (Exception e) {
                redisDisabledUntilEpochMs = System.currentTimeMillis() + 60_000L;
                log.warn("Failed to persist voice context in Redis, disabling Redis context calls for 60s: {}", e.getMessage());
            }
        }
    }

    public Optional<VoiceContext> getContext(UUID userId, UUID homeId) {
        if (userId == null || homeId == null) return Optional.empty();

        String key = buildContextKey(userId, homeId);
        int timeoutSeconds = voiceProperties.getContext().getTimeoutSeconds();

        // 1. Fast in-memory check first (0ms overhead)
        VoiceContext memCtx = inMemoryContexts.get(key);
        if (memCtx != null) {
            if (!memCtx.isExpired(timeoutSeconds)) {
                return Optional.of(memCtx);
            } else {
                inMemoryContexts.remove(key);
            }
        }

        // 2. Check Redis if available and not circuit-broken
        if (redisTemplate != null && System.currentTimeMillis() > redisDisabledUntilEpochMs) {
            try {
                String json = redisTemplate.opsForValue().get(key);
                if (json != null && !json.isBlank()) {
                    VoiceContext ctx = objectMapper.readValue(json, VoiceContext.class);
                    if (!ctx.isExpired(timeoutSeconds)) {
                        inMemoryContexts.put(key, ctx);
                        return Optional.of(ctx);
                    } else {
                        clearContext(userId, homeId);
                        return Optional.empty();
                    }
                }
            } catch (Exception e) {
                redisDisabledUntilEpochMs = System.currentTimeMillis() + 60_000L;
                log.debug("Redis getContext failed, disabling Redis context calls for 60s: {}", e.getMessage());
            }
        }

        return Optional.empty();
    }

    public void clearContext(UUID userId, UUID homeId) {
        if (userId == null || homeId == null) return;
        String key = buildContextKey(userId, homeId);

        inMemoryContexts.remove(key);
        if (redisTemplate != null && System.currentTimeMillis() > redisDisabledUntilEpochMs) {
            try {
                redisTemplate.delete(key);
            } catch (Exception e) {
                redisDisabledUntilEpochMs = System.currentTimeMillis() + 60_000L;
                log.debug("Redis clearContext failed: {}", e.getMessage());
            }
        }
    }

    private String buildContextKey(UUID userId, UUID homeId) {
        return "voice:context:" + userId + ":" + homeId;
    }
}

