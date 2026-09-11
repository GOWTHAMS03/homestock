package com.homestock.modules.smartshopping;

import com.homestock.modules.smartshopping.dto.*;
import com.homestock.modules.smartshopping.engine.clustering.CanonicalProductClusterer;
import com.homestock.modules.smartshopping.engine.filter.HardConstraintFilter;
import com.homestock.modules.smartshopping.engine.identity.BrandResolver;
import com.homestock.modules.smartshopping.engine.identity.ProductAttributeExtractor;
import com.homestock.modules.smartshopping.engine.identity.ProductIdentityResolver;
import com.homestock.modules.smartshopping.engine.identity.ProductTaxonomy;
import com.homestock.modules.smartshopping.engine.matching.EvidenceScorer;
import com.homestock.modules.smartshopping.engine.matching.FuzzySimilarityEngine;
import com.homestock.modules.smartshopping.engine.matching.ProductIdentityMatcher;
import com.homestock.modules.smartshopping.engine.url.*;
import com.homestock.modules.smartshopping.provider.ShoppingProviderRegistry;
import com.homestock.modules.smartshopping.provider.real.RealMarketCatalogProvider;
import com.homestock.modules.smartshopping.service.ProductDealService;
import com.homestock.modules.smartshopping.service.anomaly.PriceAnomalyDetector;
import com.homestock.modules.smartshopping.service.cache.DealCacheService;
import com.homestock.modules.smartshopping.service.dedup.ProductDeduplicationService;
import com.homestock.modules.smartshopping.service.ranking.DealRankingService;
import com.homestock.modules.smartshopping.service.UnitNormalizationService;
import com.homestock.modules.smartshopping.service.search.MultiEngineSearchService;
import com.homestock.modules.smartshopping.service.verification.ImageVerificationService;
import com.homestock.modules.smartshopping.service.verification.PriceVerificationService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class ProductUrlResolverTest {

    private ProductUrlValidator validator;
    private DefaultProductUrlResolver resolver;

    @BeforeEach
    void setUp() {
        validator = new ProductUrlValidator();
        resolver = new DefaultProductUrlResolver(validator);
    }

    @Test
    @DisplayName("Section 43: Classify valid retailer direct PRODUCT_DETAIL_PAGE URLs")
    void testClassifyValidDetailPages() {
        // Amazon
        assertEquals(ProductUrlType.PRODUCT_DETAIL_PAGE,
                validator.classifyUrl("https://www.amazon.in/dp/B00TS88SVK"));
        assertEquals(ProductUrlType.PRODUCT_DETAIL_PAGE,
                validator.classifyUrl("https://www.amazon.in/Fortune-Sunlite-Refined-Sunflower-Oil/dp/B00TS88SVK"));

        // Flipkart
        assertEquals(ProductUrlType.PRODUCT_DETAIL_PAGE,
                validator.classifyUrl("https://www.flipkart.com/fortune-sunlite-sunflower-oil-1l/p/itm123456789"));
        assertEquals(ProductUrlType.PRODUCT_DETAIL_PAGE,
                validator.classifyUrl("https://www.flipkart.com/product/p/itm12345"));

        // Blinkit
        assertEquals(ProductUrlType.PRODUCT_DETAIL_PAGE,
                validator.classifyUrl("https://blinkit.com/prn/fortune-sunlite-refined-sunflower-oil/prid/24011"));

        // BigBasket
        assertEquals(ProductUrlType.PRODUCT_DETAIL_PAGE,
                validator.classifyUrl("https://www.bigbasket.com/pd/10000407/fortune-sunlite-sunflower-refined-oil-1-l-pouch/"));

        // JioMart
        assertEquals(ProductUrlType.PRODUCT_DETAIL_PAGE,
                validator.classifyUrl("https://www.jiomart.com/p/groceries/fortune-sunlite-refined-sunflower-oil-1-l/490001392"));

        // Zepto
        assertEquals(ProductUrlType.PRODUCT_DETAIL_PAGE,
                validator.classifyUrl("https://www.zeptonow.com/pn/fortune-sunlite-refined-sunflower-oil-1-l/pvid/z101"));
    }

    @Test
    @DisplayName("Section 41 & 43: Classify and REJECT generic SEARCH_PAGE URLs")
    void testRejectSearchPages() {
        String[] searchUrls = {
                "https://www.amazon.in/s?k=fortune+sunflower+oil",
                "https://www.flipkart.com/search?q=sunflower+oil",
                "https://blinkit.com/s/?q=fortune+sunflower+oil",
                "https://www.bigbasket.com/ps/?q=sunflower+oil",
                "https://www.jiomart.com/search/fortune+oil",
                "https://www.zeptonow.com/search?q=sunflower+oil"
        };

        for (String url : searchUrls) {
            assertEquals(ProductUrlType.SEARCH_PAGE, validator.classifyUrl(url),
                    "URL should be classified as SEARCH_PAGE: " + url);

            ProductUrlValidationResult res = validator.validateProductUrl(url, null);
            assertFalse(res.isUrlVerified(), "Search URL must never be verified: " + url);
            assertFalse(res.isDirectProductUrlAvailable(), "Direct link must be marked unavailable for search URL");
        }
    }

    @Test
    @DisplayName("Section 43: Classify and REJECT CATEGORY_PAGE, HOMEPAGE, and INVALID_URL")
    void testRejectCategoryAndHomepage() {
        assertEquals(ProductUrlType.HOMEPAGE, validator.classifyUrl("https://www.bigbasket.com/"));
        assertEquals(ProductUrlType.HOMEPAGE, validator.classifyUrl("https://www.jiomart.com"));
        assertEquals(ProductUrlType.CATEGORY_PAGE, validator.classifyUrl("https://www.jiomart.com/c/groceries/edible-oils/"));
        assertEquals(ProductUrlType.CATEGORY_PAGE, validator.classifyUrl("https://www.bigbasket.com/cl/fruits-vegetables/"));
        assertEquals(ProductUrlType.INVALID_URL, validator.classifyUrl("not-a-valid-url"));
        assertEquals(ProductUrlType.INVALID_URL, validator.classifyUrl(""));
    }

    @Test
    @DisplayName("Section 47: URL Canonicalization strips tracking query parameters")
    void testCanonicalizeUrlStripsTracking() {
        String dirtyAmazon = "https://www.amazon.in/Fortune-Oil/dp/B00TS88SVK?tag=affiliate-21&ref_=ast_sto_dp&utm_source=google&qid=123456";
        String cleanAmazon = validator.canonicalizeUrl(dirtyAmazon);
        assertEquals("https://www.amazon.in/dp/B00TS88SVK", cleanAmazon);

        String dirtyBlinkit = "https://blinkit.com/prn/fortune-oil/prid/24011?utm_medium=cpc&ref=homestock&session-id=999";
        String cleanBlinkit = validator.canonicalizeUrl(dirtyBlinkit);
        assertEquals("https://blinkit.com/prn/fortune-oil/prid/24011", cleanBlinkit);
    }

    @Test
    @DisplayName("Section 44: URL + Product Identity Consistency Check detects variant mismatch")
    void testVariantMismatchDetection() {
        ProductIdentity identity = ProductIdentity.builder()
                .product("Fortune Sunflower Oil 1L")
                .brand("Fortune")
                .variant("Sunflower")
                .packSize(new BigDecimal("1"))
                .packUnit("L")
                .build();

        // Matching URL
        String validUrl = "https://www.jiomart.com/p/groceries/fortune-sunlite-refined-sunflower-oil-1-l/490001392";
        ProductUrlValidationResult validRes = validator.validateProductUrl(validUrl, identity);
        assertTrue(validRes.isUrlVerified(), "Matching variant should be verified");
        assertTrue(validRes.getUrlConfidence() >= 0.90);

        // Conflicting Variant in URL slug (Groundnut instead of Sunflower)
        String conflictingVariantUrl = "https://www.jiomart.com/p/groceries/fortune-filter-groundnut-oil-1-l/490001399";
        ProductUrlValidationResult conflictRes = validator.validateProductUrl(conflictingVariantUrl, identity);
        assertFalse(conflictRes.isUrlVerified(), "Groundnut oil URL must be REJECTED for Sunflower oil request");
        assertFalse(conflictRes.isDirectProductUrlAvailable());
        assertTrue(conflictRes.getValidationMessage().toLowerCase().contains("variant conflict"));
    }

    @Test
    @DisplayName("Section 44: URL + Product Identity Consistency Check detects brand mismatch")
    void testBrandMismatchDetection() {
        ProductIdentity identity = ProductIdentity.builder()
                .product("Fortune Sunflower Oil 1L")
                .brand("Fortune")
                .variant("Sunflower")
                .build();

        // Conflicting Brand in URL slug (Dhara instead of Fortune)
        String conflictingBrandUrl = "https://blinkit.com/prn/dhara-refined-sunflower-oil/prid/99001";
        ProductUrlValidationResult conflictRes = validator.validateProductUrl(conflictingBrandUrl, identity);
        assertFalse(conflictRes.isUrlVerified(), "Dhara oil URL must be REJECTED for Fortune oil request");
        assertFalse(conflictRes.isDirectProductUrlAvailable());
        assertTrue(conflictRes.getValidationMessage().toLowerCase().contains("brand conflict"));
    }

    @Test
    @DisplayName("Section 51: Fallback when candidate has only search URL")
    void testSection51Fallback() {
        ProductCandidate cand = ProductCandidate.builder()
                .candidateId("TEST-01")
                .provider("TestStore")
                .productName("Unknown Local Oil")
                .productUrl("https://teststore.com/search?q=unknown+oil")
                .build();

        String resolved = resolver.resolveProductUrl(cand);
        assertNull(resolved, "Search URL must NOT be used as canonicalProductUrl");
        assertFalse(cand.isUrlVerified());
        assertFalse(cand.isDirectProductUrlAvailable());
        assertEquals(ProductUrlType.SEARCH_PAGE, cand.getUrlType());
    }

    @Test
    @DisplayName("Section 54: End-to-End Deal Search yields canonical product detail page URLs")
    void testEndToEndDirectProductDetailNavigation() {
        // Setup RealMarketCatalogProvider with verified real data
        RealMarketCatalogProvider realProvider = new RealMarketCatalogProvider();
        ReflectionTestUtils.setField(realProvider, "enabled", true);

        ShoppingProviderRegistry registry = new ShoppingProviderRegistry(List.of(realProvider));

        FuzzySimilarityEngine fuzzyEngine = new FuzzySimilarityEngine();
        BrandResolver brandResolver = new BrandResolver(fuzzyEngine);
        ProductTaxonomy taxonomy = new ProductTaxonomy();
        ProductAttributeExtractor attributeExtractor = new ProductAttributeExtractor(brandResolver, taxonomy);

        ProductIdentityResolver identityResolver = new ProductIdentityResolver(attributeExtractor);
        HardConstraintFilter filter = new HardConstraintFilter(brandResolver, attributeExtractor, taxonomy);
        EvidenceScorer scorer = new EvidenceScorer(fuzzyEngine, brandResolver, attributeExtractor);
        ProductIdentityMatcher identityMatcher = new ProductIdentityMatcher(filter, scorer);
        CanonicalProductClusterer clusterer = new CanonicalProductClusterer();
        com.homestock.modules.smartshopping.engine.intent.SearchQueryBuilder queryBuilder = new com.homestock.modules.smartshopping.engine.intent.SearchQueryBuilder();
        MultiEngineSearchService searchService = new MultiEngineSearchService(registry, queryBuilder);

        ProductDealService dealService = new ProductDealService(
                identityResolver,
                identityMatcher,
                clusterer,
                new com.homestock.modules.smartshopping.engine.intent.ProductIntentExtractor(
                        new com.homestock.modules.smartshopping.engine.intent.ProductNormalizer(),
                        new com.homestock.modules.smartshopping.engine.intent.SearchIntentClassifier()
                ),
                new com.homestock.modules.smartshopping.engine.intent.ProductNormalizer(),
                new com.homestock.modules.smartshopping.engine.intent.SearchIntentClassifier(),
                queryBuilder,
                searchService,
                new com.homestock.modules.smartshopping.engine.matching.ProductMatchEngine(),
                new ProductDeduplicationService(),
                new PriceVerificationService(),
                new ImageVerificationService(),
                new DealRankingService(new UnitNormalizationService()),
                new PriceAnomalyDetector(),
                new DealCacheService(),
                new com.homestock.modules.smartshopping.engine.ProductIntentEngine(),
                new com.homestock.modules.smartshopping.engine.AIRecommendationEngine(),
                null,
                resolver
        );

        // Run user request: "Fortune Sunflower Oil 1L"
        ProductDealSearchResponse response = dealService.searchDeals(null, "Fortune Sunflower Oil 1L", null, null, null, null, null, null, "default");

        assertNotNull(response);
        assertFalse(response.getDeals().isEmpty(), "Expected primary deals for Fortune Sunflower Oil 1L");

        ProductDealDto topDeal = response.getDeals().get(0);
        assertNotNull(topDeal.getCanonicalProductUrl(), "Canonical direct product detail URL must be present");
        assertTrue(topDeal.isUrlVerified(), "URL must be marked as verified");
        assertTrue(topDeal.isDirectProductUrlAvailable(), "Direct product URL must be available");
        assertEquals(ProductUrlType.PRODUCT_DETAIL_PAGE, topDeal.getUrlType());

        // CRITICAL CHECK (Section 41 & 55): The canonical URL must NEVER be a search page!
        String url = topDeal.getCanonicalProductUrl().toLowerCase();
        assertFalse(url.contains("/search"), "URL must NOT contain /search");
        assertFalse(url.contains("?q="), "URL must NOT contain ?q=");
        assertFalse(url.contains("/s?k="), "URL must NOT contain /s?k=");
        assertFalse(url.contains("/ps/?q="), "URL must NOT contain /ps/?q=");
        assertFalse(url.contains("/s/?q="), "URL must NOT contain /s/?q=");

        // Verify it points to an actual product detail endpoint
        assertTrue(url.contains("/p/") || url.contains("/pd/") || url.contains("/prn/") || url.contains("/dp/"),
                "URL must point to a retailer product detail path: " + topDeal.getCanonicalProductUrl());

        // Verify store offers also contain canonical direct URLs
        assertNotNull(topDeal.getStoreOffers());
        for (StoreOfferDto offer : topDeal.getStoreOffers()) {
            assertNotNull(offer.getCanonicalProductUrl());
            assertEquals(ProductUrlType.PRODUCT_DETAIL_PAGE, offer.getUrlType());
            assertTrue(offer.isUrlVerified());
        }
    }
}
