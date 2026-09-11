package com.homestock.modules.away.service;

import com.homestock.modules.away.repository.UserActivityLogRepository;
import com.homestock.modules.inventory.entity.StockTransaction;
import com.homestock.modules.inventory.repository.StockTransactionRepository;
import com.homestock.modules.notification.repository.DeviceTokenRepository;
import com.homestock.modules.purchase.entity.Purchase;
import com.homestock.modules.purchase.repository.PurchaseRepository;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AwayPeriodDetector {

    private final UserActivityLogRepository activityLogRepository;
    private final StockTransactionRepository stockTransactionRepository;
    private final PurchaseRepository purchaseRepository;
    private final ShoppingListItemRepository shoppingListItemRepository;
    private final DeviceTokenRepository deviceTokenRepository;

    @Value("${app.away-summary.min-inactive-days:3}")
    private int minInactiveDays = 3;

    @Data
    @Builder
    public static class DetectionResult {
        private boolean isAway;
        private int awayDays;
        private Instant lastMeaningfulActivityDate;
        private Instant returnDate;
        private List<String> familyActivityDuringAway;
        private long previousWeeklyActiveDays;
    }

    @Transactional(readOnly = true)
    public DetectionResult detectInactivity(UUID userId, UUID homeId) {
        Instant now = Instant.now();
        List<Instant> candidateActivityTimes = new ArrayList<>();

        // 1. App open / heartbeat activity
        activityLogRepository.findLatestActivityByUserId(userId).ifPresent(candidateActivityTimes::add);

        // 2. Last inventory update by user
        stockTransactionRepository.findLatestTransactionTimeByUserId(userId).ifPresent(candidateActivityTimes::add);

        // 3. Last purchase recorded by user
        purchaseRepository.findLatestPurchaseTimeByUserId(userId).ifPresent(candidateActivityTimes::add);

        // 4. Last shopping list modification by user
        shoppingListItemRepository.findLatestAddedTimeByUserId(userId).ifPresent(candidateActivityTimes::add);

        // 5. Last device token usage
        deviceTokenRepository.findLatestActivityByUserId(userId).ifPresent(candidateActivityTimes::add);

        // If no prior activity exists at all, this is a fresh user; return not away
        if (candidateActivityTimes.isEmpty()) {
            log.debug("[AwayPeriodDetector] No prior activity records found for user {}. Treating as active/new.", userId);
            return DetectionResult.builder()
                    .isAway(false)
                    .awayDays(0)
                    .lastMeaningfulActivityDate(now)
                    .returnDate(now)
                    .familyActivityDuringAway(List.of())
                    .previousWeeklyActiveDays(0)
                    .build();
        }

        // Determine most recent meaningful activity date
        Instant lastMeaningful = candidateActivityTimes.stream()
                .max(Instant::compareTo)
                .orElse(now);

        long inactiveDays = ChronoUnit.DAYS.between(lastMeaningful, now);

        // 6. Check family member activity during the user's away period
        List<String> familyEvents = new ArrayList<>();
        if (inactiveDays >= minInactiveDays && homeId != null) {
            List<StockTransaction> familyTx = stockTransactionRepository.findFamilyTransactionsSince(homeId, userId, lastMeaningful);
            for (StockTransaction tx : familyTx) {
                if (familyEvents.size() >= 5) break;
                String actorName = tx.getUser() != null ? tx.getUser().getFullName() : "A family member";
                String itemName = tx.getItem() != null ? tx.getItem().getName() : "Item";
                familyEvents.add(String.format("%s updated %s stock to %s %s", actorName, itemName, tx.getNewQuantity(), tx.getUnit()));
            }

            List<Purchase> familyPurchases = purchaseRepository.findFamilyPurchasesSince(homeId, userId, lastMeaningful);
            for (Purchase p : familyPurchases) {
                if (familyEvents.size() >= 5) break;
                String actorName = p.getRecordedBy() != null ? p.getRecordedBy().getFullName() : "A family member";
                familyEvents.add(String.format("%s recorded a grocery purchase (₹%s)", actorName, p.getTotalAmount()));
            }
        }

        // 7. Previous usage frequency (active days over prior 30 days)
        Instant thirtyDaysBeforeAway = lastMeaningful.minus(30, ChronoUnit.DAYS);
        long activeDaysCount = activityLogRepository.countDistinctActiveDaysSince(userId, thirtyDaysBeforeAway);

        boolean isAway = inactiveDays >= minInactiveDays;

        log.info("[AwayPeriodDetector] User {} home {}: lastMeaningful={}, inactiveDays={}, isAway={}",
                userId, homeId, lastMeaningful, inactiveDays, isAway);

        return DetectionResult.builder()
                .isAway(isAway)
                .awayDays((int) inactiveDays)
                .lastMeaningfulActivityDate(lastMeaningful)
                .returnDate(now)
                .familyActivityDuringAway(familyEvents)
                .previousWeeklyActiveDays(activeDaysCount)
                .build();
    }
}
