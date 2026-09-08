package com.homestock.modules.consumption.service;

import com.homestock.modules.consumption.entity.ConsumptionProfile;
import com.homestock.modules.consumption.entity.QuantitySource;
import com.homestock.modules.consumption.entity.QuantityStatus;
import com.homestock.modules.inventory.entity.InventoryItem;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;

@Slf4j
@Service
public class StockEstimationService {

    /**
     * Passively estimate current remaining quantity for an item based on days elapsed and consumption rate.
     */
    public BigDecimal estimateCurrentQuantity(InventoryItem item, ConsumptionProfile profile) {
        if (item == null) return BigDecimal.ZERO;

        BigDecimal baseQty = item.getQuantity() != null ? item.getQuantity() : BigDecimal.ZERO;
        if (baseQty.compareTo(BigDecimal.ZERO) <= 0) {
            return BigDecimal.ZERO;
        }

        // If no consumption model is available yet, return the last known quantity
        if (profile == null || profile.getWeightedDailyConsumption() == null ||
                profile.getWeightedDailyConsumption().compareTo(BigDecimal.ZERO) <= 0) {
            return baseQty;
        }

        // Determine reference date (lastVerifiedAt, purchaseDate, or updatedAt)
        LocalDate referenceDate = null;
        if (item.getLastVerifiedAt() != null) {
            referenceDate = item.getLastVerifiedAt().atZone(ZoneId.systemDefault()).toLocalDate();
        } else if (item.getPurchaseDate() != null) {
            referenceDate = item.getPurchaseDate();
        } else if (item.getUpdatedAt() != null) {
            referenceDate = item.getUpdatedAt().atZone(ZoneId.systemDefault()).toLocalDate();
        }

        if (referenceDate == null) {
            return baseQty;
        }

        long daysPassed = ChronoUnit.DAYS.between(referenceDate, LocalDate.now());
        if (daysPassed <= 0) {
            return baseQty;
        }

        BigDecimal dailyUsage = profile.getWeightedDailyConsumption();
        BigDecimal estimatedUsage = dailyUsage.multiply(BigDecimal.valueOf(daysPassed));

        BigDecimal remaining = baseQty.subtract(estimatedUsage);
        return remaining.compareTo(BigDecimal.ZERO) > 0 ? remaining : BigDecimal.ZERO;
    }

    /**
     * Compute estimated days remaining until stock reaches 0.
     */
    public Integer calculateDaysRemaining(BigDecimal currentStock, ConsumptionProfile profile) {
        if (currentStock == null || currentStock.compareTo(BigDecimal.ZERO) <= 0) {
            return 0;
        }

        if (profile == null || profile.getWeightedDailyConsumption() == null ||
                profile.getWeightedDailyConsumption().compareTo(BigDecimal.ZERO) <= 0) {
            return null; // Cannot predict accurately without consumption model
        }

        BigDecimal daily = profile.getWeightedDailyConsumption();
        BigDecimal days = currentStock.divide(daily, 0, RoundingMode.HALF_UP);
        return days.intValue();
    }

    /**
     * Format friendly stock quantity text without false decimal precision.
     * Examples: "~2 kg left", "About half left", "Likely enough for 3–4 days".
     */
    public String formatStockDisplay(InventoryItem item, BigDecimal currentStock, Integer daysRemaining) {
        if (currentStock == null || currentStock.compareTo(BigDecimal.ZERO) <= 0) {
            return "Out of stock";
        }

        // If qualitative status was explicitly confirmed
        if (item.getQuantityStatus() != null && item.getQuantitySource() == QuantitySource.VERIFIED) {
            return item.getQuantityStatus().getDisplayName();
        }

        String unit = item.getUnit() != null ? item.getUnit().trim() : "pcs";
        boolean isEstimated = item.getQuantitySource() == QuantitySource.ESTIMATED;

        // Simplify number: round to whole integer or single decimal if small
        String numberStr;
        if (currentStock.compareTo(BigDecimal.valueOf(5)) >= 0) {
            numberStr = String.valueOf(currentStock.setScale(0, RoundingMode.HALF_UP).intValue());
        } else if (currentStock.compareTo(BigDecimal.ONE) >= 0) {
            numberStr = currentStock.setScale(1, RoundingMode.HALF_UP).stripTrailingZeros().toPlainString();
        } else {
            numberStr = currentStock.setScale(2, RoundingMode.HALF_UP).stripTrailingZeros().toPlainString();
        }

        if (isEstimated) {
            if (daysRemaining != null && daysRemaining > 0 && daysRemaining <= 7) {
                int minDays = Math.max(1, daysRemaining - 1);
                int maxDays = daysRemaining + 1;
                return "Likely enough for " + minDays + "–" + maxDays + " days";
            }
            return "~" + numberStr + " " + unit + " left";
        }

        return numberStr + " " + unit;
    }
}
