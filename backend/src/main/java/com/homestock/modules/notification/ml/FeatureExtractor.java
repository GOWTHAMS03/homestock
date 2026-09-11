package com.homestock.modules.notification.ml;

import com.homestock.modules.consumption.entity.ConsumptionProfile;
import com.homestock.modules.consumption.repository.ConsumptionProfileRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.entity.StockTransaction;
import com.homestock.modules.inventory.entity.TransactionType;
import com.homestock.modules.inventory.repository.StockTransactionRepository;
import com.homestock.modules.notification.dto.MLFeatureVectorDto;
import com.homestock.modules.notification.entity.NotificationEventType;
import com.homestock.modules.notification.repository.NotificationEventRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * FeatureExtractor:
 * Extracts unified feature vectors across inventory levels, consumption history,
 * seasonal temporal patterns, and user notification engagement.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class FeatureExtractor {

    private final ConsumptionProfileRepository consumptionProfileRepository;
    private final StockTransactionRepository stockTransactionRepository;
    private final NotificationEventRepository notificationEventRepository;

    public MLFeatureVectorDto extractFeatures(InventoryItem item, UUID userId) {
        UUID homeId = item.getHome() != null ? item.getHome().getId() : null;
        UUID itemId = item.getId();

        // 1. Base Inventory Features
        BigDecimal currentStock = item.getQuantity() != null ? item.getQuantity() : BigDecimal.ZERO;
        String unit = item.getUnit() != null ? item.getUnit() : "pcs";

        // 2. Consumption Profile Features
        BigDecimal avgDaily = BigDecimal.ZERO;
        BigDecimal variance = BigDecimal.ZERO;
        BigDecimal avgInterval = BigDecimal.ZERO;
        Integer sampleCount = 0;
        Long daysSinceRestock = null;

        if (homeId != null) {
            Optional<ConsumptionProfile> profileOpt = consumptionProfileRepository.findByHomeIdAndInventoryItemId(homeId, itemId);
            if (profileOpt.isPresent()) {
                ConsumptionProfile profile = profileOpt.get();
                avgDaily = profile.getAverageDailyConsumption() != null ? profile.getAverageDailyConsumption() : BigDecimal.ZERO;
                variance = profile.getConsumptionVariability() != null ? profile.getConsumptionVariability() : BigDecimal.ZERO;
                avgInterval = profile.getAveragePurchaseInterval() != null ? profile.getAveragePurchaseInterval() : BigDecimal.ZERO;
                sampleCount = profile.getSampleCount() != null ? profile.getSampleCount() : 0;

                if (profile.getLastPurchaseDate() != null) {
                    daysSinceRestock = ChronoUnit.DAYS.between(profile.getLastPurchaseDate(), LocalDate.now());
                }
            }
        }

        // 3. Recent Velocity & Trend from Stock Transactions
        Instant sevenDaysAgo = Instant.now().minus(Duration.ofDays(7));
        List<StockTransaction> recentTx = stockTransactionRepository.findByItemIdAndCreatedAtAfter(itemId, sevenDaysAgo);

        BigDecimal recent7dConsumed = BigDecimal.ZERO;
        for (StockTransaction tx : recentTx) {
            if ((tx.getTransactionType() == TransactionType.STOCK_OUT || (tx.getQuantityChange() != null && tx.getQuantityChange().compareTo(BigDecimal.ZERO) < 0)) && tx.getQuantityChange() != null) {
                recent7dConsumed = recent7dConsumed.add(tx.getQuantityChange().abs());
            }
        }

        BigDecimal recent7dVelocity = recent7dConsumed.divide(new BigDecimal("7.0"), 4, RoundingMode.HALF_UP);
        String trend = "STABLE";
        if (avgDaily.compareTo(BigDecimal.ZERO) > 0) {
            double ratio = recent7dVelocity.doubleValue() / avgDaily.doubleValue();
            if (ratio > 1.25) trend = "ACCELERATING";
            else if (ratio < 0.75) trend = "DECELERATING";
        }

        // 4. Temporal Features
        ZonedDateTime now = ZonedDateTime.now();
        int dayOfWeek = now.getDayOfWeek().getValue(); // 1 (Mon) to 7 (Sun)
        int hourOfDay = now.getHour();

        // 5. User Notification Engagement Features
        Instant oneDayAgo = Instant.now().minus(Duration.ofHours(24));
        Instant oneHourAgo = Instant.now().minus(Duration.ofHours(1));

        long count24h = userId != null ? notificationEventRepository.countTotalByUserIdSince(userId, oneDayAgo) : 0;
        long count1h = userId != null ? notificationEventRepository.countTotalByUserIdSince(userId, oneHourAgo) : 0;

        long openedTotal = userId != null ? notificationEventRepository.countByUserIdAndEventTypeSince(userId, NotificationEventType.OPENED, Instant.EPOCH) : 0;
        long clickedTotal = userId != null ? notificationEventRepository.countByUserIdAndEventTypeSince(userId, NotificationEventType.CLICKED, Instant.EPOCH) : 0;
        long dismissedTotal = userId != null ? notificationEventRepository.countByUserIdAndEventTypeSince(userId, NotificationEventType.DISMISSED, Instant.EPOCH) : 0;
        long actionsTotal = userId != null ? notificationEventRepository.countByUserIdAndEventTypeSince(userId, NotificationEventType.ACTION_TAKEN, Instant.EPOCH) : 0;
        long sentTotal = userId != null ? notificationEventRepository.countByUserIdAndEventTypeSince(userId, NotificationEventType.SENT, Instant.EPOCH) : 0;

        double openRate = sentTotal > 0 ? (double) (openedTotal + clickedTotal) / sentTotal : 0.65;
        double dismissRate = sentTotal > 0 ? (double) dismissedTotal / sentTotal : 0.15;
        double actionRate = sentTotal > 0 ? (double) actionsTotal / sentTotal : 0.45;

        // Family activity rate: actions by other members in the same home
        double familyActivityRate = 0.50;
        if (homeId != null) {
            long homeActions = notificationEventRepository.countHomeEventsByEventTypeSince(homeId, NotificationEventType.ACTION_TAKEN, oneDayAgo);
            familyActivityRate = Math.min(1.0, homeActions * 0.25);
        }

        return MLFeatureVectorDto.builder()
                .itemId(itemId)
                .userId(userId)
                .homeId(homeId)
                .itemName(item.getName())
                .currentStock(currentStock)
                .unit(unit)
                .averageConsumptionPerDay(avgDaily)
                .medianConsumption(avgDaily)
                .consumptionVariance(variance)
                .consumptionVelocity(recent7dVelocity)
                .daysSinceLastRestock(daysSinceRestock)
                .averageRestockInterval(avgInterval)
                .purchaseFrequency(avgInterval.compareTo(BigDecimal.ZERO) > 0 ? 30.0 / avgInterval.doubleValue() : 1.0)
                .recentUsageTrend(trend)
                .sampleCount(sampleCount)
                .dayOfWeek(dayOfWeek)
                .hourOfDay(hourOfDay)
                .notificationCount24h(count24h)
                .notificationCount1h(count1h)
                .notificationOpenRate(openRate)
                .notificationDismissRate(dismissRate)
                .userActionRate(actionRate)
                .familyActivityRate(familyActivityRate)
                .previousNotificationSuccessRate(actionRate)
                .build();
    }
}
