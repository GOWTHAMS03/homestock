package com.homestock.modules.smartshopping;

import com.homestock.modules.smartshopping.dto.ProductIntent;
import com.homestock.modules.smartshopping.dto.SearchIntent;
import com.homestock.modules.smartshopping.engine.intent.SearchQueryBuilder;
import com.homestock.modules.smartshopping.provider.ProductSearchRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class SearchQueryBuilderTest {

    private SearchQueryBuilder queryBuilder;

    @BeforeEach
    void setUp() {
        queryBuilder = new SearchQueryBuilder();
    }

    @Test
    @DisplayName("Requirement 6: Exact product queries retain brand, variant, and pack size")
    void testExactProductQueryGeneration() {
        ProductIntent intent = ProductIntent.builder()
                .rawInput("Fortune Sunflower Oil 1L")
                .brand("Fortune")
                .variant("Sunflower")
                .genericName("Sunflower Oil")
                .exactProductName("Fortune Sunflower Oil 1L")
                .packSize("1L")
                .searchIntent(SearchIntent.EXACT_PRODUCT)
                .build();

        List<ProductSearchRequest> requests = queryBuilder.buildSearchQueries(intent, 5);

        assertFalse(requests.isEmpty());
        // All exact queries must carry the brand
        for (ProductSearchRequest req : requests) {
            assertEquals("Fortune", req.getBrand());
        }

        // At least one query must contain brand and pack size
        boolean hasBrandAndPackSize = requests.stream()
                .anyMatch(r -> r.getItemName().toLowerCase().contains("fortune") && r.getItemName().toLowerCase().contains("1l"));
        assertTrue(hasBrandAndPackSize, "Should generate query with brand and pack size");
    }

    @Test
    @DisplayName("Requirement 6: Generic queries never include unrequested brands")
    void testGenericQueryGenerationNoBrand() {
        ProductIntent intent = ProductIntent.builder()
                .rawInput("Sunflower oil")
                .productName("Sunflower oil")
                .genericName("Sunflower Oil")
                .category("Cooking Oil")
                .searchIntent(SearchIntent.GENERIC_PRODUCT)
                .build();

        List<ProductSearchRequest> requests = queryBuilder.buildSearchQueries(intent, 5);

        assertFalse(requests.isEmpty());
        for (ProductSearchRequest req : requests) {
            assertNull(req.getBrand(), "Generic query must not add a brand that user did not request");
            assertFalse(req.getItemName().toLowerCase().contains("fortune"), "Generic query must not invent Fortune");
            assertFalse(req.getItemName().toLowerCase().contains("saffola"), "Generic query must not invent Saffola");
        }
    }
}
