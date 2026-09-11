package com.homestock.modules.away;

import com.homestock.modules.away.entity.AwayPredictionType;
import com.homestock.modules.away.ml.StatisticalAwayPredictor;
import com.homestock.modules.away.service.ConsumptionHistoryService;
import com.homestock.modules.away.service.InventoryPredictionService;
import com.homestock.modules.away.service.PredictionConfidenceService;
import com.homestock.modules.inventory.entity.InventoryItem;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class InventoryPredictionServiceTest {

    private InventoryPredictionService inventoryPredictionService;

    @BeforeEach
    void setUp() {
        StatisticalAwayPredictor awayPredictor = new StatisticalAwayPredictor();
        PredictionConfidenceService confidenceService = new PredictionConfidenceService();
        inventoryPredictionService = new InventoryPredictionService(awayPredictor, confidenceService);
    }

    @Test
    @DisplayName("Consumption exceeding available stock marks item as LIKELY_RAN_OUT")
    void testItemLikelyRanOut() {
        InventoryItem bread = InventoryItem.builder()
                .name("Bread")
                .quantity(new BigDecimal("2.0"))
                .unit("packs")
                .minimumQuantity(new BigDecimal("1.0"))
                .build();
        bread.setId(UUID.randomUUID());

        // Baseline: 0.5 packs/day. Away = 6 days => ~3.0 packs predicted consumed
        ConsumptionHistoryService.ItemBaselineHistory history = ConsumptionHistoryService.ItemBaselineHistory.builder()
                .itemId(bread.getId())
                .itemName("Bread")
                .stockBeforeAway(new BigDecimal("2.0"))
                .knownPurchasesDuringAway(BigDecimal.ZERO)
                .baselineDailyConsumption(new BigDecimal("0.50"))
                .consumptionVariability(new BigDecimal("0.10"))
                .sampleCount(6)
                .feedbackCalibrationFactor(BigDecimal.ONE)
                .build();

        var result = inventoryPredictionService.predictInventoryChange(
                bread, history, LocalDate.of(2026, 9, 1), LocalDate.of(2026, 9, 7)
        );

        assertNotNull(result);
        assertEquals(AwayPredictionType.LIKELY_RAN_OUT, result.getPredictionType());
        assertEquals(0, result.getEstimatedQuantity().compareTo(BigDecimal.ZERO));
        assertEquals("Probably ran out", result.getDisplayTitle());
        assertEquals("Add to Shopping List", result.getActionLabel());
        assertTrue(result.getConfidence() >= 0.70);
    }

    @Test
    @DisplayName("Consumption leaving small stock below minimum marks item as LIKELY_LOW")
    void testItemLikelyLow() {
        InventoryItem oil = InventoryItem.builder()
                .name("Sunflower Oil")
                .quantity(new BigDecimal("1.0"))
                .unit("L")
                .minimumQuantity(new BigDecimal("0.5"))
                .build();
        oil.setId(UUID.randomUUID());

        // Baseline: 0.10 L/day. Away = 6 days => ~0.65 L consumed, remaining ~0.35 L (< 0.5L min)
        ConsumptionHistoryService.ItemBaselineHistory history = ConsumptionHistoryService.ItemBaselineHistory.builder()
                .itemId(oil.getId())
                .itemName("Sunflower Oil")
                .stockBeforeAway(new BigDecimal("1.0"))
                .knownPurchasesDuringAway(BigDecimal.ZERO)
                .baselineDailyConsumption(new BigDecimal("0.10"))
                .consumptionVariability(new BigDecimal("0.15"))
                .sampleCount(8)
                .feedbackCalibrationFactor(BigDecimal.ONE)
                .build();

        var result = inventoryPredictionService.predictInventoryChange(
                oil, history, LocalDate.of(2026, 9, 1), LocalDate.of(2026, 9, 7)
        );

        assertNotNull(result);
        assertEquals(AwayPredictionType.LIKELY_LOW, result.getPredictionType());
        assertTrue(result.getEstimatedQuantity().compareTo(BigDecimal.ZERO) > 0);
        assertEquals("Likely running low", result.getDisplayTitle());
        assertEquals("Add to Shopping List", result.getActionLabel());
    }
}
