package com.homestock.modules.away.service;

import com.homestock.modules.away.repository.PredictionFeedbackRepository;
import com.homestock.modules.consumption.entity.ConsumptionProfile;
import com.homestock.modules.consumption.repository.ConsumptionProfileRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.entity.StockTransaction;
import com.homestock.modules.inventory.repository.StockTransactionRepository;
import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class ConsumptionHistoryService {

    private final ConsumptionProfileRepository profileRepository;
    private final StockTransactionRepository stockTransactionRepository;
    private final PredictionFeedbackRepository feedbackRepository;

    @Data
    @Builder
    public static class ItemBaselineHistory {
        private UUID itemId;
        private String itemName;
        private BigDecimal stockBeforeAway;
        private BigDecimal knownPurchasesDuringAway;
        private BigDecimal baselineDailyConsumption;
        private BigDecimal consumptionVariability;
        private BigDecimal averagePurchaseInterval;
        private Integer sampleCount;
        private BigDecimal feedbackCalibrationFactor;
    }

    @Transactional(readOnly = true)
    public ItemBaselineHistory getItemHistoryBeforeAway(
            InventoryItem item,
            UUID homeId,
            Instant awayStartDate,
            Instant returnDate
    ) {
        // 1. Retrieve existing consumption profile if present
        Optional<ConsumptionProfile> profileOpt = profileRepository.findByHomeIdAndInventoryItemId(homeId, item.getId());

        BigDecimal baseVelocity = BigDecimal.ZERO;
        BigDecimal variability = new BigDecimal("0.25");
        BigDecimal purchaseInterval = BigDecimal.ZERO;
        int samples = 0;

        if (profileOpt.isPresent()) {
            ConsumptionProfile p = profileOpt.get();
            baseVelocity = p.getWeightedDailyConsumption() != null && p.getWeightedDailyConsumption().compareTo(BigDecimal.ZERO) > 0
                    ? p.getWeightedDailyConsumption()
                    : (p.getAverageDailyConsumption() != null ? p.getAverageDailyConsumption() : BigDecimal.ZERO);
            variability = p.getConsumptionVariability() != null ? p.getConsumptionVariability() : new BigDecimal("0.25");
            purchaseInterval = p.getAveragePurchaseInterval() != null ? p.getAveragePurchaseInterval() : BigDecimal.ZERO;
            samples = p.getSampleCount();
        }

        // 2. Query transactions for fallback/supplementary calculation
        List<StockTransaction> recentTx = stockTransactionRepository.findTop20ByItemIdOrderByCreatedAtDesc(item.getId());

        BigDecimal knownPurchasesDuringAway = BigDecimal.ZERO;
        BigDecimal knownDecrementsDuringAway = BigDecimal.ZERO;

        for (StockTransaction tx : recentTx) {
            if (tx.getCreatedAt().isAfter(awayStartDate) && !tx.getCreatedAt().isAfter(returnDate)) {
                if (tx.getQuantityChange() != null && tx.getQuantityChange().compareTo(BigDecimal.ZERO) > 0) {
                    knownPurchasesDuringAway = knownPurchasesDuringAway.add(tx.getQuantityChange());
                } else if (tx.getQuantityChange() != null && tx.getQuantityChange().compareTo(BigDecimal.ZERO) < 0) {
                    knownDecrementsDuringAway = knownDecrementsDuringAway.add(tx.getQuantityChange().abs());
                }
            }
        }

        // 3. Estimate stock before departure
        // Stock before away = current stock + known decrements during away - known purchases during away
        BigDecimal currentStock = item.getQuantity() != null ? item.getQuantity() : BigDecimal.ZERO;
        BigDecimal stockBeforeAway = currentStock.add(knownDecrementsDuringAway).subtract(knownPurchasesDuringAway);
        if (stockBeforeAway.compareTo(BigDecimal.ZERO) < 0) {
            stockBeforeAway = currentStock;
        }

        // If sample count in profile is low, inspect historical decrements
        if (samples < 3 && !recentTx.isEmpty()) {
            BigDecimal sumDecrements = BigDecimal.ZERO;
            int decrementCount = 0;
            for (StockTransaction tx : recentTx) {
                if (tx.getCreatedAt().isBefore(awayStartDate) && tx.getQuantityChange() != null && tx.getQuantityChange().compareTo(BigDecimal.ZERO) < 0) {
                    sumDecrements = sumDecrements.add(tx.getQuantityChange().abs());
                    decrementCount++;
                }
            }
            if (decrementCount > 0) {
                samples = Math.max(samples, decrementCount);
                if (baseVelocity.compareTo(BigDecimal.ZERO) <= 0) {
                    baseVelocity = sumDecrements.divide(BigDecimal.valueOf(Math.max(1, decrementCount * 3)), 3, RoundingMode.HALF_UP);
                }
            }
        }

        // 4. Retrieve learned user correction calibration factor for this item
        BigDecimal feedbackFactor = feedbackRepository.findAverageAdjustmentFactorByItemId(item.getId())
                .orElse(BigDecimal.ONE);

        return ItemBaselineHistory.builder()
                .itemId(item.getId())
                .itemName(item.getName())
                .stockBeforeAway(stockBeforeAway.setScale(3, RoundingMode.HALF_UP))
                .knownPurchasesDuringAway(knownPurchasesDuringAway)
                .baselineDailyConsumption(baseVelocity)
                .consumptionVariability(variability)
                .averagePurchaseInterval(purchaseInterval)
                .sampleCount(samples)
                .feedbackCalibrationFactor(feedbackFactor)
                .build();
    }
}
