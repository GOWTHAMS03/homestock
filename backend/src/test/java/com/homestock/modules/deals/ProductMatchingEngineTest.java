package com.homestock.modules.deals;

import com.homestock.modules.deals.model.DealCandidateInput;
import com.homestock.modules.deals.model.DealMatchCategory;
import com.homestock.modules.deals.model.NormalizedProductQuery;
import com.homestock.modules.deals.model.ProductMatchResult;
import com.homestock.modules.deals.service.ProductMatchingEngine;
import com.homestock.modules.smartshopping.engine.matching.FuzzySimilarityEngine;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("ProductMatchingEngine Strict Exact Match Rules Tests")
class ProductMatchingEngineTest {

    private ProductMatchingEngine matchingEngine;
    private NormalizedProductQuery requestedOil1L;

    @BeforeEach
    void setUp() {
        FuzzySimilarityEngine fuzzy = new FuzzySimilarityEngine();
        matchingEngine = new ProductMatchingEngine(fuzzy);

        requestedOil1L = NormalizedProductQuery.builder()
                .rawQuery("Fortune Sunflower Oil 1L")
                .normalizedQuery("fortune sunflower oil 1l")
                .brand("Fortune")
                .category("Cooking Oil")
                .product("Sunflower Oil")
                .variant("Sunflower")
                .canonicalQuantity(new BigDecimal("1000"))
                .canonicalUnit("ML")
                .packCount(1)
                .build();
    }

    @Test
    @DisplayName("Fortune Sunflower Oil 1L -> EXACT MATCH")
    void testExactMatchAcceptance() {
        DealCandidateInput candidate = DealCandidateInput.builder()
                .title("Fortune Sunlite Refined Sunflower Oil 1L Pouch")
                .brand("Fortune")
                .category("Cooking Oil")
                .variant("Sunflower")
                .quantity(new BigDecimal("1000"))
                .unit("ML")
                .packCount(1)
                .price(new BigDecimal("182.00"))
                .availability("IN_STOCK")
                .confidence(0.95)
                .build();

        ProductMatchResult result = matchingEngine.match(requestedOil1L, candidate);

        assertTrue(result.isExactMatch(), "Should be exact match");
        assertEquals(DealMatchCategory.EXACT_MATCH, result.getCategory());
        assertTrue(result.getMatchScore() >= 0.80, "Match score should be >= 0.80");
    }

    @Test
    @DisplayName("Fortune Sunflower Oil 5L -> REJECT (Wrong quantity)")
    void testWrongQuantityRejection() {
        DealCandidateInput candidate5L = DealCandidateInput.builder()
                .title("Fortune Sunlite Refined Sunflower Oil 5L Jar")
                .brand("Fortune")
                .category("Cooking Oil")
                .variant("Sunflower")
                .quantity(new BigDecimal("5000"))
                .unit("ML")
                .packCount(1)
                .price(new BigDecimal("890.00"))
                .availability("IN_STOCK")
                .build();

        ProductMatchResult result = matchingEngine.match(requestedOil1L, candidate5L);

        assertFalse(result.isExactMatch(), "5L must NOT be exact match for 1L");
        assertEquals(DealMatchCategory.REJECTED, result.getCategory(), "Wrong quantity must be rejected as exact deal");
    }

    @Test
    @DisplayName("Fortune Rice Bran Oil 1L -> REJECT (Wrong variant)")
    void testWrongVariantRejection() {
        DealCandidateInput candidateRiceBran = DealCandidateInput.builder()
                .title("Fortune Rice Bran Health Oil 1L")
                .brand("Fortune")
                .category("Cooking Oil")
                .variant("Rice Bran")
                .quantity(new BigDecimal("1000"))
                .unit("ML")
                .packCount(1)
                .price(new BigDecimal("175.00"))
                .availability("IN_STOCK")
                .build();

        ProductMatchResult result = matchingEngine.match(requestedOil1L, candidateRiceBran);

        assertFalse(result.isExactMatch(), "Rice Bran must NOT be exact match for Sunflower");
        assertEquals(DealMatchCategory.REJECTED, result.getCategory(), "Conflicting variant must be rejected");
    }

    @Test
    @DisplayName("Saffola Sunflower Oil 1L -> ALTERNATIVE (Different brand)")
    void testDifferentBrandAlternative() {
        DealCandidateInput candidateSaffola = DealCandidateInput.builder()
                .title("Saffola Sunlite Refined Sunflower Oil 1L Pouch")
                .brand("Saffola")
                .category("Cooking Oil")
                .variant("Sunflower")
                .quantity(new BigDecimal("1000"))
                .unit("ML")
                .packCount(1)
                .price(new BigDecimal("185.00"))
                .availability("IN_STOCK")
                .build();

        ProductMatchResult result = matchingEngine.match(requestedOil1L, candidateSaffola);

        assertFalse(result.isExactMatch(), "Different brand cannot be exact match when Fortune was requested");
        assertEquals(DealMatchCategory.SIMILAR_ALTERNATIVE, result.getCategory(),
                "Should qualify as a valid similar/alternative deal");
    }

    @Test
    @DisplayName("Fortune Sunflower Oil 2 x 1L Combo -> REJECT (Pack combo mismatch)")
    void testComboPackRejection() {
        DealCandidateInput candidateCombo = DealCandidateInput.builder()
                .title("Fortune Sunflower Oil 1L (Pack of 2)")
                .brand("Fortune")
                .category("Cooking Oil")
                .variant("Sunflower")
                .quantity(new BigDecimal("1000"))
                .unit("ML")
                .packCount(2)
                .price(new BigDecimal("350.00"))
                .availability("IN_STOCK")
                .build();

        ProductMatchResult result = matchingEngine.match(requestedOil1L, candidateCombo);

        assertFalse(result.isExactMatch(), "Pack of 2 combo must NOT be exact match for single 1L");
        assertEquals(DealMatchCategory.REJECTED, result.getCategory());
    }
}
