package com.homestock.modules.consumption.service;

import com.homestock.modules.consumption.entity.ConfidenceLevel;
import com.homestock.modules.consumption.entity.ConsumptionCycle;
import com.homestock.modules.consumption.entity.ConsumptionProfile;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.purchase.entity.PurchaseItem;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;

@Slf4j
@Service
public class ConsumptionCalculationService {

    private static final BigDecimal ANOMALY_HIGH_FACTOR = new BigDecimal("2.2");
    private static final BigDecimal ANOMALY_LOW_FACTOR = new BigDecimal("0.35");
    private static final BigDecimal RECENCY_DECAY = new BigDecimal("0.75");
    private static final BigDecimal ANOMALY_WEIGHT_MULTIPLIER = new BigDecimal("0.20");

    /**
     * Reconstruct and extract consumption cycles from sorted purchase items.
     * PurchaseItems must be sorted by purchase date ascending.
     */
    public List<ConsumptionCycle> buildCyclesFromPurchases(Home home, InventoryItem item, List<PurchaseItem> purchaseItems) {
        List<ConsumptionCycle> cycles = new ArrayList<>();
        if (purchaseItems == null || purchaseItems.size() < 2) {
            return cycles;
        }

        // Filter valid purchase items with dates and positive quantities
        List<PurchaseItem> validPurchases = purchaseItems.stream()
                .filter(p -> p.getPurchase() != null && p.getPurchase().getPurchaseDate() != null)
                .filter(p -> p.getQuantity() != null && p.getQuantity().compareTo(BigDecimal.ZERO) > 0)
                .sorted(Comparator.comparing(p -> p.getPurchase().getPurchaseDate()))
                .toList();

        if (validPurchases.size() < 2) {
            return cycles;
        }

        // Calculate raw intervals first to determine median interval for anomaly detection
        List<Integer> intervals = new ArrayList<>();
        for (int i = 1; i < validPurchases.size(); i++) {
            LocalDate prevDate = validPurchases.get(i - 1).getPurchase().getPurchaseDate();
            LocalDate currDate = validPurchases.get(i).getPurchase().getPurchaseDate();
            long days = ChronoUnit.DAYS.between(prevDate, currDate);
            if (days > 0) {
                intervals.add((int) days);
            }
        }

        if (intervals.isEmpty()) {
            return cycles;
        }

        // Median interval
        List<Integer> sortedIntervals = new ArrayList<>(intervals);
        Collections.sort(sortedIntervals);
        double medianInterval = sortedIntervals.get(sortedIntervals.size() / 2);

        for (int i = 1; i < validPurchases.size(); i++) {
            PurchaseItem prev = validPurchases.get(i - 1);
            PurchaseItem curr = validPurchases.get(i);
            LocalDate prevDate = prev.getPurchase().getPurchaseDate();
            LocalDate currDate = curr.getPurchase().getPurchaseDate();

            long daysBetween = ChronoUnit.DAYS.between(prevDate, currDate);
            if (daysBetween <= 0) {
                continue; // Ignore same-day duplicate purchases or re-entries
            }

            int intervalDays = (int) daysBetween;
            BigDecimal previousQty = prev.getQuantity();

            BigDecimal dailyUsage = previousQty.divide(BigDecimal.valueOf(intervalDays), 4, RoundingMode.HALF_UP);

            boolean isAnomaly = false;
            String anomalyReason = null;

            if (medianInterval >= 3.0) {
                if (BigDecimal.valueOf(intervalDays).compareTo(BigDecimal.valueOf(medianInterval).multiply(ANOMALY_HIGH_FACTOR)) > 0) {
                    isAnomaly = true;
                    anomalyReason = "Unusual long gap (" + intervalDays + " days vs median " + (int) medianInterval + " days, e.g. vacation or dining out)";
                } else if (BigDecimal.valueOf(intervalDays).compareTo(BigDecimal.valueOf(medianInterval).multiply(ANOMALY_LOW_FACTOR)) < 0) {
                    isAnomaly = true;
                    anomalyReason = "Unusual quick restock (" + intervalDays + " days vs median " + (int) medianInterval + " days, e.g. festival or sale)";
                }
            }

            ConfidenceLevel cycleConfidence = isAnomaly ? ConfidenceLevel.LOW :
                    (intervalDays >= 3 && intervalDays <= 30 ? ConfidenceLevel.HIGH : ConfidenceLevel.MEDIUM);

            ConsumptionCycle cycle = ConsumptionCycle.builder()
                    .home(home)
                    .inventoryItem(item)
                    .product(item.getProduct())
                    .previousPurchase(prev.getPurchase())
                    .currentPurchase(curr.getPurchase())
                    .previousPurchaseDate(prevDate)
                    .currentPurchaseDate(currDate)
                    .quantity(previousQty)
                    .intervalDays(intervalDays)
                    .estimatedDailyConsumption(dailyUsage)
                    .isAnomaly(isAnomaly)
                    .anomalyReason(anomalyReason)
                    .confidence(cycleConfidence)
                    .build();

            cycles.add(cycle);
        }

        return cycles;
    }

    /**
     * Compute or update a ConsumptionProfile using historical cycles and recent item status.
     */
    public ConsumptionProfile calculateProfile(Home home, InventoryItem item, List<ConsumptionCycle> cycles, ConsumptionProfile existingProfile) {
        ConsumptionProfile profile = existingProfile != null ? existingProfile : ConsumptionProfile.builder()
                .home(home)
                .inventoryItem(item)
                .product(item.getProduct())
                .build();

        if (cycles == null || cycles.isEmpty()) {
            // Default initial profile based on item initial settings or minimum quantity fallback
            BigDecimal defaultDaily = item.getMinimumQuantity().divide(BigDecimal.valueOf(7), 4, RoundingMode.HALF_UP);
            profile.setAverageDailyConsumption(defaultDaily);
            profile.setWeightedDailyConsumption(defaultDaily);
            profile.setMinDailyConsumption(defaultDaily.multiply(new BigDecimal("0.8")).setScale(4, RoundingMode.HALF_UP));
            profile.setMaxDailyConsumption(defaultDaily.multiply(new BigDecimal("1.2")).setScale(4, RoundingMode.HALF_UP));
            profile.setConsumptionVariability(BigDecimal.ZERO);
            profile.setAveragePurchaseInterval(new BigDecimal("7.0"));
            profile.setConfidence(ConfidenceLevel.LOW);
            profile.setSampleCount(0);
            profile.setLastCalculatedAt(Instant.now());
            return profile;
        }

        // Sort cycles descending (newest first)
        List<ConsumptionCycle> sortedCycles = cycles.stream()
                .sorted(Comparator.comparing(ConsumptionCycle::getCurrentPurchaseDate).reversed())
                .toList();

        // 1. Calculate Simple Average and Min/Max
        BigDecimal sumUsage = BigDecimal.ZERO;
        BigDecimal sumInterval = BigDecimal.ZERO;
        BigDecimal minDaily = sortedCycles.get(0).getEstimatedDailyConsumption();
        BigDecimal maxDaily = sortedCycles.get(0).getEstimatedDailyConsumption();

        for (ConsumptionCycle c : sortedCycles) {
            BigDecimal usage = c.getEstimatedDailyConsumption();
            sumUsage = sumUsage.add(usage);
            sumInterval = sumInterval.add(BigDecimal.valueOf(c.getIntervalDays()));
            if (usage.compareTo(minDaily) < 0) minDaily = usage;
            if (usage.compareTo(maxDaily) > 0) maxDaily = usage;
        }

        int totalCount = sortedCycles.size();
        BigDecimal avgDaily = sumUsage.divide(BigDecimal.valueOf(totalCount), 4, RoundingMode.HALF_UP);
        BigDecimal avgInterval = sumInterval.divide(BigDecimal.valueOf(totalCount), 2, RoundingMode.HALF_UP);

        // 2. Calculate Recency-Weighted Average
        BigDecimal totalWeightedUsage = BigDecimal.ZERO;
        BigDecimal totalWeight = BigDecimal.ZERO;

        for (int k = 0; k < sortedCycles.size(); k++) {
            ConsumptionCycle c = sortedCycles.get(k);
            BigDecimal weight = BigDecimal.valueOf(Math.pow(RECENCY_DECAY.doubleValue(), k));
            if (Boolean.TRUE.equals(c.getIsAnomaly())) {
                weight = weight.multiply(ANOMALY_WEIGHT_MULTIPLIER);
            }
            totalWeightedUsage = totalWeightedUsage.add(c.getEstimatedDailyConsumption().multiply(weight));
            totalWeight = totalWeight.add(weight);
        }

        BigDecimal weightedDaily = totalWeight.compareTo(BigDecimal.ZERO) > 0
                ? totalWeightedUsage.divide(totalWeight, 4, RoundingMode.HALF_UP)
                : avgDaily;

        // 3. Calculate Variance & Variability (Coefficient of Variation)
        double varianceSum = 0.0;
        for (ConsumptionCycle c : sortedCycles) {
            double diff = c.getEstimatedDailyConsumption().doubleValue() - avgDaily.doubleValue();
            varianceSum += (diff * diff);
        }
        double stdDev = Math.sqrt(varianceSum / totalCount);
        double variability = avgDaily.doubleValue() > 0 ? (stdDev / avgDaily.doubleValue()) : 0.0;

        // 4. Confidence Evaluation
        ConfidenceLevel confidence;
        long normalCyclesCount = sortedCycles.stream().filter(c -> !Boolean.TRUE.equals(c.getIsAnomaly())).count();

        if (normalCyclesCount >= 4 && variability <= 0.40) {
            confidence = ConfidenceLevel.HIGH;
        } else if (normalCyclesCount >= 2 && variability <= 0.70) {
            confidence = ConfidenceLevel.MEDIUM;
        } else {
            confidence = ConfidenceLevel.LOW;
        }

        // 5. Last Purchase Information
        ConsumptionCycle newestCycle = sortedCycles.get(0);
        profile.setLastPurchaseDate(newestCycle.getCurrentPurchaseDate());
        profile.setLastPurchaseQuantity(newestCycle.getQuantity());

        profile.setAverageDailyConsumption(avgDaily);
        profile.setWeightedDailyConsumption(weightedDaily);
        profile.setMinDailyConsumption(minDaily);
        profile.setMaxDailyConsumption(maxDaily);
        profile.setConsumptionVariability(BigDecimal.valueOf(variability).setScale(4, RoundingMode.HALF_UP));
        profile.setAveragePurchaseInterval(avgInterval);
        profile.setConfidence(confidence);
        profile.setSampleCount(totalCount);
        profile.setLastCalculatedAt(Instant.now());

        return profile;
    }

    /**
     * Generate human-readable confidence explanation without false precision.
     */
    public String getConfidenceExplanation(ConfidenceLevel level, int sampleCount, BigDecimal avgInterval, String itemName) {
        int intervalInt = avgInterval != null ? avgInterval.setScale(0, RoundingMode.HALF_UP).intValue() : 7;
        if (level == ConfidenceLevel.HIGH) {
            return "Based on " + sampleCount + " recent purchase cycles, your household usually consumes " + itemName + " every " + intervalInt + " days.";
        } else if (level == ConfidenceLevel.MEDIUM) {
            return "Based on your recent purchases, " + itemName + " may run low in about " + intervalInt + " days.";
        } else {
            return "We're still learning how quickly your home uses " + itemName + ".";
        }
    }

    /**
     * Format natural range display text (e.g. "Uses 5 kg every 6–8 days" or "~650–750 g/day").
     */
    public String formatTypicalRangeText(BigDecimal minDaily, BigDecimal maxDaily, BigDecimal avgInterval, String unit, BigDecimal packageSize) {
        if (minDaily == null || maxDaily == null || minDaily.compareTo(BigDecimal.ZERO) == 0) {
            return "Typical consumption estimate in progress";
        }

        int interval = avgInterval != null && avgInterval.compareTo(BigDecimal.ZERO) > 0
                ? avgInterval.setScale(0, RoundingMode.HALF_UP).intValue() : 7;
        int minInterval = Math.max(1, interval - 1);
        int maxInterval = interval + 2;

        if (packageSize != null && packageSize.compareTo(BigDecimal.ZERO) > 0) {
            return "Your home usually uses " + packageSize.stripTrailingZeros().toPlainString() + " " + unit + " every " + minInterval + "–" + maxInterval + " days.";
        }

        return "Usually consumed every " + minInterval + "–" + maxInterval + " days.";
    }
}
