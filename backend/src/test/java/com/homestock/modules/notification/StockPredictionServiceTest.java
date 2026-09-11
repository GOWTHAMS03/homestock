package com.homestock.modules.notification;

import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.notification.dto.MLFeatureVectorDto;
import com.homestock.modules.notification.ml.FeatureExtractor;
import com.homestock.modules.notification.ml.StockPredictionService;
import com.homestock.modules.notification.ml.model.MLStockPredictionModel;
import com.homestock.modules.notification.ml.model.RuleBasedPredictionModel;
import com.homestock.modules.notification.ml.model.StockPredictionResult;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class StockPredictionServiceTest {

    @Mock
    private FeatureExtractor featureExtractor;

    private RuleBasedPredictionModel ruleBasedModel;
    private MLStockPredictionModel mlStockModel;
    private StockPredictionService predictionService;

    @BeforeEach
    void setUp() {
        ruleBasedModel = new RuleBasedPredictionModel();
        mlStockModel = new MLStockPredictionModel();
        predictionService = new StockPredictionService(featureExtractor, ruleBasedModel, mlStockModel);
    }

    @Test
    @DisplayName("Cold start user (< 5 samples) should use RuleBasedPredictionModel")
    void testColdStartPrediction() {
        InventoryItem item = InventoryItem.builder()
                .name("Sunflower Oil")
                .quantity(new BigDecimal("0.5"))
                .unit("L")
                .build();

        MLFeatureVectorDto coldStartFeatures = MLFeatureVectorDto.builder()
                .itemName("Sunflower Oil")
                .currentStock(new BigDecimal("0.5"))
                .unit("L")
                .sampleCount(2) // < 5 observations
                .averageConsumptionPerDay(new BigDecimal("0.08"))
                .build();

        when(featureExtractor.extractFeatures(any(), any())).thenReturn(coldStartFeatures);

        StockPredictionResult result = predictionService.predictDepletion(item, UUID.randomUUID());

        assertNotNull(result);
        assertEquals("RULE_BASED", result.getModelUsed());
        assertEquals("LOW", result.getConfidence());
        assertTrue(result.getDaysUntilEmpty().compareTo(BigDecimal.ZERO) > 0);
        assertTrue(result.getProbabilityWithin7Days() > 0.50);
    }

    @Test
    @DisplayName("Mature user (>= 5 samples) should use MLStockPredictionModel with statistical CDF")
    void testMatureMLPrediction() {
        InventoryItem item = InventoryItem.builder()
                .name("Sunflower Oil")
                .quantity(new BigDecimal("0.3"))
                .unit("L")
                .build();

        MLFeatureVectorDto matureFeatures = MLFeatureVectorDto.builder()
                .itemName("Sunflower Oil")
                .currentStock(new BigDecimal("0.3"))
                .unit("L")
                .sampleCount(12) // >= 5 observations
                .averageConsumptionPerDay(new BigDecimal("0.12"))
                .consumptionVelocity(new BigDecimal("0.14"))
                .consumptionVariance(new BigDecimal("0.002"))
                .recentUsageTrend("ACCELERATING")
                .build();

        when(featureExtractor.extractFeatures(any(), any())).thenReturn(matureFeatures);

        StockPredictionResult result = predictionService.predictDepletion(item, UUID.randomUUID());

        assertNotNull(result);
        assertEquals("STATISTICAL_ML", result.getModelUsed());
        assertTrue(result.getDaysUntilEmpty().compareTo(new BigDecimal("3.0")) <= 0);
        assertTrue(result.getProbabilityWithin3Days() >= 0.70);
        assertTrue(result.getProbabilityWithin7Days() >= 0.90);
    }

    @Test
    @DisplayName("Depleted item (0 stock) predicts 0 days remaining with 1.0 probability")
    void testZeroStockPrediction() {
        MLFeatureVectorDto zeroStockFeatures = MLFeatureVectorDto.builder()
                .itemName("Milk")
                .currentStock(BigDecimal.ZERO)
                .unit("L")
                .sampleCount(6)
                .averageConsumptionPerDay(new BigDecimal("0.50"))
                .build();

        StockPredictionResult result = mlStockModel.predict(zeroStockFeatures);

        assertEquals(BigDecimal.ZERO, result.getDaysUntilEmpty());
        assertEquals(1.0, result.getProbabilityWithin1Day());
        assertEquals(1.0, result.getProbabilityWithin3Days());
    }
}
