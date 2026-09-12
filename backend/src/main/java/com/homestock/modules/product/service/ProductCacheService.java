package com.homestock.modules.product.service;

import com.homestock.core.redis.RedisResilienceService;
import com.homestock.modules.product.dto.ProductDto;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Optional;
import java.util.UUID;

/**
 * Cache-aside service for frequently accessed canonical product catalog data.
 * Product details (name, brand, package size, unit) rarely change, so a 24-hour TTL
 * drastically reduces repeated database and external provider lookups.
 */
@Service
@RequiredArgsConstructor
public class ProductCacheService {

    private static final Logger log = LoggerFactory.getLogger(ProductCacheService.class);
    private static final String CACHE_NAME = "product";
    private static final String KEY_PREFIX_ID = "homestock:product:id:";
    private static final String KEY_PREFIX_BARCODE = "homestock:product:barcode:";

    private final RedisResilienceService resilienceService;

    @Value("${app.redis.cache.product-ttl-seconds:86400}")
    private long ttlSeconds = 86400;

    public Optional<ProductDto> getById(UUID id) {
        if (id == null) {
            return Optional.empty();
        }
        return resilienceService.get(KEY_PREFIX_ID + id, ProductDto.class, CACHE_NAME);
    }

    public Optional<ProductDto> getByBarcode(String barcode) {
        if (barcode == null || barcode.isBlank()) {
            return Optional.empty();
        }
        return resilienceService.get(KEY_PREFIX_BARCODE + barcode.trim(), ProductDto.class, CACHE_NAME);
    }

    public void put(ProductDto product) {
        if (product == null) {
            return;
        }

        Duration ttl = Duration.ofSeconds(ttlSeconds);
        if (product.getId() != null) {
            resilienceService.set(KEY_PREFIX_ID + product.getId(), product, ttl, CACHE_NAME);
        }
        if (product.getBarcode() != null && !product.getBarcode().isBlank()) {
            resilienceService.set(KEY_PREFIX_BARCODE + product.getBarcode().trim(), product, ttl, CACHE_NAME);
        }
        log.debug("Cached product in Redis: id={}, barcode={}", product.getId(), product.getBarcode());
    }

    public void evict(UUID id, String barcode) {
        if (id != null) {
            resilienceService.delete(KEY_PREFIX_ID + id, CACHE_NAME);
        }
        if (barcode != null && !barcode.isBlank()) {
            resilienceService.delete(KEY_PREFIX_BARCODE + barcode.trim(), CACHE_NAME);
        }
        log.debug("Evicted product cache: id={}, barcode={}", id, barcode);
    }
}
