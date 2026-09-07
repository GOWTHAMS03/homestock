package com.homestock.modules.voice.service;

import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.voice.dto.VoiceCommandResult;
import com.homestock.modules.voice.dto.VoiceIntent;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.jpa.domain.Specification;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VoiceCommandParserTest {

    @Mock
    private InventoryItemRepository inventoryItemRepository;

    private VoiceCommandParser parser;
    private final UUID homeId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        UnitNormalizationService unitNormalizer = new UnitNormalizationService();
        NumberNormalizationService numberNormalizer = new NumberNormalizationService();
        TamilTanglishNormalizer tamilNormalizer = new TamilTanglishNormalizer();
        ProductMatcher productMatcher = new ProductMatcher(inventoryItemRepository, tamilNormalizer);

        parser = new VoiceCommandParser(unitNormalizer, numberNormalizer, tamilNormalizer, productMatcher);

        org.mockito.Mockito.lenient().when(inventoryItemRepository.findAll()).thenReturn(Collections.emptyList());
    }

    @Test
    void testEnglishAddShoppingItem() {
        VoiceCommandResult result = parser.parse(homeId, "Add 2 litre cooking oil to shopping list");
        assertEquals(VoiceIntent.ADD_SHOPPING_ITEM, result.getIntent());
        assertNotNull(result.getEntities());
        assertEquals("cooking oil", result.getEntities().getItemName().toLowerCase());
        assertEquals(0, new BigDecimal("2").compareTo(result.getEntities().getQuantity()));
        assertTrue("L".equalsIgnoreCase(result.getEntities().getUnit()));
    }

    @Test
    void testTanglishAddShoppingItem() {
        VoiceCommandResult result = parser.parse(homeId, "Shopping list la rice add pannu");
        assertEquals(VoiceIntent.ADD_SHOPPING_ITEM, result.getIntent());
        assertNotNull(result.getEntities());
        assertEquals("rice", result.getEntities().getItemName().toLowerCase());
    }

    @Test
    void testTanglishQuantityAndItem() {
        VoiceCommandResult result = parser.parse(homeId, "rendu packet milk shopping list la podu");
        assertEquals(VoiceIntent.ADD_SHOPPING_ITEM, result.getIntent());
        assertNotNull(result.getEntities());
        assertEquals("milk", result.getEntities().getItemName().toLowerCase());
        assertEquals(0, new BigDecimal("2").compareTo(result.getEntities().getQuantity()));
        assertTrue("PACK".equalsIgnoreCase(result.getEntities().getUnit()));
    }

    @Test
    void testStockOutTanglish() {
        VoiceCommandResult result = parser.parse(homeId, "Cooking oil 500 ml theerndhuduchu");
        assertEquals(VoiceIntent.STOCK_OUT, result.getIntent());
        assertNotNull(result.getEntities());
        assertEquals(0, new BigDecimal("500").compareTo(result.getEntities().getQuantity()));
        assertTrue("ML".equalsIgnoreCase(result.getEntities().getUnit()));
    }

    @Test
    void testItemStatusQuery() {
        VoiceCommandResult result = parser.parse(homeId, "Rice shopping list la irukka?");
        assertEquals(VoiceIntent.GET_ITEM_STATUS, result.getIntent());
        assertNotNull(result.getEntities());
        assertEquals("rice", result.getEntities().getItemName().toLowerCase());
    }

    @Test
    void testNavigationCommands() {
        VoiceCommandResult result1 = parser.parse(homeId, "Open shopping list");
        assertEquals(VoiceIntent.OPEN_SHOPPING_LIST, result1.getIntent());

        VoiceCommandResult result2 = parser.parse(homeId, "Go to inventory");
        assertEquals(VoiceIntent.OPEN_INVENTORY, result2.getIntent());

        VoiceCommandResult result3 = parser.parse(homeId, "Show analytics");
        assertEquals(VoiceIntent.OPEN_ANALYTICS, result3.getIntent());
    }

    @Test
    void testLowStockQuery() {
        VoiceCommandResult result = parser.parse(homeId, "What's running low?");
        assertEquals(VoiceIntent.GET_LOW_STOCK_ITEMS, result.getIntent());
    }
}
