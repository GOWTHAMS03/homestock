package com.homestock.modules.away.service;

import com.homestock.modules.away.entity.AwayPredictionType;
import com.homestock.modules.away.entity.PredictionEventClassification;
import com.homestock.modules.away.ml.StatisticalAwayPredictor;
import com.homestock.modules.inventory.entity.InventoryItem;
import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;

@Slf4j
@Service
@RequiredArgsConstructor
public class InventoryPredictionService {

    private final StatisticalAwayPredictor awayPredictor;
    private final PredictionConfidenceService confidenceService;

    @Data
    @Builder
    public static class InventoryPredictionResult {
        private AwayPredictionType predictionType;
        private PredictionEventClassification eventClassification;
        private BigDecimal stockBeforeAway;
        private BigDecimal estimatedQuantity;
        private BigDecimal estimatedConsumed;
        private Double confidence;
        private String confidenceLabel;
        private String reason;
        private String displayTitle;
        private String displaySubtitle;
        private String actionLabel;
        private boolean isProminent;
        private boolean isColdStart;
    }

    public InventoryPredictionResult predictInventoryChange(
            InventoryItem item,
            ConsumptionHistoryService.ItemBaselineHistory history,
            LocalDate awayStart,
            LocalDate awayEnd
    ) {
        long awayDays = ChronoUnit.DAYS.between(awayStart, awayEnd);
        if (awayDays <= 0) awayDays = 1;

        BigDecimal stockBefore = history.getStockBeforeAway();
        BigDecimal purchasesDuringAway = history.getKnownPurchasesDuringAway();
        BigDecimal effectiveStockBefore = stockBefore.add(purchasesDuringAway);

        // Run ML statistical prediction
        StatisticalAwayPredictor.AwayPredictionInput mlInput = StatisticalAwayPredictor.AwayPredictionInput.builder()
                .itemName(item.getName())
                .currentStockBeforeAway(effectiveStockBefore)
                .baselineDailyConsumption(history.getBaselineDailyConsumption())
                .consumptionVariability(history.getConsumptionVariability())
                .sampleCount(history.getSampleCount())
                .awayStartDate(awayStart)
                .awayEndDate(awayEnd)
                .feedbackCalibrationFactor(history.getFeedbackCalibrationFactor())
                .build();

        StatisticalAwayPredictor.AwayPredictionResult mlResult = awayPredictor.predict(mlInput);

        BigDecimal estimatedConsumed = mlResult.getEstimatedConsumption();
        BigDecimal estimatedRemaining = mlResult.getEstimatedRemainingStock();

        // Calculate confidence
        boolean hasFeedback = history.getFeedbackCalibrationFactor() != null &&
                history.getFeedbackCalibrationFactor().compareTo(BigDecimal.ONE) != 0;
        double confidence = confidenceService.calculateConfidence(
                history.getSampleCount(),
                history.getConsumptionVariability(),
                awayDays,
                hasFeedback
        );
        String confidenceLabel = confidenceService.formatConfidenceLabel(confidence);
        boolean prominent = confidenceService.isProminent(confidence);

        // Determine item classification & state
        AwayPredictionType type;
        String displayTitle;
        String displaySubtitle;
        String actionLabel;
        String unit = item.getUnit() != null ? item.getUnit() : "units";

        if (mlResult.isColdStart()) {
            type = AwayPredictionType.NORMAL;
            displayTitle = "Observing household usage";
            displaySubtitle = "Not enough history to predict this item yet";
            actionLabel = "Review";
        } else if (effectiveStockBefore.compareTo(BigDecimal.ZERO) <= 0 || estimatedConsumed.compareTo(effectiveStockBefore) >= 0) {
            type = AwayPredictionType.LIKELY_RAN_OUT;
            displayTitle = "Probably ran out";
            displaySubtitle = String.format("Based on your usual usage (~%s %s may have been used)",
                    estimatedConsumed.stripTrailingZeros().toPlainString(), unit);
            actionLabel = "Add to Shopping List";
        } else {
            // Check if remaining stock is low compared to minimum threshold or 25% of stock
            BigDecimal minStock = item.getMinimumQuantity() != null && item.getMinimumQuantity().compareTo(BigDecimal.ZERO) > 0
                    ? item.getMinimumQuantity()
                    : effectiveStockBefore.multiply(new BigDecimal("0.25"));

            if (estimatedRemaining.compareTo(minStock) <= 0) {
                type = AwayPredictionType.LIKELY_LOW;
                displayTitle = "Likely running low";
                displaySubtitle = String.format("~%s %s estimated remaining",
                        estimatedRemaining.stripTrailingZeros().toPlainString(), unit);
                actionLabel = "Add to Shopping List";
            } else {
                type = AwayPredictionType.NORMAL;
                displayTitle = "Likely well-stocked";
                displaySubtitle = String.format("~%s %s estimated remaining",
                        estimatedRemaining.stripTrailingZeros().toPlainString(), unit);
                actionLabel = "Looks right";
            }
        }

        String reason = mlResult.isColdStart()
                ? "Still learning your household's usage pattern."
                : String.format("Based on average consumption during previous %d days",
                        Math.max(14, history.getSampleCount() * 3));

        return InventoryPredictionResult.builder()
                .predictionType(type)
                .eventClassification(PredictionEventClassification.PREDICTED_EVENT)
                .stockBeforeAway(stockBefore)
                .estimatedQuantity(estimatedRemaining)
                .estimatedConsumed(estimatedConsumed)
                .confidence(confidence)
                .confidenceLabel(confidenceLabel)
                .reason(reason)
                .displayTitle(displayTitle)
                .displaySubtitle(displaySubtitle)
                .actionLabel(actionLabel)
                .isProminent(prominent && !mlResult.isColdStart())
                .isColdStart(mlResult.isColdStart())
                .build();
    }
}
