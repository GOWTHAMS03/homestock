package com.homestock.modules.notification.ml;

import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.notification.dto.MLFeatureVectorDto;
import com.homestock.modules.notification.dto.MLPredictionDto;
import com.homestock.modules.notification.ml.model.MLStockPredictionModel;
import com.homestock.modules.notification.ml.model.PredictionModel;
import com.homestock.modules.notification.ml.model.RuleBasedPredictionModel;
import com.homestock.modules.notification.ml.model.StockPredictionResult;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * StockPredictionService:
 * Coordinates feature extraction and delegates to the appropriate statistical ML or rule-based model.
 * Guarantees reliable forecasts under cold-start (<5 observations) and mature usage (>=5 observations).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class StockPredictionService {

    private final FeatureExtractor featureExtractor;
    private final RuleBasedPredictionModel ruleBasedModel;
    private final MLStockPredictionModel mlStockModel;

    public StockPredictionResult predictDepletion(InventoryItem item, UUID userId) {
        MLFeatureVectorDto features = featureExtractor.extractFeatures(item, userId);
        return predictDepletionWithFeatures(features);
    }

    public StockPredictionResult predictDepletionWithFeatures(MLFeatureVectorDto features) {
        PredictionModel chosenModel;
        if (mlStockModel.canHandle(features)) {
            chosenModel = mlStockModel;
        } else {
            chosenModel = ruleBasedModel;
        }

        StockPredictionResult result = chosenModel.predict(features);
        log.debug("[StockPrediction] Item='{}', Model='{}', DaysRemaining={}, Prob3d={}",
                features.getItemName(), chosenModel.getModelName(),
                result.getDaysUntilEmpty(), result.getProbabilityWithin3Days());

        return result;
    }

    public MLPredictionDto getPredictionDto(InventoryItem item, UUID userId) {
        MLFeatureVectorDto features = featureExtractor.extractFeatures(item, userId);
        StockPredictionResult result = predictDepletionWithFeatures(features);

        boolean urgent = result.getDaysUntilEmpty().compareTo(new BigDecimal("2.0")) <= 0
                || result.getProbabilityWithin3Days() >= 0.80;

        String action = urgent ? "Restock immediately or add to shopping list" : "Monitor consumption rate";

        return MLPredictionDto.builder()
                .itemId(item.getId())
                .itemName(item.getName())
                .currentQuantity(item.getQuantity())
                .unit(item.getUnit())
                .predictedDaysRemaining(result.getDaysUntilEmpty())
                .probabilityWithin1Day(result.getProbabilityWithin1Day())
                .probabilityWithin3Days(result.getProbabilityWithin3Days())
                .probabilityWithin7Days(result.getProbabilityWithin7Days())
                .confidence(result.getConfidence())
                .modelName(result.getModelUsed())
                .recommendedAction(action)
                .urgent(urgent)
                .build();
    }
}
