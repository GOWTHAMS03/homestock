package com.homestock.modules.smartshopping;

import com.homestock.modules.smartshopping.dto.ProductDealSearchResponse;
import com.homestock.modules.smartshopping.service.cache.DealCacheService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

class DealCacheServiceTest {

    private DealCacheService cacheService;

    @BeforeEach
    void setUp() {
        cacheService = new DealCacheService();
        ReflectionTestUtils.setField(cacheService, "ttlSeconds", 60L);
    }

    @Test
    @DisplayName("Requirement 20: Cache store and retrieval with TTL")
    void testCacheHitAndMiss() {
        String key = "test-key";
        ProductDealSearchResponse response = ProductDealSearchResponse.builder().message("Success").build();

        // Initially empty
        Optional<ProductDealSearchResponse> miss = cacheService.get(key);
        assertTrue(miss.isEmpty());

        // Put in cache
        cacheService.put(key, response);

        // Hit
        Optional<ProductDealSearchResponse> hit = cacheService.get(key);
        assertTrue(hit.isPresent());
        assertEquals("Success", hit.get().getMessage());

        // Evict
        cacheService.evict(key);
        assertTrue(cacheService.get(key).isEmpty());
    }
}
