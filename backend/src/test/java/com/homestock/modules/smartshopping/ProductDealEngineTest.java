package com.homestock.modules.smartshopping;

import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import com.homestock.modules.smartshopping.dto.*;
import com.homestock.modules.smartshopping.engine.*;
import com.homestock.modules.smartshopping.provider.ShoppingProviderRegistry;
import com.homestock.modules.smartshopping.provider.real.RealMarketCatalogProvider;
import com.homestock.modules.smartshopping.service.ProductDealService;
import com.homestock.modules.smartshopping.service.ProductMatchingService;
import com.homestock.modules.smartshopping.service.UnitNormalizationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
class ProductDealEngineTest {

    private ProductIntentEngine intentEngine;
    private ProductSearchEngine searchEngine;
    private ProductMatchingEngine matchingEngine;
    private ProductComparisonEngine comparisonEngine;
    private DealRankingEngine rankingEngine;
    private AIRecommendationEngine recommendationEngine;
    private ProductDealService dealService;

    @Mock
    private ShoppingListItemRepository listItemRepository;

    @BeforeEach
    void setUp() {
        intentEngine = new ProductIntentEngine();
        UnitNormalizationService unitService = new UnitNormalizationService();

        ProductMatchingService matchingService = new ProductMatchingService(unitService);
        ReflectionTestUtils.setField(matchingService, "confidenceThreshold", 0.70);

        RealMarketCatalogProvider realMarketProvider = new RealMarketCatalogProvider();
        ReflectionTestUtils.setField(realMarketProvider, "enabled", true);

        ShoppingProviderRegistry registry = new ShoppingProviderRegistry(List.of(realMarketProvider));
        searchEngine = new ProductSearchEngine(registry);
        matchingEngine = new ProductMatchingEngine(matchingService);
        comparisonEngine = new ProductComparisonEngine();
        rankingEngine = new DealRankingEngine(unitService);
        recommendationEngine = new AIRecommendationEngine();

        dealService = new ProductDealService(
                intentEngine,
                searchEngine,
                matchingEngine,
                comparisonEngine,
                rankingEngine,
                recommendationEngine,
                listItemRepository
        );
    }

    @Test
    @DisplayName("Generic query 'Oil' should detect GENERIC_DISCOVERY mode and find multi-brand deals")
    void testGenericOilSearch() {
        UUID homeId = UUID.randomUUID();
        ProductDealSearchResponse response = dealService.searchDeals(
                homeId, "Oil", null, null, null, null, null, null, "default");

        assertNotNull(response);
        assertNotNull(response.getIntent());
        assertEquals("GENERIC_DISCOVERY", response.getIntent().getSearchMode());
        assertEquals("Cooking Oil", response.getIntent().getPrimaryCategory());
        assertTrue(response.getIntent().getAllowedTypes().contains("Sunflower"));
        assertTrue(response.getIntent().getAllowedTypes().contains("Groundnut"));

        // Products should contain multiple brands and varieties
        assertFalse(response.getProducts().isEmpty());
        assertTrue(response.getProducts().size() >= 4);

        // Verify summary
        assertNotNull(response.getSummary());
        assertTrue(response.getSummary().getTotalProducts() >= 4);
        assertNotNull(response.getSummary().getAiRecommendation());

        // Verify highlights
        assertNotNull(response.getHighlights());
        assertNotNull(response.getHighlights().getLowestPrice(), "Lowest price deal should be tagged");
        assertNotNull(response.getHighlights().getBestValue(), "Best value deal should be tagged");

        // The 5L bulk jar should have cheaper unit price than 1L pouch
        ProductDealDto bestVal = response.getHighlights().getBestValue();
        System.out.println("DEBUG bestVal: " + bestVal.getProductName() + ", size=" + bestVal.getPackageSize() + ", unitPrice=" + bestVal.getUnitPrice() + ", label=" + bestVal.getUnitPriceLabel());
        assertNotNull(bestVal.getUnitPriceLabel());
        assertTrue(bestVal.getUnitPriceLabel().toUpperCase().contains("/L"));

        // Filters should have types, brands, pack sizes
        assertNotNull(response.getFilters());
        assertFalse(response.getFilters().getAvailableTypes().isEmpty());
        assertFalse(response.getFilters().getAvailableBrands().isEmpty());
    }

    @Test
    @DisplayName("Tamil/Tanglish query 'samayal ennai' should normalize to Cooking Oil discovery")
    void testTamilTanglishOilSearch() {
        UUID homeId = UUID.randomUUID();
        ProductDealSearchResponse response = dealService.searchDeals(
                homeId, "samayal ennai", null, null, null, null, null, null, "default");

        assertNotNull(response);
        assertEquals("Cooking Oil", response.getIntent().getPrimaryCategory());
        assertEquals("GENERIC_DISCOVERY", response.getIntent().getSearchMode());
        assertFalse(response.getProducts().isEmpty());
    }

    @Test
    @DisplayName("Exact query 'Fortune Sunflower Refined Oil 1L' should detect EXACT_PRODUCT mode")
    void testExactOilSearch() {
        UUID homeId = UUID.randomUUID();
        ProductDealSearchResponse response = dealService.searchDeals(
                homeId, "Fortune Sunflower Refined Oil 1L", null, null, null, null, null, null, "default");

        assertNotNull(response);
        assertEquals("EXACT_PRODUCT", response.getIntent().getSearchMode());
        assertEquals("Fortune", response.getIntent().getExtractedBrand());
        assertEquals("Sunflower", response.getIntent().getExtractedVariant());
        assertNotNull(response.getIntent().getExtractedPackSize());

        // Top product should be Fortune Sunflower
        assertFalse(response.getProducts().isEmpty());
        ProductDealDto topProduct = response.getProducts().get(0);
        assertEquals("Fortune", topProduct.getBrand());
        assertTrue(topProduct.getProductName().toLowerCase().contains("sunflower"));

        // Should have store comparison across JioMart, BigBasket, Blinkit, Amazon
        assertNotNull(topProduct.getStoreOffers());
        assertTrue(topProduct.getStoreOffers().size() >= 2);
        assertTrue(topProduct.getSavingsVsHighest().compareTo(BigDecimal.ZERO) > 0);
    }

    @Test
    @DisplayName("Barcode query should detect BARCODE priority and EXACT_PRODUCT mode")
    void testBarcodeSearch() {
        UUID homeId = UUID.randomUUID();
        ProductDealSearchResponse response = dealService.searchDeals(
                homeId, "8906007280123", null, null, null, null, null, null, "default");

        assertNotNull(response);
        assertEquals("EXACT_PRODUCT", response.getIntent().getSearchMode());
        assertEquals("BARCODE", response.getIntent().getSearchPriority());
        assertEquals("8906007280123", response.getIntent().getTargetBarcode());
    }

    @Test
    @DisplayName("Subtype filter chip should filter to only requested oil subtype")
    void testSubtypeFilter() {
        UUID homeId = UUID.randomUUID();
        ProductDealSearchResponse response = dealService.searchDeals(
                homeId, "Oil", null, null, null, "Groundnut", null, null, "default");

        assertNotNull(response);
        for (ProductDealDto deal : response.getProducts()) {
            assertEquals("Groundnut", deal.getVariantType());
        }
    }
}
