package com.homestock.modules.deals;

import com.homestock.modules.deals.model.NormalizedProductQuery;
import com.homestock.modules.deals.service.ProductQueryNormalizationService;
import com.homestock.modules.smartshopping.engine.identity.BrandResolver;
import com.homestock.modules.smartshopping.engine.identity.ProductTaxonomy;
import com.homestock.modules.smartshopping.engine.intent.ProductNormalizer;
import com.homestock.modules.smartshopping.engine.matching.FuzzySimilarityEngine;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

@DisplayName("ProductQueryNormalizationService Tests")
class ProductQueryNormalizationServiceTest {

    private ProductQueryNormalizationService normalizationService;

    @BeforeEach
    void setUp() {
        ProductNormalizer normalizer = new ProductNormalizer();
        FuzzySimilarityEngine fuzzy = new FuzzySimilarityEngine();
        BrandResolver brandResolver = new BrandResolver(fuzzy);
        ProductTaxonomy taxonomy = new ProductTaxonomy();

        normalizationService = new ProductQueryNormalizationService(normalizer, brandResolver, taxonomy);
    }

    @Test
    @DisplayName("Normalizes 1L, 1 l, 1 litre, 1 liter, and 1000ml to canonical 1000 ML")
    void testUnitAndQuantityNormalization() {
        String[] queries = {
                "fortune sunflower oil 1 litre",
                "sunflower oil 1L",
                "fortune sunflower 1ltr",
                "fortune sunflower oil 1 liter",
                "fortune sunflower oil 1 l",
                "fortune sunflower oil 1000ml"
        };

        for (String q : queries) {
            NormalizedProductQuery norm = normalizationService.normalize(q);
            assertNotNull(norm.getCanonicalQuantity(), "Failed for query: " + q);
            assertEquals(0, new BigDecimal("1000").compareTo(norm.getCanonicalQuantity()),
                    "Quantity mismatch for: " + q);
            assertEquals("ML", norm.getCanonicalUnit(), "Unit mismatch for: " + q);
        }
    }

    @Test
    @DisplayName("Extracts Fortune, Cooking Oil, Sunflower, 1000 ML from 'Fortune Sunflower Oil 1L'")
    void testStructuredAttributeExtraction() {
        NormalizedProductQuery norm = normalizationService.normalize("Fortune Sunflower Oil 1L");

        assertEquals("Fortune", norm.getBrand());
        assertEquals("Cooking Oil", norm.getCategory());
        assertEquals("Sunflower", norm.getVariant());
        assertEquals(0, new BigDecimal("1000").compareTo(norm.getCanonicalQuantity()));
        assertEquals("ML", norm.getCanonicalUnit());
        assertEquals(1, norm.getPackCount());
    }

    @Test
    @DisplayName("Correctly identifies combo packs (e.g. 2 x 1L or pack of 2)")
    void testComboPackExtraction() {
        NormalizedProductQuery norm = normalizationService.normalize("Fortune Sunflower Oil 2 x 1L");
        assertEquals(2, norm.getPackCount());
        assertEquals(0, new BigDecimal("1000").compareTo(norm.getCanonicalQuantity()));

        NormalizedProductQuery norm2 = normalizationService.normalize("Fortune Sunflower Oil pack of 3");
        assertEquals(3, norm2.getPackCount());
    }

    @Test
    @DisplayName("Gracefully handles generic queries like 'oil'")
    void testGenericQueryNormalization() {
        NormalizedProductQuery norm = normalizationService.normalize("oil");

        assertEquals("Cooking Oil", norm.getCategory());
        assertNull(norm.getBrand());
        assertNull(norm.getCanonicalQuantity());
        assertEquals(1, norm.getPackCount());
    }
}
