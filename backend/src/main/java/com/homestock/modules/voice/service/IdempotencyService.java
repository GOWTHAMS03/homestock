package com.homestock.modules.voice.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.homestock.modules.voice.config.VoiceProperties;
import com.homestock.modules.voice.dto.ExecuteCommandResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
public class IdempotencyService {

    private final VoiceProperties voiceProperties;
    private final ObjectMapper objectMapper;
    private final StringRedisTemplate redisTemplate;

    // In-memory fallback
    private final Map<String, CacheEntry> inMemoryCache = new ConcurrentHashMap<>();

    private record CacheEntry(ExecuteCommandResponse response, long createdAtEpochMs) {
        public boolean isExpired(int ttlSeconds) {
            return (System.currentTimeMillis() - createdAtEpochMs) > (ttlSeconds * 1000L);
        }
    }

    @Autowired
    public IdempotencyService(VoiceProperties voiceProperties,
                              ObjectMapper objectMapper,
                              @Autowired(required = false) StringRedisTemplate redisTemplate) {
        this.voiceProperties = voiceProperties;
        this.objectMapper = objectMapper;
        this.redisTemplate = redisTemplate;
    }

    public String computeAudioHash(byte[] audioBytes) {
        if (audioBytes == null || audioBytes.length == 0) {
            return UUID.randomUUID().toString();
        }
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(audioBytes);
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (Exception e) {
            return UUID.randomUUID().toString();
        }
    }

    public Optional<ExecuteCommandResponse> getCachedResponse(String idempotencyKey) {
        if (idempotencyKey == null || idempotencyKey.isBlank()) {
            return Optional.empty();
        }

        String key = "voice:idem:" + idempotencyKey;
        int ttl = voiceProperties.getIdempotency().getWindowSeconds();

        // 1. Check Redis
        if (redisTemplate != null) {
            try {
                String json = redisTemplate.opsForValue().get(key);
                if (json != null && !json.isBlank()) {
                    ExecuteCommandResponse cached = objectMapper.readValue(json, ExecuteCommandResponse.class);
                    log.info("Idempotent duplicate command detected for key: {}", idempotencyKey);
                    return Optional.of(cached);
                }
            } catch (Exception e) {
                log.debug("Redis idempotency get failed: {}", e.getMessage());
            }
        }

        // 2. Check in-memory
        CacheEntry entry = inMemoryCache.get(key);
        if (entry != null) {
            if (!entry.isExpired(ttl)) {
                log.info("Idempotent duplicate command detected (in-memory) for key: {}", idempotencyKey);
                return Optional.of(entry.response);
            } else {
                inMemoryCache.remove(key);
            }
        }

        return Optional.empty();
    }

    public void cacheResponse(String idempotencyKey, ExecuteCommandResponse response) {
        if (idempotencyKey == null || idempotencyKey.isBlank() || response == null) {
            return;
        }

        String key = "voice:idem:" + idempotencyKey;
        int ttl = voiceProperties.getIdempotency().getWindowSeconds();

        inMemoryCache.put(key, new CacheEntry(response, System.currentTimeMillis()));

        if (redisTemplate != null) {
            try {
                String json = objectMapper.writeValueAsString(response);
                redisTemplate.opsForValue().set(key, json, Duration.ofSeconds(ttl));
            } catch (Exception e) {
                log.warn("Failed to cache idempotent voice response in Redis: {}", e.getMessage());
            }
        }
    }
}

