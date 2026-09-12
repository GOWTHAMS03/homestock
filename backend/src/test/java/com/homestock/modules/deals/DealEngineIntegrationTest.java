package com.homestock.modules.deals;

import com.homestock.modules.deals.adapter.DealSourceAdapter;
import com.homestock.modules.deals.adapter.DealSourceAdapterRegistry;
import com.homestock.modules.deals.dto.CanonicalDealDto;
import com.homestock.modules.deals.dto.DealSearchResponseDto;
import com.homestock.modules.deals.entity.DealEntity;
import com.homestock.modules.deals.model.*;
import com.homestock.modules.deals.repository.DealPriceHistoryRepository;
import com.homestock.modules.deals.repository.DealRepository;
import com.homestock.modules.deals.service.*;
import com.homestock.modules.smartshopping.engine.identity.BrandResolver;
import com.homestock.modules.smartshopping.engine.identity.ProductTaxonomy;
import com.homestock.modules.smartshopping.engine.intent.ProductNormalizer;
import com.homestock.modules.smartshopping.engine.matching.FuzzySimilarityEngine;
import com.homestock.modules.smartshopping.provider.ProductSearchRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@DisplayName("RealTimeDealEngine Integration Tests")
class DealEngineIntegrationTest {

    private RealTimeDealEngine dealEngine;
    private DealRepository dealRepository;
    private DealPriceHistoryRepository priceHistoryRepository;
    private DealSourceAdapter mockAmazonAdapter;
    private DealSourceAdapter mockFlipkartAdapter;

    @BeforeEach
    void setUp() {
        FuzzySimilarityEngine fuzzy = new FuzzySimilarityEngine();
        ProductNormalizer normalizer = new ProductNormalizer();
        BrandResolver brandResolver = new BrandResolver(fuzzy);
        ProductTaxonomy taxonomy = new ProductTaxonomy();

        ProductQueryNormalizationService normalizationService = new ProductQueryNormalizationService(normalizer, brandResolver, taxonomy);
        ProductMatchingEngine matchingEngine = new ProductMatchingEngine(fuzzy);
        FinalPriceCalculationService priceCalculationService = new FinalPriceCalculationService();
        DealFreshnessService freshnessService = new DealFreshnessService();
        DealScoringEngine scoringEngine = new DealScoringEngine();

        dealRepository = Mockito.mock(DealRepository.class);
        priceHistoryRepository = Mockito.mock(DealPriceHistoryRepository.class);

        when(dealRepository.save(any(DealEntity.class))).thenAnswer(invocation -> {
            DealEntity entity = invocation.getArgument(0);
            if (entity.getId() == null) {
                entity.setId(UUID.randomUUID());
            }
            return entity;
        });

        DealValidationService validationService = new DealValidationService(dealRepository, priceHistoryRepository, freshnessService);

        mockAmazonAdapter = Mockito.mock(DealSourceAdapter.class);
        when(mockAmazonAdapter.getSource()).thenReturn(DealSource.AMAZON);
        when(mockAmazonAdapter.isEnabled()).thenReturn(true);

        mockFlipkartAdapter = Mockito.mock(DealSourceAdapter.class);
        when(mockFlipkartAdapter.getSource()).thenReturn(DealSource.FLIPKART);
        when(mockFlipkartAdapter.isEnabled()).thenReturn(true);

        DealSourceAdapterRegistry adapterRegistry = new DealSourceAdapterRegistry(List.of(mockAmazonAdapter, mockFlipkartAdapter));

        dealEngine = new RealTimeDealEngine(
                normalizationService,
                adapterRegistry,
                matchingEngine,
                priceCalculationService,
                validationService,
                scoringEngine,
                freshnessService,
                dealRepository
        );
    }

    @Test
    @DisplayName("End-to-End: Search 'Fortune Sunflower Oil 1L' returns canonical card merging Flipkart & Amazon, rejecting 5L & Rice Bran")
    void testEndToEndDealsSearchAndDeduplication() {
        // Amazon returns 1L Sunflower Oil (₹189) and 5L Sunflower Oil (₹890)
        ExternalProduct amz1L = ExternalProduct.builder()
                .source(DealSource.AMAZON)
                .externalProductId("AMZ-SUN-1L")
                .title("Fortune Sunlite Refined Sunflower Oil 1L Pouch")
                .brand("Fortune")
                .category("Cooking Oil")
                .variant("Sunflower")
                .quantity(new BigDecimal("1000"))
                .unit("ML")
                .packCount(1)
                .price(new BigDecimal("189.00"))
                .productUrl("https://www.amazon.in/dp/B00OIL1L")
                .availability("IN_STOCK")
                .build();

        ExternalProduct amz5L = ExternalProduct.builder()
                .source(DealSource.AMAZON)
                .externalProductId("AMZ-SUN-5L")
                .title("Fortune Sunlite Refined Sunflower Oil 5L Jar")
                .brand("Fortune")
                .category("Cooking Oil")
                .variant("Sunflower")
                .quantity(new BigDecimal("5000"))
                .unit("ML")
                .packCount(1)
                .price(new BigDecimal("890.00"))
                .productUrl("https://www.amazon.in/dp/B00OIL5L")
                .availability("IN_STOCK")
                .build();

        when(mockAmazonAdapter.searchProducts(any(ProductSearchRequest.class)))
                .thenReturn(List.of(amz1L, amz5L));

        // Flipkart returns 1L Sunflower Oil (₹182 - cheapest) and 1L Rice Bran Oil (₹175)
        ExternalProduct fk1L = ExternalProduct.builder()
                .source(DealSource.FLIPKART)
                .externalProductId("FK-SUN-1L")
                .title("Fortune Sunflower Oil - 1 L Pouch")
                .brand("Fortune")
                .category("Cooking Oil")
                .variant("Sunflower")
                .quantity(new BigDecimal("1000"))
                .unit("ML")
                .packCount(1)
                .price(new BigDecimal("182.00"))
                .productUrl("https://www.flipkart.com/dp/FK00OIL1L")
                .availability("IN_STOCK")
                .build();

        ExternalProduct fkRiceBran = ExternalProduct.builder()
                .source(DealSource.FLIPKART)
                .externalProductId("FK-RB-1L")
                .title("Fortune Rice Bran Health Oil 1L")
                .brand("Fortune")
                .category("Cooking Oil")
                .variant("Rice Bran")
                .quantity(new BigDecimal("1000"))
                .unit("ML")
                .packCount(1)
                .price(new BigDecimal("175.00"))
                .productUrl("https://www.flipkart.com/dp/FK00RICE1L")
                .availability("IN_STOCK")
                .build();

        when(mockFlipkartAdapter.searchProducts(any(ProductSearchRequest.class)))
                .thenReturn(List.of(fk1L, fkRiceBran));

        // Execute search
        DealSearchResponseDto response = dealEngine.searchDeals(
                "Fortune Sunflower Oil 1L", DealFreshnessService.PriorityContext.ACTIVE_VIEW);

        assertNotNull(response);
        assertEquals(1, response.getExactDeals().size(), "Only the 1L Sunflower Oil should be in exact deals");

        CanonicalDealDto canonical = response.getExactDeals().get(0);
        assertTrue(canonical.isExactMatch());
        // Best price is Flipkart ₹182
        assertEquals(0, new BigDecimal("182.00").compareTo(canonical.getBestFinalPrice()));
        assertEquals(DealSource.FLIPKART, canonical.getBestSource());
        assertEquals("https://www.flipkart.com/dp/FK00OIL1L", canonical.getBestProductUrl());

        // Multi-store offers merged underneath canonical item (Phase 18)
        assertEquals(2, canonical.getOtherStores().size(), "Both Flipkart and Amazon offers should be grouped");
        assertTrue(canonical.getOtherStores().stream().anyMatch(s -> s.getSource() == DealSource.FLIPKART && s.isBestPrice()));
        assertTrue(canonical.getOtherStores().stream().anyMatch(s -> s.getSource() == DealSource.AMAZON && !s.isBestPrice()));

        // Verification that 5L and Rice Bran were NOT included in exact deals
        assertFalse(response.getExactDeals().stream().anyMatch(d -> "Rice Bran".equalsIgnoreCase(d.getVariant())),
                "Rice Bran must NOT be in exact deals for Sunflower Oil");
        assertFalse(response.getExactDeals().stream().anyMatch(d -> d.getQuantity() != null && d.getQuantity().compareTo(new BigDecimal("5000")) == 0),
                "5L must NOT be in exact deals for 1L requested product");
    }
}
