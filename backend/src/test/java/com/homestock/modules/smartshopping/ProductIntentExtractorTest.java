package com.homestock.modules.smartshopping;

import com.homestock.modules.smartshopping.dto.ProductIntent;
import com.homestock.modules.smartshopping.dto.SearchIntent;
import com.homestock.modules.smartshopping.engine.intent.ProductIntentExtractor;
import com.homestock.modules.smartshopping.engine.intent.ProductNormalizer;
import com.homestock.modules.smartshopping.engine.intent.SearchIntentClassifier;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

class ProductIntentExtractorTest {

    private ProductIntentExtractor extractor;

    @BeforeEach
    void setUp() {
        ProductNormalizer normalizer = new ProductNormalizer();
        SearchIntentClassifier classifier = new SearchIntentClassifier();
        extractor = new ProductIntentExtractor(normalizer, classifier);
    }

    @Test
    @DisplayName("Requirement 1: 'Fortune Sunflower Oil 1L - 2 bottles' correctly extracts all fields")
    void testFortuneOilWithQuantity() {
        String input = "Fortune Sunflower Oil 1L - 2 bottles";
        ProductIntent intent = extractor.extractIntent(input, null, null, null);

        assertNotNull(intent);
        assertEquals("Fortune Sunflower Oil 1L - 2 bottles", intent.getRawInput());
        assertEquals("Fortune", intent.getBrand());
        assertEquals("Sunflower", intent.getVariant());
        assertEquals("1L", intent.getPackSize());
        assertEquals(new BigDecimal("2"), intent.getQuantity());
        assertEquals("bottle", intent.getUnit());
        assertEquals("Cooking Oil", intent.getCategory());
        assertTrue(intent.getGenericName().toLowerCase().contains("sunflower"));
        assertEquals(SearchIntent.EXACT_PRODUCT, intent.getSearchIntent());
        assertTrue(intent.getConfidence() >= 0.95);
        assertNotNull(intent.getFieldConfidences());
        assertTrue(intent.getFieldConfidences().containsKey("brand"));
        assertTrue(intent.getFieldConfidences().containsKey("packSize"));
        assertTrue(intent.getFieldConfidences().containsKey("quantity"));
    }

    @Test
    @DisplayName("Requirement 2: 'Surf Excel Matic Top Load 2kg' classified as EXACT_PRODUCT")
    void testSurfExcelExact() {
        String input = "Surf Excel Matic Top Load 2kg";
        ProductIntent intent = extractor.extractIntent(input, null, null, null);

        assertEquals("Surf Excel", intent.getBrand());
        assertEquals("Matic Top Load", intent.getVariant());
        assertEquals("2kg", intent.getPackSize());
        assertEquals(SearchIntent.EXACT_PRODUCT, intent.getSearchIntent());
    }

    @Test
    @DisplayName("Requirement 2: 'Parle-G 800g' classified as EXACT_PRODUCT / BRANDED_PRODUCT")
    void testParleGBranded() {
        String input = "Parle-G 800g";
        ProductIntent intent = extractor.extractIntent(input, null, null, null);

        assertEquals("Parle-G", intent.getBrand());
        assertEquals("800g", intent.getPackSize());
        assertTrue(intent.getSearchIntent() == SearchIntent.EXACT_PRODUCT || intent.getSearchIntent() == SearchIntent.BRANDED_PRODUCT);
    }

    @Test
    @DisplayName("Requirement 2: 'Coca Cola Zero Sugar 750ml' extracts variant and size")
    void testCocaColaZeroSugar() {
        String input = "Coca Cola Zero Sugar 750ml";
        ProductIntent intent = extractor.extractIntent(input, null, null, null);

        assertEquals("Coca Cola", intent.getBrand());
        assertEquals("Zero Sugar", intent.getVariant());
        assertEquals("750ml", intent.getPackSize());
        assertEquals(SearchIntent.EXACT_PRODUCT, intent.getSearchIntent());
    }

    @Test
    @DisplayName("Requirement 2: Genuinely generic 'Sunflower oil' classified as GENERIC_PRODUCT without brand")
    void testGenericSunflowerOil() {
        String input = "Sunflower oil";
        ProductIntent intent = extractor.extractIntent(input, null, null, null);

        assertNull(intent.getBrand(), "Generic search must not invent a brand");
        assertEquals("Sunflower", intent.getVariant());
        assertEquals(SearchIntent.GENERIC_PRODUCT, intent.getSearchIntent());
    }

    @Test
    @DisplayName("Requirement 2: Ambiguous single-term 'oil' classified as INSUFFICIENT_INFORMATION")
    void testAmbiguousOil() {
        String input = "oil";
        ProductIntent intent = extractor.extractIntent(input, null, null, null);

        assertEquals(SearchIntent.INSUFFICIENT_INFORMATION, intent.getSearchIntent());
        assertTrue(intent.getConfidence() < 0.70);
    }

    @Test
    @DisplayName("Requirement 4: 'Fortune Oil 1L - quantity 3' cleanly separates pack size from required count")
    void testQuantitySeparation() {
        String input = "Fortune Oil 1L - quantity 3";
        ProductIntent intent = extractor.extractIntent(input, null, null, null);

        assertEquals("Fortune", intent.getBrand());
        assertEquals("1L", intent.getPackSize());
        assertEquals(new BigDecimal("3"), intent.getQuantity());
    }

    @Test
    @DisplayName("Requirement 3: Barcode input receives highest product identity priority")
    void testBarcodeIdentity() {
        String input = "8906007280123";
        ProductIntent intent = extractor.extractIntent(input, null, null, null);

        assertEquals("8906007280123", intent.getBarcode());
        assertEquals(SearchIntent.EXACT_PRODUCT, intent.getSearchIntent());
        assertEquals(1.0, intent.getConfidence());
    }
}
