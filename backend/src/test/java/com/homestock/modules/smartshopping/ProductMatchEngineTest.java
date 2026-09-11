package com.homestock.modules.smartshopping;

import com.homestock.modules.smartshopping.dto.MatchStatus;
import com.homestock.modules.smartshopping.dto.ProductCandidate;
import com.homestock.modules.smartshopping.dto.ProductIntent;
import com.homestock.modules.smartshopping.dto.SearchIntent;
import com.homestock.modules.smartshopping.engine.matching.ProductMatchEngine;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

class ProductMatchEngineTest {

    private ProductMatchEngine matchEngine;

    @BeforeEach
    void setUp() {
        matchEngine = new ProductMatchEngine();
    }

    @Test
    @DisplayName("Requirement 7: Exact match for identical barcode yields VERIFIED_EXACT (100%)")
    void testExactBarcodeMatch() {
        ProductIntent intent = ProductIntent.builder()
                .barcode("8906007280123")
                .searchIntent(SearchIntent.EXACT_PRODUCT)
                .build();

        ProductCandidate candidate = ProductCandidate.builder()
                .barcode("8906007280123")
                .productName("Fortune Sunlite Refined Sunflower Oil")
                .brand("Fortune")
                .packageSize("1 L")
                .build();

        var result = matchEngine.match(intent, candidate);
        assertEquals(100.0, result.score());
        assertEquals(MatchStatus.VERIFIED_EXACT, result.status());
        assertTrue(result.isAcceptableExact());
        assertFalse(result.isBrandClash());
    }

    @Test
    @DisplayName("Requirement 7 & 8: Exact brand, product name, variant, and pack size yields VERIFIED_EXACT")
    void testExactBrandAndProductMatch() {
        ProductIntent intent = ProductIntent.builder()
                .brand("Fortune")
                .productName("Fortune Sunflower Oil 1L")
                .variant("Sunflower")
                .packSize("1L")
                .category("Cooking Oil")
                .genericName("Sunflower Oil")
                .searchIntent(SearchIntent.EXACT_PRODUCT)
                .build();

        ProductCandidate candidate = ProductCandidate.builder()
                .productName("Fortune Sunlite Refined Sunflower Oil 1L")
                .brand("Fortune")
                .packageSize("1L")
                .category("Cooking Oil")
                .imageUrl("https://example.com/img.jpg")
                .build();

        var result = matchEngine.match(intent, candidate);
        assertTrue(result.score() >= 95.0, "Score should be >= 95 for exact match");
        assertEquals(MatchStatus.VERIFIED_EXACT, result.status());
        assertTrue(result.isAcceptableExact());
        assertFalse(result.isBrandClash());
    }

    @Test
    @DisplayName("Requirement 8: Brand Protection Rule - competing brand receives severe penalty (-60) and REJECT")
    void testBrandProtectionRule() {
        ProductIntent intent = ProductIntent.builder()
                .brand("Surf Excel")
                .productName("Surf Excel Matic 2kg")
                .variant("Matic")
                .packSize("2kg")
                .category("Cleaning & Detergents")
                .searchIntent(SearchIntent.EXACT_PRODUCT)
                .build();

        // Competing brand Ariel
        ProductCandidate arielCandidate = ProductCandidate.builder()
                .productName("Ariel Matic Detergent Powder 2kg")
                .brand("Ariel")
                .packageSize("2kg")
                .category("Cleaning & Detergents")
                .build();

        var result = matchEngine.match(intent, arielCandidate);
        assertTrue(result.isBrandClash(), "Should detect brand clash");
        assertFalse(result.isAcceptableExact(), "Ariel must never be an exact match for Surf Excel");
        assertEquals(MatchStatus.REJECT, result.status());
        assertTrue(result.score() < 70.0);
    }

    @Test
    @DisplayName("Requirement 7: Wrong pack size lowers match score and prevents VERIFIED_EXACT")
    void testWrongPackSizePenalty() {
        ProductIntent intent = ProductIntent.builder()
                .brand("Surf Excel")
                .productName("Surf Excel Matic 2kg")
                .packSize("2kg")
                .category("Cleaning & Detergents")
                .searchIntent(SearchIntent.EXACT_PRODUCT)
                .build();

        ProductCandidate oneKgCandidate = ProductCandidate.builder()
                .productName("Surf Excel Matic Detergent Powder 1kg")
                .brand("Surf Excel")
                .packageSize("1kg")
                .category("Cleaning & Detergents")
                .build();

        var result = matchEngine.match(intent, oneKgCandidate);
        assertNotEquals(MatchStatus.VERIFIED_EXACT, result.status(), "1kg must not be VERIFIED_EXACT for 2kg request");
    }

    @Test
    @DisplayName("Requirement 7: Variant clash (Sunflower vs Mustard) receives penalty")
    void testVariantClashPenalty() {
        ProductIntent intent = ProductIntent.builder()
                .brand("Fortune")
                .productName("Fortune Sunflower Oil")
                .variant("Sunflower")
                .category("Cooking Oil")
                .searchIntent(SearchIntent.EXACT_PRODUCT)
                .build();

        ProductCandidate mustardCandidate = ProductCandidate.builder()
                .productName("Fortune Kachi Ghani Mustard Oil 1L")
                .brand("Fortune")
                .category("Cooking Oil")
                .build();

        var result = matchEngine.match(intent, mustardCandidate);
        assertNotEquals(MatchStatus.VERIFIED_EXACT, result.status());
        assertTrue(result.score() < 85.0);
    }
}
