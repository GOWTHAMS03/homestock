package com.homestock.modules.smartshopping;

import com.homestock.modules.smartshopping.dto.*;
import com.homestock.modules.smartshopping.engine.clustering.CanonicalProductClusterer;
import com.homestock.modules.smartshopping.engine.filter.HardConstraintFilter;
import com.homestock.modules.smartshopping.engine.identity.BrandResolver;
import com.homestock.modules.smartshopping.engine.identity.ProductAttributeExtractor;
import com.homestock.modules.smartshopping.engine.identity.ProductIdentityResolver;
import com.homestock.modules.smartshopping.engine.identity.ProductTaxonomy;
import com.homestock.modules.smartshopping.engine.intent.SearchQueryBuilder;
import com.homestock.modules.smartshopping.engine.matching.EvidenceScorer;
import com.homestock.modules.smartshopping.engine.matching.FuzzySimilarityEngine;
import com.homestock.modules.smartshopping.engine.matching.ProductIdentityMatcher;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * End-to-End Test Suite for Product Identity Resolution & Search Mechanism
 * Verifying all 10 core scenarios from Section 39 of the Specification.
 */
class ProductSearchResolutionTest {

    private ProductIdentityResolver identityResolver;
    private ProductIdentityMatcher identityMatcher;
    private CanonicalProductClusterer clusterer;
    private SearchQueryBuilder queryBuilder;

    @BeforeEach
    void setUp() {
        FuzzySimilarityEngine fuzzyEngine = new FuzzySimilarityEngine();
        BrandResolver brandResolver = new BrandResolver(fuzzyEngine);
        ProductTaxonomy taxonomy = new ProductTaxonomy();
        ProductAttributeExtractor attributeExtractor = new ProductAttributeExtractor(brandResolver, taxonomy);

        this.identityResolver = new ProductIdentityResolver(attributeExtractor);
        HardConstraintFilter filter = new HardConstraintFilter(brandResolver, attributeExtractor, taxonomy);
        EvidenceScorer scorer = new EvidenceScorer(fuzzyEngine, brandResolver, attributeExtractor);
        this.identityMatcher = new ProductIdentityMatcher(filter, scorer);
        this.clusterer = new CanonicalProductClusterer();
        this.queryBuilder = new SearchQueryBuilder();
    }

    @Test
    @DisplayName("Scenario 1: Fortune Sunflower Oil 1L - Exact branded search rejects wrong variant, wrong brand, wrong pack size")
    void testScenario1_FortuneSunflowerOil1L() {
        // 1. Resolve Identity
        ProductIdentity identity = identityResolver.resolve("Fortune Sunflower Oil 1L", null);
        assertEquals("Fortune", identity.getBrand());
        assertEquals("Sunflower", identity.getVariant());
        assertEquals(0, BigDecimal.valueOf(1000.0).compareTo(identity.getNormalizedPackSizeValue()));
        assertEquals("ML", identity.getNormalizedPackSizeUnit());
        assertEquals(SearchIntent.EXACT_PRODUCT, identity.getSearchMode());

        // 2. Candidates across engines
        ProductCandidate exact = ProductCandidate.builder()
                .productName("Fortune Sunlite Refined Sunflower Oil 1L Pouch")
                .brand("Fortune")
                .packageSize("1L")
                .price(BigDecimal.valueOf(145.0))
                .provider("Blinkit")
                .build();

        ProductCandidate wrongVariant = ProductCandidate.builder()
                .productName("Fortune Filtered Groundnut Oil 1L")
                .brand("Fortune")
                .packageSize("1L")
                .price(BigDecimal.valueOf(180.0))
                .provider("Zepto")
                .build();

        ProductCandidate wrongBrand = ProductCandidate.builder()
                .productName("Dhara Refined Sunflower Oil 1L")
                .brand("Dhara")
                .packageSize("1L")
                .price(BigDecimal.valueOf(135.0))
                .provider("Instamart")
                .build();

        ProductCandidate wrongPackSize = ProductCandidate.builder()
                .productName("Fortune Sunlite Refined Sunflower Oil 500ml")
                .brand("Fortune")
                .packageSize("500ml")
                .price(BigDecimal.valueOf(78.0))
                .provider("Amazon")
                .build();

        ProductIdentityMatcher.MatchResult matchResult = identityMatcher.matchCandidates(
                identity, List.of(exact, wrongVariant, wrongBrand, wrongPackSize));

        // Verify Rejections
        assertEquals(1, matchResult.getValidCandidates().size());
        assertEquals(3, matchResult.getRejectedCandidates().size());

        assertTrue(matchResult.getRejectedCandidates().stream()
                .anyMatch(r -> r.getCandidateTitle().contains("Groundnut") && r.getRejectionReason() == RejectionReason.WRONG_VARIANT));
        assertTrue(matchResult.getRejectedCandidates().stream()
                .anyMatch(r -> r.getCandidateTitle().contains("Dhara") && r.getRejectionReason() == RejectionReason.WRONG_BRAND));
        assertTrue(matchResult.getRejectedCandidates().stream()
                .anyMatch(r -> r.getCandidateTitle().contains("500ml") && r.getRejectionReason() == RejectionReason.WRONG_PACK_SIZE));

        // Verify clustering
        CanonicalProductClusterer.ClusteringResult clustered = clusterer.clusterAndRank(identity, matchResult.getValidCandidates());
        assertEquals(1, clustered.getPrimaryDeals().size());
        assertEquals("Fortune", clustered.getPrimaryDeals().get(0).getBrand());
        assertEquals(145.0, clustered.getPrimaryDeals().get(0).getBestPrice().doubleValue());
    }

    @Test
    @DisplayName("Scenario 2: Surf Excel Matic Front Load 2kg - Multi-word brand & variant matching")
    void testScenario2_SurfExcelMaticFrontLoad2kg() {
        ProductIdentity identity = identityResolver.resolve("Surf Excel Matic Front Load 2kg", null);
        assertEquals("Surf Excel", identity.getBrand());
        assertEquals("Matic Front Load", identity.getVariant());
        assertEquals(0, BigDecimal.valueOf(2000.0).compareTo(identity.getNormalizedPackSizeValue()));
        assertEquals("G", identity.getNormalizedPackSizeUnit());

        ProductCandidate exact = ProductCandidate.builder()
                .productName("Surf Excel Matic Front Load Detergent Powder 2 kg")
                .brand("Surf Excel")
                .packageSize("2kg")
                .price(BigDecimal.valueOf(420.0))
                .provider("Flipkart")
                .build();

        ProductCandidate wrongVariant = ProductCandidate.builder()
                .productName("Surf Excel Matic Top Load Detergent Powder 2 kg")
                .brand("Surf Excel")
                .packageSize("2kg")
                .price(BigDecimal.valueOf(390.0))
                .provider("Zepto")
                .build();

        ProductCandidate wrongBrand = ProductCandidate.builder()
                .productName("Ariel Matic Front Load Detergent Powder 2 kg")
                .brand("Ariel")
                .packageSize("2kg")
                .price(BigDecimal.valueOf(410.0))
                .provider("Blinkit")
                .build();

        ProductIdentityMatcher.MatchResult matchResult = identityMatcher.matchCandidates(
                identity, List.of(exact, wrongVariant, wrongBrand));

        assertEquals(1, matchResult.getValidCandidates().size());
        assertEquals("Surf Excel", matchResult.getValidCandidates().get(0).getCanonicalBrand());
        assertEquals(2, matchResult.getRejectedCandidates().size());
    }

    @Test
    @DisplayName("Scenario 3: Tata Salt 1kg - Essential staple matching and brand protection")
    void testScenario3_TataSalt1kg() {
        ProductIdentity identity = identityResolver.resolve("Tata Salt 1kg", null);
        assertEquals("Tata", identity.getBrand());
        assertEquals(0, BigDecimal.valueOf(1000.0).compareTo(identity.getNormalizedPackSizeValue()));

        ProductCandidate exact = ProductCandidate.builder()
                .productName("Tata Salt Vacuum Evaporated Iodised Salt 1 kg")
                .brand("Tata")
                .packageSize("1kg")
                .price(BigDecimal.valueOf(28.0))
                .provider("BigBasket")
                .build();

        ProductCandidate wrongBrand = ProductCandidate.builder()
                .productName("Aashirvaad Iodised Crystal Salt 1 kg")
                .brand("Aashirvaad")
                .packageSize("1kg")
                .price(BigDecimal.valueOf(25.0))
                .provider("Zepto")
                .build();

        ProductIdentityMatcher.MatchResult matchResult = identityMatcher.matchCandidates(
                identity, List.of(exact, wrongBrand));

        assertEquals(1, matchResult.getValidCandidates().size());
        assertEquals(1, matchResult.getRejectedCandidates().size());
        assertEquals(RejectionReason.WRONG_BRAND, matchResult.getRejectedCandidates().get(0).getRejectionReason());
    }

    @Test
    @DisplayName("Scenario 4: Sunflower oil 1L - Generic query allows multiple brands, rejects other oil variants")
    void testScenario4_GenericSunflowerOil1L() {
        ProductIdentity identity = identityResolver.resolve("Sunflower oil 1L", null);
        assertNull(identity.getBrand()); // Generic query: no brand forced
        assertEquals("Sunflower", identity.getVariant());
        assertFalse(identity.getConstraints().isBrandRequired());

        ProductCandidate fortune = ProductCandidate.builder()
                .productName("Fortune Sunflower Oil 1L")
                .brand("Fortune")
                .packageSize("1L")
                .price(BigDecimal.valueOf(140.0))
                .provider("Zepto")
                .build();

        ProductCandidate freedom = ProductCandidate.builder()
                .productName("Freedom Refined Sunflower Oil 1L")
                .brand("Freedom")
                .packageSize("1L")
                .price(BigDecimal.valueOf(138.0))
                .provider("Blinkit")
                .build();

        ProductCandidate groundnut = ProductCandidate.builder()
                .productName("Fortune Groundnut Oil 1L")
                .brand("Fortune")
                .packageSize("1L")
                .price(BigDecimal.valueOf(190.0))
                .provider("Amazon")
                .build();

        ProductIdentityMatcher.MatchResult matchResult = identityMatcher.matchCandidates(
                identity, List.of(fortune, freedom, groundnut));

        // Both Sunflower oils accepted, Groundnut oil rejected for variant clash
        assertEquals(2, matchResult.getValidCandidates().size());
        assertEquals(1, matchResult.getRejectedCandidates().size());
        assertEquals(RejectionReason.WRONG_VARIANT, matchResult.getRejectedCandidates().get(0).getRejectionReason());
    }

    @Test
    @DisplayName("Scenario 5: Aashirvaad Atta 5kg - Atta staple matching with pack size verification")
    void testScenario5_AashirvaadAtta5kg() {
        ProductIdentity identity = identityResolver.resolve("Aashirvaad Atta 5kg", null);
        assertEquals("Aashirvaad", identity.getBrand());
        assertEquals(0, BigDecimal.valueOf(5000.0).compareTo(identity.getNormalizedPackSizeValue()));

        ProductCandidate exact = ProductCandidate.builder()
                .productName("Aashirvaad Shudh Chakki Atta 5 kg")
                .brand("Aashirvaad")
                .packageSize("5kg")
                .price(BigDecimal.valueOf(255.0))
                .provider("Instamart")
                .build();

        ProductCandidate wrongBrand = ProductCandidate.builder()
                .productName("Pillsbury Chakki Fresh Atta 5 kg")
                .brand("Pillsbury")
                .packageSize("5kg")
                .price(BigDecimal.valueOf(240.0))
                .provider("Zepto")
                .build();

        ProductCandidate wrongSize = ProductCandidate.builder()
                .productName("Aashirvaad Shudh Chakki Atta 10 kg")
                .brand("Aashirvaad")
                .packageSize("10kg")
                .price(BigDecimal.valueOf(480.0))
                .provider("Amazon")
                .build();

        ProductIdentityMatcher.MatchResult matchResult = identityMatcher.matchCandidates(
                identity, List.of(exact, wrongBrand, wrongSize));

        assertEquals(1, matchResult.getValidCandidates().size());
        assertEquals(2, matchResult.getRejectedCandidates().size());
    }

    @Test
    @DisplayName("Scenario 6: Dettol soap 125g pack of 3 - Multi-pack count detection")
    void testScenario6_DettolSoapMultiPack() {
        ProductIdentity identity = identityResolver.resolve("Dettol soap 125g pack of 3", null);
        assertEquals("Dettol", identity.getBrand());

        ProductCandidate exact = ProductCandidate.builder()
                .productName("Dettol Original Bathing Soap Bar 125g (Pack of 3)")
                .brand("Dettol")
                .packageSize("125g pack of 3")
                .price(BigDecimal.valueOf(160.0))
                .provider("Blinkit")
                .build();

        ProductCandidate wrongBrand = ProductCandidate.builder()
                .productName("Lifebuoy Total Soap 125g Pack of 3")
                .brand("Lifebuoy")
                .packageSize("125g pack of 3")
                .price(BigDecimal.valueOf(130.0))
                .provider("Zepto")
                .build();

        ProductIdentityMatcher.MatchResult matchResult = identityMatcher.matchCandidates(
                identity, List.of(exact, wrongBrand));

        assertEquals(1, matchResult.getValidCandidates().size());
        assertEquals(1, matchResult.getRejectedCandidates().size());
        assertEquals(RejectionReason.WRONG_BRAND, matchResult.getRejectedCandidates().get(0).getRejectionReason());
    }

    @Test
    @DisplayName("Scenario 7: Toothpaste - Broad generic search")
    void testScenario7_ToothpasteGeneric() {
        ProductIdentity identity = identityResolver.resolve("Toothpaste", null);
        assertNull(identity.getBrand());
        assertEquals("Personal Care", identity.getCategory());
        assertFalse(identity.getConstraints().isBrandRequired());
    }

    @Test
    @DisplayName("Scenario 8: Fortune Sunflower Oil 1L 2 bottles - Pack size vs requested quantity separation")
    void testScenario8_PackSizeVsQuantity() {
        ProductIdentity identity = identityResolver.resolve("Fortune Sunflower Oil 1L 2 bottles", null);
        assertEquals("Fortune", identity.getBrand());
        assertEquals("Sunflower", identity.getVariant());
        assertEquals(0, BigDecimal.valueOf(1000.0).compareTo(identity.getNormalizedPackSizeValue()));
        assertEquals(0, BigDecimal.valueOf(2).compareTo(identity.getRequestedQuantity()));
        assertEquals("bottle", identity.getRequestedQuantityUnit());

        ProductCandidate candidate = ProductCandidate.builder()
                .productName("Fortune Sunlite Refined Sunflower Oil 1L")
                .brand("Fortune")
                .packageSize("1L")
                .price(BigDecimal.valueOf(140.0))
                .provider("Blinkit")
                .build();

        ProductIdentityMatcher.MatchResult matchResult = identityMatcher.matchCandidates(
                identity, List.of(candidate));
        assertEquals(1, matchResult.getValidCandidates().size());

        CanonicalProductClusterer.ClusteringResult clustered = clusterer.clusterAndRank(identity, matchResult.getValidCandidates());
        assertEquals(1, clustered.getPrimaryDeals().size());

        ProductDealDto deal = clustered.getPrimaryDeals().get(0);
        assertEquals(140.0, deal.getEffectivePrice().doubleValue());
        // Required quantity cost = 140 * 2 = 280.0
        assertEquals(280.0, deal.getRequiredQuantityCost().doubleValue());
    }

    @Test
    @DisplayName("Scenario 9: Ennai 1L - Regional Tamil translation to Cooking Oil")
    void testScenario9_RegionalTamilTranslation() {
        ProductIdentity identity = identityResolver.resolve("Ennai 1L", null);
        assertEquals("Cooking Oil", identity.getCategory());
        assertEquals(0, BigDecimal.valueOf(1000.0).compareTo(identity.getNormalizedPackSizeValue()));
        assertEquals("ML", identity.getNormalizedPackSizeUnit());
    }

    @Test
    @DisplayName("Scenario 10: Barcode Search 8901030383792 - 100% confidence verified identity")
    void testScenario10_BarcodeSearch() {
        String barcode = "8901030383792";
        ProductIdentity identity = identityResolver.resolve("", barcode);
        assertEquals(barcode, identity.getBarcode());
        assertEquals(SearchIntent.BARCODE_SEARCH, identity.getSearchMode());
        assertTrue(identity.getConstraints().isBarcodeRequired());

        ProductCandidate matching = ProductCandidate.builder()
                .productName("Surf Excel Easy Wash Detergent Powder 1kg")
                .barcode(barcode)
                .price(BigDecimal.valueOf(140.0))
                .provider("Blinkit")
                .build();

        ProductCandidate mismatching = ProductCandidate.builder()
                .productName("Ariel Complete 1kg")
                .barcode("8901030999999")
                .price(BigDecimal.valueOf(135.0))
                .provider("Zepto")
                .build();

        ProductIdentityMatcher.MatchResult matchResult = identityMatcher.matchCandidates(
                identity, List.of(matching, mismatching));

        assertEquals(1, matchResult.getValidCandidates().size());
        assertEquals(1, matchResult.getRejectedCandidates().size());
        assertEquals(RejectionReason.BARCODE_MISMATCH, matchResult.getRejectedCandidates().get(0).getRejectionReason());

        ProductCandidate verified = matchResult.getValidCandidates().get(0);
        assertEquals(MatchStatus.VERIFIED_EXACT, verified.getMatchStatus());
        assertNotNull(verified.getEvidence());
        assertEquals(1, verified.getEvidence().getSourceAgreement());
    }
}
