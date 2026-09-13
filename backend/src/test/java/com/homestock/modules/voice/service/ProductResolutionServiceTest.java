package com.homestock.modules.voice.service;

import com.homestock.modules.category.entity.Category;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.product.entity.Product;
import com.homestock.modules.product.repository.ProductRepository;
import com.homestock.modules.voice.dto.ProductMatchResult;
import com.homestock.modules.voice.dto.ProductMatchResult.MatchType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
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
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ProductResolutionServiceTest {

    @Mock
    private InventoryItemRepository inventoryItemRepository;

    @Mock
    private ProductRepository productRepository;

    private TamilTanglishNormalizer tamilNormalizer;
    private ProductResolutionService resolutionService;

    private final UUID homeId = UUID.randomUUID();
    private Home home;
    private InventoryItem riceItem;
    private InventoryItem oilItem;
    private InventoryItem milkItem;

    @BeforeEach
    void setUp() {
        tamilNormalizer = new TamilTanglishNormalizer();
        resolutionService = new ProductResolutionService(inventoryItemRepository, productRepository, tamilNormalizer);

        home = Home.builder().name("My Home").build();
        home.setId(homeId);

        riceItem = InventoryItem.builder()
                .home(home)
                .name("Ponni Raw Rice")
                .quantity(new BigDecimal("10.00"))
                .unit("KG")
                .isArchived(false)
                .build();
        riceItem.setId(UUID.randomUUID());

        oilItem = InventoryItem.builder()
                .home(home)
                .name("Gold Winner Sunflower Oil")
                .quantity(new BigDecimal("2.00"))
                .unit("L")
                .isArchived(false)
                .build();
        oilItem.setId(UUID.randomUUID());

        milkItem = InventoryItem.builder()
                .home(home)
                .name("Aavin Toned Milk")
                .quantity(new BigDecimal("3.00"))
                .unit("PACKET")
                .isArchived(false)
                .build();
        milkItem.setId(UUID.randomUUID());
    }

    @Test
    @DisplayName("Should resolve exact case-insensitive match from inventory")
    void testExactMatch() {
        when(inventoryItemRepository.findAllByHomeIdAndIsArchivedFalseOrderByNameAsc(homeId))
                .thenReturn(List.of(riceItem, oilItem));

        ProductMatchResult result = resolutionService.resolveProduct(homeId, "Ponni Raw Rice", "Rice");

        assertEquals(MatchType.EXACT, result.getMatchType());
        assertEquals(riceItem.getId(), result.getProductId());
        assertEquals("Ponni Raw Rice", result.getProductName());
        assertEquals(1.0, result.getConfidence());
    }

    @Test
    @DisplayName("Should resolve Tamil alias 'arisi' to Rice item in inventory")
    void testTamilAliasResolution() {
        when(inventoryItemRepository.findAllByHomeIdAndIsArchivedFalseOrderByNameAsc(homeId))
                .thenReturn(List.of(riceItem, oilItem));

        ProductMatchResult result = resolutionService.resolveProduct(homeId, "arisi", "Rice");

        assertTrue(result.getConfidence() >= 0.90);
        assertEquals(riceItem.getId(), result.getProductId());
        assertTrue(result.getProductName().toLowerCase().contains("rice"));
    }

    @Test
    @DisplayName("Should resolve Tanglish postposition 'oil-la' to Cooking Oil")
    void testTanglishPostpositionResolution() {
        when(inventoryItemRepository.findAllByHomeIdAndIsArchivedFalseOrderByNameAsc(homeId))
                .thenReturn(List.of(riceItem, oilItem));

        ProductMatchResult result = resolutionService.resolveProduct(homeId, "oil-la", "Oil");

        assertTrue(result.getConfidence() >= 0.85);
        assertEquals(oilItem.getId(), result.getProductId());
    }

    @Test
    @DisplayName("Should resolve barcode against product catalog")
    void testBarcodeMatch() {
        String barcode = "8901030382909";
        Product catalogProduct = Product.builder()
                .barcode(barcode)
                .name("Tata Salt 1kg")
                .brand("Tata")
                .build();
        catalogProduct.setId(UUID.randomUUID());

        when(productRepository.findByBarcode(barcode)).thenReturn(Optional.of(catalogProduct));

        ProductMatchResult result = resolutionService.resolveProduct(homeId, barcode, null);

        assertEquals(MatchType.BARCODE, result.getMatchType());
        assertEquals("Tata Salt 1kg", result.getProductName());
        assertEquals(0.99, result.getConfidence());
    }

    @Test
    @DisplayName("Should fall back to canonical catalog when item not in home inventory")
    void testCanonicalFallbackWhenNotInInventory() {
        when(inventoryItemRepository.findAllByHomeIdAndIsArchivedFalseOrderByNameAsc(homeId))
                .thenReturn(List.of(oilItem));

        ProductMatchResult result = resolutionService.resolveProduct(homeId, "sakkarai", "Sugar");

        assertEquals(MatchType.ALIAS, result.getMatchType());
        assertNull(result.getProductId()); // Not yet in inventory
        assertEquals("Sugar", result.getProductName());
        assertEquals(0.98, result.getConfidence());
        assertEquals("KG", result.getDefaultUnit());
    }

    @Test
    @DisplayName("Should handle fuzzy match with minor speech typo")
    void testFuzzyMatch() {
        when(inventoryItemRepository.findAllByHomeIdAndIsArchivedFalseOrderByNameAsc(homeId))
                .thenReturn(List.of(milkItem));

        ProductMatchResult result = resolutionService.resolveProduct(homeId, "Aavin Milk", "Milk");

        assertTrue(result.getConfidence() >= 0.80);
        assertEquals(milkItem.getId(), result.getProductId());
    }
}

