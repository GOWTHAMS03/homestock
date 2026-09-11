package com.homestock.modules.away.service;

import com.homestock.modules.away.entity.AwayPredictionType;
import com.homestock.modules.inventory.entity.InventoryItem;
import lombok.Builder;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Optional;

@Slf4j
@Service
public class RestockPredictionService {

    @Data
    @Builder
    public static class RestockRequirementResult {
        private AwayPredictionType predictionType;
        private boolean needsRestock;
        private double cyclesMissed;
        private Double confidence;
        private String confidenceLabel;
        private String displayTitle;
        private String displaySubtitle;
        private String reason;
    }

    public Optional<RestockRequirementResult> evaluateRestockCycle(
            InventoryItem item,
            BigDecimal averagePurchaseInterval,
            long awayDays,
            BigDecimal estimatedRemainingStock
    ) {
        if (averagePurchaseInterval == null || averagePurchaseInterval.compareTo(BigDecimal.ZERO) <= 0) {
            return Optional.empty();
        }

        double interval = averagePurchaseInterval.doubleValue();
        double cyclesMissed = awayDays / interval;

        // If awayDays is at least 1.2x the usual replenishment cycle and estimated stock is low
        if (cyclesMissed >= 1.2) {
            double confidence = Math.min(0.92, 0.50 + Math.min(0.40, (cyclesMissed - 1.0) * 0.20));
            long confPct = Math.round(confidence * 100);

            String title = "Restock likely needed";
            String subtitle = String.format("You usually restock every ~%d days. %d days have elapsed.",
                    Math.round(interval), awayDays);
            String reason = String.format("Usual purchase cycle of ~%s days missed during absence",
                    averagePurchaseInterval.setScale(1, RoundingMode.HALF_UP));

            return Optional.of(RestockRequirementResult.builder()
                    .predictionType(AwayPredictionType.RESTOCK_RECOMMENDED)
                    .needsRestock(true)
                    .cyclesMissed(cyclesMissed)
                    .confidence(confidence)
                    .confidenceLabel(confPct + "% confidence")
                    .displayTitle(title)
                    .displaySubtitle(subtitle)
                    .reason(reason)
                    .build());
        }

        return Optional.empty();
    }
}
