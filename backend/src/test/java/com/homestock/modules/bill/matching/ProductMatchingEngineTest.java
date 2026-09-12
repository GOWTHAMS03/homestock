package com.homestock.modules.bill.matching;

import com.homestock.modules.bill.parser.ParsedBillItem;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.product.entity.Product;
import com.homestock.modules.product.repository.ProductRepository;
import com.homestock.modules.shopping.entity.ShoppingListItem;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ProductMatchingEngineTest {

    @Mock
    private InventoryItemRepository inventoryItemRepository;

    @Mock
    private ProductRepository productRepository;

    @Mock
    private ShoppingListItemRepository shoppingListItemRepository;

    private ProductNormalizationService normalizationService;
    private ProductMatchingEngine matchingEngine;

    private final UUID homeId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        normalizationService = new ProductNormalizationService();
        matchingEngine = new ProductMatchingEngine(
                inventoryItemRepository,
                productRepository,
                shoppingListItemRepository,
                normalizationService
        );
    }

    @Test
    void testAutoMatchWhenExistingInventoryItemNameMatches() {
        InventoryItem existingItem = InventoryItem.builder()
                .name("Aashirvaad Superior MP Atta")
                .brand("Aashirvaad")
                .unit("KG")
                .quantity(new BigDecimal("5.0"))
                .build();
        existingItem.setId(UUID.randomUUID());

        when(inventoryItemRepository.findByHomeId(eq(homeId))).thenReturn(List.of(existingItem));

        ParsedBillItem scanned = ParsedBillItem.builder()
                .name("AASHIRVAAD ATTA 5KG")
                .quantity(new BigDecimal("1"))
                .unit("KG")
                .finalPrice(new BigDecimal("245.00"))
                .build();

        ProductMatchResult result = matchingEngine.matchItem(homeId, scanned);

        assertNotNull(result);
        assertEquals("AUTO_MATCHED", result.getMatchStatus());
        assertTrue(result.getConfidence().doubleValue() >= 0.80);
        assertNotNull(result.getMatchedInventoryItem());
        assertEquals("Aashirvaad Superior MP Atta", result.getMatchedInventoryItem().getName());
    }

    @Test
    void testNewProductCandidateWhenNoInventoryOrCatalogMatch() {
        when(inventoryItemRepository.findByHomeId(eq(homeId))).thenReturn(List.of());

        ParsedBillItem scanned = ParsedBillItem.builder()
                .name("ORGANIC CHIA SEEDS 250G")
                .quantity(new BigDecimal("1"))
                .unit("G")
                .finalPrice(new BigDecimal("199.00"))
                .build();

        ProductMatchResult result = matchingEngine.matchItem(homeId, scanned);

        assertNotNull(result);
        assertEquals("NEW_PRODUCT", result.getMatchStatus());
        assertNull(result.getMatchedInventoryItem());
        assertNull(result.getMatchedProduct());
        assertTrue(result.getResolvedName().contains("Chia Seeds"));
    }

    @Test
    void testStandardUnitPriceCalculationGramsToKg() {
        when(inventoryItemRepository.findByHomeId(eq(homeId))).thenReturn(List.of());

        // 500g for Rs. 275.00 -> Standard price per KG is 275 / 500 * 1000 = 550.00
        ParsedBillItem scanned = ParsedBillItem.builder()
                .name("AMUL BUTTER 500G")
                .quantity(new BigDecimal("500"))
                .unit("G")
                .finalPrice(new BigDecimal("275.00"))
                .build();

        ProductMatchResult result = matchingEngine.matchItem(homeId, scanned);

        assertNotNull(result);
        assertNotNull(result.getStandardUnitPrice());
        assertEquals(new BigDecimal("550.00"), result.getStandardUnitPrice());
    }

    @Test
    void testMatchShoppingListItem() {
        ShoppingListItem listItem = ShoppingListItem.builder()
                .itemName("Aashirvaad Atta")
                .quantity(new BigDecimal("5.0"))
                .unit("KG")
                .status("PENDING")
                .build();
        listItem.setId(UUID.randomUUID());

        when(shoppingListItemRepository.findPendingItemsByHomeId(eq(homeId))).thenReturn(List.of(listItem));

        Optional<ShoppingListItem> match = matchingEngine.findMatchingShoppingItem(homeId, "AASHIRVAAD ATTA 5KG");

        assertTrue(match.isPresent());
        assertEquals("Aashirvaad Atta", match.get().getItemName());
    }
}
