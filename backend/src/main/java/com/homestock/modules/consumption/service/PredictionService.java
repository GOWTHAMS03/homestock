package com.homestock.modules.consumption.service;

import com.homestock.modules.consumption.dto.PredictionDto;
import com.homestock.modules.consumption.entity.ConfidenceLevel;
import com.homestock.modules.consumption.entity.ConsumptionProfile;
import com.homestock.modules.consumption.entity.PredictionStatus;
import com.homestock.modules.consumption.entity.QuantitySource;
import com.homestock.modules.inventory.entity.InventoryItem;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

@Slf4j
@Service
@RequiredArgsConstructor
public class PredictionService {

    private final StockEstimationService stockEstimationService;
    private final ConsumptionCalculationService calculationService;

    public PredictionDto predictItemStock(InventoryItem item, ConsumptionProfile profile) {
        BigDecimal effectiveQty = stockEstimationService.estimateCurrentQuantity(item, profile);
        Integer daysRemaining = stockEstimationService.calculateDaysRemaining(effectiveQty, profile);
        String formattedQty = stockEstimationService.formatStockDisplay(item, effectiveQty, daysRemaining);

        PredictionStatus status;
        String predictionText;
        String suggestedAction;

        if (effectiveQty.compareTo(BigDecimal.ZERO) <= 0) {
            status = PredictionStatus.OUT_OF_STOCK;
            predictionText = "Out of stock";
            suggestedAction = "ADD_TO_SHOPPING";
        } else if (daysRemaining != null && daysRemaining <= 1) {
            status = PredictionStatus.LIKELY_TO_RUN_OUT;
            predictionText = "Likely to run out today";
            suggestedAction = "ADD_TO_SHOPPING";
        } else if ((daysRemaining != null && daysRemaining <= 3) ||
                (effectiveQty.compareTo(item.getMinimumQuantity()) <= 0)) {
            status = PredictionStatus.LOW;
            int minDays = daysRemaining != null ? Math.max(1, daysRemaining - 1) : 2;
            int maxDays = daysRemaining != null ? daysRemaining + 1 : 3;
            predictionText = "Likely low in " + minDays + "–" + maxDays + " days";
            suggestedAction = "CHECK_STOCK";
        } else if (daysRemaining != null && daysRemaining <= 7) {
            status = PredictionStatus.WATCH;
            predictionText = "May run low this week (approx " + daysRemaining + " days left)";
            suggestedAction = "NONE";
        } else {
            status = PredictionStatus.SAFE;
            int days = daysRemaining != null ? daysRemaining : 14;
            predictionText = "Likely enough for " + days + "+ days";
            suggestedAction = "NONE";
        }

        ConfidenceLevel confidence = profile != null ? profile.getConfidence() : ConfidenceLevel.LOW;
        int sampleCount = profile != null ? profile.getSampleCount() : 0;
        BigDecimal interval = profile != null ? profile.getAveragePurchaseInterval() : BigDecimal.valueOf(7);
        String confidenceText = calculationService.getConfidenceExplanation(confidence, sampleCount, interval, item.getName());

        QuantitySource source = item.getQuantitySource() != null ? item.getQuantitySource() :
                (daysRemaining != null && daysRemaining < 30 ? QuantitySource.ESTIMATED : QuantitySource.VERIFIED);

        return PredictionDto.builder()
                .itemId(item.getId())
                .itemName(item.getName())
                .categoryName(item.getCategory() != null ? item.getCategory().getName() : "General")
                .currentQuantity(effectiveQty)
                .formattedQuantity(formattedQty)
                .unit(item.getUnit())
                .quantityStatus(item.getQuantityStatus())
                .quantitySource(source)
                .predictionStatus(status)
                .estimatedDaysRemaining(daysRemaining)
                .predictionRangeText(predictionText)
                .confidence(confidence)
                .confidenceText(confidenceText)
                .suggestedAction(suggestedAction)
                .build();
    }
}
