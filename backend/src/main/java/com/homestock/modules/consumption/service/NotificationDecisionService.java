package com.homestock.modules.consumption.service;

import com.homestock.modules.consumption.dto.PredictionDto;
import com.homestock.modules.consumption.entity.PredictionStatus;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.notification.entity.NotificationType;
import com.homestock.modules.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationDecisionService {

    private final NotificationService notificationService;

    // Cooldown tracker: itemId -> timestamp of last notification
    private final Map<UUID, Long> itemNotificationCooldowns = new ConcurrentHashMap<>();
    private static final long COOLDOWN_MILLIS = 48L * 60 * 60 * 1000; // 48 hours

    // Default quiet hours: 22:00 to 08:00
    private static final LocalTime QUIET_HOURS_START = LocalTime.of(22, 0);
    private static final LocalTime QUIET_HOURS_END = LocalTime.of(8, 0);

    /**
     * Evaluate batch of predicted items and decide whether to send individual or grouped notifications.
     */
    public void evaluateAndNotify(Home home, List<PredictionDto> predictions) {
        if (home == null || predictions == null || predictions.isEmpty()) {
            return;
        }

        // 1. Quiet Hours check
        if (isQuietHours()) {
            log.debug("Suppressing notification for home {}: currently in quiet hours", home.getId());
            return;
        }

        long now = System.currentTimeMillis();

        // 2. Filter items needing notification that are not on cooldown
        List<PredictionDto> actionableItems = predictions.stream()
                .filter(p -> p.getPredictionStatus() == PredictionStatus.OUT_OF_STOCK ||
                             p.getPredictionStatus() == PredictionStatus.LIKELY_TO_RUN_OUT ||
                             p.getPredictionStatus() == PredictionStatus.LOW)
                .filter(p -> {
                    Long lastNotified = itemNotificationCooldowns.get(p.getItemId());
                    return lastNotified == null || (now - lastNotified) > COOLDOWN_MILLIS;
                })
                .toList();

        if (actionableItems.isEmpty()) {
            return;
        }

        // 3. Multi-item Grouping rule (Section 22):
        // If 3 or more items become low at the same time, send ONE grouped alert
        if (actionableItems.size() >= 3) {
            String title = "🛒 " + actionableItems.size() + " household items may need restocking";
            StringBuilder body = new StringBuilder("Items: ");
            for (int i = 0; i < Math.min(3, actionableItems.size()); i++) {
                if (i > 0) body.append(", ");
                body.append(actionableItems.get(i).getItemName());
            }
            if (actionableItems.size() > 3) {
                body.append(" and ").append(actionableItems.size() - 3).append(" more.");
            }

            notificationService.notifyHomeMembers(home, null, NotificationType.LOW_STOCK, title, body.toString(), null);

            for (PredictionDto p : actionableItems) {
                itemNotificationCooldowns.put(p.getItemId(), now);
            }
            return;
        }

        // 4. Send targeted, individual actionable notifications
        for (PredictionDto p : actionableItems) {
            String title;
            String body;

            if (p.getPredictionStatus() == PredictionStatus.OUT_OF_STOCK) {
                title = "🚨 " + p.getItemName() + " is out of stock";
                body = "Tap to add to your shared shopping list.";
            } else if (p.getPredictionStatus() == PredictionStatus.LIKELY_TO_RUN_OUT) {
                title = "🥛 " + p.getItemName() + " may run out today";
                body = "Based on your household usage cycle. Tap to restock.";
            } else {
                title = "🛢️ " + p.getItemName() + " is running low";
                body = p.getPredictionRangeText() + ". Tap to check stock or add to shopping.";
            }

            notificationService.notifyHomeMembers(home, null, NotificationType.LOW_STOCK, title, body, null);
            itemNotificationCooldowns.put(p.getItemId(), now);
        }
    }

    public boolean isQuietHours() {
        LocalTime now = LocalTime.now();
        return now.isAfter(QUIET_HOURS_START) || now.isBefore(QUIET_HOURS_END);
    }
}
