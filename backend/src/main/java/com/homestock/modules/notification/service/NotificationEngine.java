package com.homestock.modules.notification.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.entity.HomeMember;
import com.homestock.modules.home.repository.HomeMemberRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.notification.dto.NotificationCandidate;
import com.homestock.modules.notification.dto.NotificationDecision;
import com.homestock.modules.notification.engine.NotificationDecisionEngine;
import com.homestock.modules.notification.engine.NotificationDeduplicationService;
import com.homestock.modules.notification.entity.*;
import com.homestock.modules.notification.provider.FirebaseNotificationProvider;
import com.homestock.modules.notification.repository.NotificationDeduplicationRepository;
import com.homestock.modules.notification.repository.NotificationEventRepository;
import com.homestock.modules.notification.repository.NotificationRepository;
import com.homestock.modules.purchase.entity.Purchase;
import com.homestock.modules.user.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalTime;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationEngine {

    private final NotificationRepository notificationRepository;
    private final NotificationDeduplicationRepository deduplicationRepository;
    private final HomeMemberRepository homeMemberRepository;
    private final NotificationPreferenceService preferenceService;
    private final DeviceTokenService deviceTokenService;
    private final FirebaseNotificationProvider firebaseNotificationProvider;
    private final ObjectMapper objectMapper;
    private final NotificationDecisionEngine decisionEngine;
    private final NotificationEventRepository eventRepository;
    private final NotificationDeduplicationService deduplicationService;
    private final InventoryItemRepository inventoryItemRepository;

    @Value("${app.notifications.cooldown.stock-hours:24}")
    private long stockCooldownHours = 24;

    @Value("${app.notifications.cooldown.expiry-hours:24}")
    private long expiryCooldownHours = 24;

    @Value("${app.notifications.cooldown.smart-restock-hours:72}")
    private long restockCooldownHours = 72;

    /**
     * Central dispatch for notifications across home members.
     * Integrates with NotificationDecisionEngine to enforce ML scoring,
     * fatigue limits, timing optimization, and channel routing.
     */
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.REQUIRES_NEW)
    public void dispatchHomeNotification(
            Home home,
            User excludedUser,
            NotificationType type,
            String title,
            String body,
            String dedupKey,
            Duration cooldown,
            BigDecimal currentQuantity,
            String currentStatus,
            Map<String, String> dataPayload
    ) {
        if (home == null || type == null) return;

        NotificationPriority priority = NotificationPriority.fromType(type);

        // 1. Deduplication check
        if (dedupKey != null && !dedupKey.isBlank()) {
            try {
                Instant now = Instant.now();
                Optional<NotificationDeduplication> existingDedup = deduplicationRepository.findByDedupKey(dedupKey);

                if (existingDedup.isPresent()) {
                    NotificationDeduplication dedup = existingDedup.get();
                    Duration effectiveCooldown = cooldown != null ? cooldown : Duration.ofHours(24);

                    boolean withinCooldown = dedup.getLastSentAt().plus(effectiveCooldown).isAfter(now);
                    boolean statusChanged = currentStatus != null && dedup.getLastStatus() != null &&
                            !currentStatus.equalsIgnoreCase(dedup.getLastStatus());
                    boolean qtyChangedSignificantly = currentQuantity != null && dedup.getLastQuantity() != null &&
                            currentQuantity.compareTo(dedup.getLastQuantity()) != 0;

                    // If within cooldown and condition has not changed, suppress duplicate alert
                    if (withinCooldown && !statusChanged && !qtyChangedSignificantly) {
                        log.debug("Suppressing duplicate notification for dedupKey: {}", dedupKey);
                        return;
                    }

                    // Update deduplication timestamp
                    dedup.setLastSentAt(now);
                    dedup.setLastQuantity(currentQuantity);
                    dedup.setLastStatus(currentStatus);
                    deduplicationRepository.save(dedup);
                } else {
                    NotificationDeduplication newDedup = NotificationDeduplication.builder()
                            .dedupKey(dedupKey)
                            .homeId(home.getId())
                            .lastSentAt(now)
                            .lastQuantity(currentQuantity)
                            .lastStatus(currentStatus)
                            .build();
                    deduplicationRepository.save(newDedup);
                }
            } catch (Exception e) {
                log.warn("Failed to check or update notification deduplication: {}", e.getMessage());
            }
        }

        // 2. Resolve inventory item if available
        InventoryItem resolvedItem = null;
        if (dataPayload != null && dataPayload.containsKey("entityId")) {
            try {
                UUID itemId = UUID.fromString(dataPayload.get("entityId"));
                resolvedItem = inventoryItemRepository.findById(itemId).orElse(null);
            } catch (Exception ignored) {}
        }

        // 3. Resolve home members and filter through ML decision engine
        List<HomeMember> members = homeMemberRepository.findAllByHomeId(home.getId());

        for (HomeMember member : members) {
            User targetUser = member.getUser();
            if (targetUser == null) continue;

            // Exclude actor (do not notify the member who initiated the action)
            // But if there is only 1 member in the home, or if the event is a critical stock alert
            // (LOW_STOCK, OUT_OF_STOCK, EXPIRY_REMINDER), never exclude them.
            if (excludedUser != null && members.size() > 1 && targetUser.getId().equals(excludedUser.getId())) {
                if (type != NotificationType.LOW_STOCK && type != NotificationType.OUT_OF_STOCK && type != NotificationType.EXPIRY_REMINDER) {
                    continue;
                }
            }

            // Check User Preferences
            NotificationPreference pref = preferenceService.getPreferencesForUser(targetUser.getId());
            if (pref != null && !pref.isNotificationTypeEnabled(type)) {
                log.debug("User {} has disabled notification type {}", targetUser.getId(), type);
                continue;
            }

            // Build ML Notification Candidate
            NotificationCandidate candidate = NotificationCandidate.builder()
                    .home(home)
                    .recipientUser(targetUser)
                    .triggerUser(excludedUser)
                    .inventoryItem(resolvedItem)
                    .type(type)
                    .basePriority(priority)
                    .proposedTitle(title)
                    .proposedBody(body)
                    .currentStock(currentQuantity != null ? currentQuantity : (resolvedItem != null ? resolvedItem.getQuantity() : null))
                    .unit(resolvedItem != null ? resolvedItem.getUnit() : null)
                    .dedupKey(dedupKey)
                    .candidateTimestamp(Instant.now())
                    .build();

            // Run through ML Smart Notification Decision Engine
            NotificationDecision decision = null;
            if (decisionEngine != null) {
                try {
                    decision = decisionEngine.evaluateCandidate(candidate);
                } catch (Exception e) {
                    log.warn("Decision engine evaluation failed, falling back to rule defaults: {}", e.getMessage());
                }
            }

            // Record Decision Event in Audit / Learning Dataset
            if (decision != null) {
                recordNotificationEvent(candidate, decision);

                // If Decision is SUPPRESS, suppress completely
                if (decision.getDecisionType() == NotificationDecisionType.SUPPRESS) {
                    log.info("[MLNotificationEngine] Suppressed notification '{}' for user {}: {}",
                            title, targetUser.getId(), decision.getRationale());
                    continue;
                }
            }

            String finalTitle = (decision != null && decision.getFinalTitle() != null) ? decision.getFinalTitle() : title;
            String finalBody = (decision != null && decision.getFinalBody() != null) ? decision.getFinalBody() : body;
            NotificationPriority resolvedPriority = (decision != null && decision.getResolvedPriority() != null)
                    ? decision.getResolvedPriority() : priority;
            String payloadJson = serializePayload(dataPayload, decision);

            // Save in-app notification record in Database safely
            try {
                Notification notification = Notification.builder()
                        .home(home)
                        .user(targetUser)
                        .type(type)
                        .priority(resolvedPriority)
                        .title(finalTitle)
                        .body(finalBody)
                        .payloadJson(payloadJson)
                        .dedupKey(dedupKey)
                        .isRead(false)
                        .build();
                notificationRepository.save(notification);
            } catch (Exception e) {
                log.error("Failed to persist in-app notification for user {}: {}", targetUser.getId(), e.getMessage());
            }

            // Push Notification Dispatch Decision Check:
            // Only send Firebase Push if:
            // 1. Decision is SEND_NOW and Channel is PUSH (or decision is null default fallback)
            // 2. Not inside quiet hours (unless CRITICAL/HIGH priority)
            boolean isPushAllowedByML = decision == null ||
                    (decision.getDecisionType() == NotificationDecisionType.SEND_NOW && decision.getChannel() == NotificationChannel.PUSH);

            boolean isQuietHours = pref != null && pref.isInsideQuietHours(LocalTime.now())
                    && resolvedPriority != NotificationPriority.CRITICAL && resolvedPriority != NotificationPriority.HIGH;

            if (isPushAllowedByML && !isQuietHours) {
                try {
                    List<DeviceToken> tokens = deviceTokenService.getActiveTokensForUser(targetUser.getId());
                    if (!tokens.isEmpty()) {
                        firebaseNotificationProvider.sendPushNotification(
                                tokens,
                                type,
                                resolvedPriority,
                                finalTitle,
                                finalBody,
                                dataPayload
                        );
                    }
                    if (deduplicationService != null) {
                        deduplicationService.recordDispatch(candidate);
                    }
                } catch (Exception e) {
                    log.warn("Failed to dispatch push notification for user {}: {}", targetUser.getId(), e.getMessage());
                }
            } else {
                log.info("[MLNotificationEngine] Push omitted for user {} (MLAllowed: {}, QuietHours: {}, Score: {})",
                        targetUser.getId(), isPushAllowedByML, isQuietHours, decision != null ? decision.getFinalScore() : "N/A");
            }
        }
    }

    /**
     * Direct notification to a specific user.
     */
    @Transactional(propagation = org.springframework.transaction.annotation.Propagation.REQUIRES_NEW)
    public void dispatchUserNotification(
            Home home,
            User targetUser,
            NotificationType type,
            String title,
            String body,
            String dedupKey,
            Map<String, String> dataPayload
    ) {
        if (targetUser == null || type == null) return;

        NotificationPriority priority = NotificationPriority.fromType(type);

        NotificationPreference pref = preferenceService.getPreferencesForUser(targetUser.getId());
        if (pref != null && !pref.isNotificationTypeEnabled(type)) {
            return;
        }

        InventoryItem resolvedItem = null;
        if (dataPayload != null && dataPayload.containsKey("entityId")) {
            try {
                UUID itemId = UUID.fromString(dataPayload.get("entityId"));
                resolvedItem = inventoryItemRepository.findById(itemId).orElse(null);
            } catch (Exception ignored) {}
        }

        NotificationCandidate candidate = NotificationCandidate.builder()
                .home(home)
                .recipientUser(targetUser)
                .inventoryItem(resolvedItem)
                .type(type)
                .basePriority(priority)
                .proposedTitle(title)
                .proposedBody(body)
                .currentStock(resolvedItem != null ? resolvedItem.getQuantity() : null)
                .unit(resolvedItem != null ? resolvedItem.getUnit() : null)
                .dedupKey(dedupKey)
                .candidateTimestamp(Instant.now())
                .build();

        NotificationDecision decision = null;
        if (decisionEngine != null) {
            try {
                decision = decisionEngine.evaluateCandidate(candidate);
            } catch (Exception e) {
                log.warn("Decision engine evaluation failed for direct user notification: {}", e.getMessage());
            }
        }

        if (decision != null) {
            recordNotificationEvent(candidate, decision);
            if (decision.getDecisionType() == NotificationDecisionType.SUPPRESS) {
                log.info("[MLNotificationEngine] Suppressed direct notification '{}' for user {}: {}",
                        title, targetUser.getId(), decision.getRationale());
                return;
            }
        }

        String finalTitle = (decision != null && decision.getFinalTitle() != null) ? decision.getFinalTitle() : title;
        String finalBody = (decision != null && decision.getFinalBody() != null) ? decision.getFinalBody() : body;
        NotificationPriority resolvedPriority = (decision != null && decision.getResolvedPriority() != null)
                ? decision.getResolvedPriority() : priority;
        String payloadJson = serializePayload(dataPayload, decision);

        try {
            Notification notification = Notification.builder()
                    .home(home)
                    .user(targetUser)
                    .type(type)
                    .priority(resolvedPriority)
                    .title(finalTitle)
                    .body(finalBody)
                    .payloadJson(payloadJson)
                    .dedupKey(dedupKey)
                    .isRead(false)
                    .build();
            notificationRepository.save(notification);
        } catch (Exception e) {
            log.error("Failed to persist notification for user {}: {}", targetUser.getId(), e.getMessage());
        }

        boolean isPushAllowedByML = decision == null ||
                (decision.getDecisionType() == NotificationDecisionType.SEND_NOW && decision.getChannel() == NotificationChannel.PUSH);

        boolean isQuietHours = pref != null && pref.isInsideQuietHours(LocalTime.now())
                && resolvedPriority != NotificationPriority.CRITICAL && resolvedPriority != NotificationPriority.HIGH;

        if (isPushAllowedByML && !isQuietHours) {
            try {
                List<DeviceToken> tokens = deviceTokenService.getActiveTokensForUser(targetUser.getId());
                if (!tokens.isEmpty()) {
                    firebaseNotificationProvider.sendPushNotification(tokens, type, resolvedPriority, finalTitle, finalBody, dataPayload);
                }
                if (deduplicationService != null) {
                    deduplicationService.recordDispatch(candidate);
                }
            } catch (Exception e) {
                log.warn("Failed to dispatch push notification for user {}: {}", targetUser.getId(), e.getMessage());
            }
        }
    }

    private void recordNotificationEvent(NotificationCandidate candidate, NotificationDecision decision) {
        if (eventRepository == null || candidate == null || decision == null || decision.getDecisionType() == null) return;
        try {
            NotificationEventType eventType = switch (decision.getDecisionType()) {
                case SUPPRESS -> NotificationEventType.SUPPRESSED;
                case SEND_NOW, IN_APP_ONLY -> NotificationEventType.SENT;
                case SCHEDULE, GROUP -> NotificationEventType.GENERATED;
                default -> NotificationEventType.GENERATED;
            };

            NotificationEvent event = NotificationEvent.builder()
                    .user(candidate.getRecipientUser())
                    .home(candidate.getHome())
                    .inventoryItem(candidate.getInventoryItem())
                    .notificationType(candidate.getType() != null ? candidate.getType() : NotificationType.SYSTEM)
                    .priority(decision.getResolvedPriority())
                    .channel(decision.getChannel())
                    .decision(decision.getDecisionType())
                    .eventType(eventType)
                    .urgencyScore(decision.getUrgencyScore())
                    .relevanceScore(decision.getRelevanceScore())
                    .confidenceScore(decision.getConfidenceScore())
                    .actionProbability(decision.getActionProbability())
                    .fatigueScore(decision.getFatigueScore())
                    .finalScore(decision.getFinalScore())
                    .predictedDaysRemaining(candidate.getPredictedDaysRemaining())
                    .dedupKey(candidate.getDedupKey())
                    .scheduledFor(decision.getScheduledFor())
                    .occurredAt(Instant.now())
                    .build();

            eventRepository.save(event);
        } catch (Exception e) {
            log.warn("Failed to record notification event: {}", e.getMessage());
        }
    }

    private String serializePayload(Map<String, String> dataPayload, NotificationDecision decision) {
        Map<String, String> map = new HashMap<>();
        if (dataPayload != null) {
            map.putAll(dataPayload);
        }
        if (decision != null) {
            if (decision.getActionLabel() != null && !map.containsKey("actionLabel")) {
                map.put("actionLabel", decision.getActionLabel());
            }
            if (decision.getActionDeepLink() != null && !map.containsKey("actionRoute")) {
                map.put("actionRoute", decision.getActionDeepLink());
            }
        }
        try {
            return objectMapper.writeValueAsString(map);
        } catch (Exception e) {
            return null;
        }
    }


    // ==========================================
    // Specific Domain Event Notification Hooks
    // ==========================================

    public void notifyLowStock(Home home, InventoryItem item, User actor) {
        String dedupKey = "LOW_STOCK:" + home.getId() + ":" + item.getId();
        String title = item.getName() + " is running low";
        String body = "You have " + item.getQuantity() + " " + item.getUnit() + " remaining. Add it to your shopping list?";

        Map<String, String> data = Map.of(
                "action", "VIEW_ITEM",
                "entityId", item.getId().toString(),
                "homeId", home.getId().toString(),
                "type", NotificationType.LOW_STOCK.name()
        );

        dispatchHomeNotification(
                home, actor, NotificationType.LOW_STOCK, title, body, dedupKey,
                Duration.ofHours(stockCooldownHours), item.getQuantity(), "LOW_STOCK", data
        );
    }

    public void notifyOutOfStock(Home home, InventoryItem item, User actor) {
        String dedupKey = "OUT_OF_STOCK:" + home.getId() + ":" + item.getId();
        String title = item.getName() + " is out of stock";
        String body = "Your " + item.getName() + " stock is empty. Add it to your shopping list?";

        Map<String, String> data = Map.of(
                "action", "VIEW_ITEM",
                "entityId", item.getId().toString(),
                "homeId", home.getId().toString(),
                "type", NotificationType.OUT_OF_STOCK.name()
        );

        dispatchHomeNotification(
                home, actor, NotificationType.OUT_OF_STOCK, title, body, dedupKey,
                Duration.ofHours(stockCooldownHours), BigDecimal.ZERO, "OUT_OF_STOCK", data
        );
    }

    public void notifyExpiry(Home home, InventoryItem item, long daysUntilExpiry) {
        String dateStr = item.getExpiryDate() != null ? item.getExpiryDate().toString() : "soon";
        String dedupKey = "EXPIRY:" + item.getId() + ":" + daysUntilExpiry;

        String title;
        String body;
        if (daysUntilExpiry == 0) {
            title = item.getName() + " expires today";
            body = "Use it today to avoid waste.";
        } else if (daysUntilExpiry == 1) {
            title = item.getName() + " expires tomorrow";
            body = "Use it soon to avoid waste.";
        } else if (daysUntilExpiry < 0) {
            title = item.getName() + " has expired";
            body = "Check your stock to discard or update.";
        } else {
            title = item.getName() + " expires in " + daysUntilExpiry + " days";
            body = "Consider using your " + item.getName() + " before " + dateStr + ".";
        }

        Map<String, String> data = Map.of(
                "action", "VIEW_ITEM",
                "entityId", item.getId().toString(),
                "homeId", home.getId().toString(),
                "type", NotificationType.EXPIRY_REMINDER.name()
        );

        dispatchHomeNotification(
                home, null, NotificationType.EXPIRY_REMINDER, title, body, dedupKey,
                Duration.ofHours(expiryCooldownHours), item.getQuantity(), "EXPIRY_" + daysUntilExpiry, data
        );
    }

    public void notifyShoppingListUpdate(Home home, User actor, List<String> itemNames) {
        if (itemNames == null || itemNames.isEmpty()) return;

        String title = "Shopping list updated";
        String body;
        String actorName = actor != null ? actor.getFullName() : "A family member";

        if (itemNames.size() == 1) {
            body = actorName + " added " + itemNames.getFirst() + " to the shopping list.";
        } else {
            body = actorName + " added " + itemNames.size() + " items to the shopping list.";
        }

        Map<String, String> data = Map.of(
                "action", "VIEW_SHOPPING",
                "homeId", home.getId().toString(),
                "type", NotificationType.SHOPPING_LIST_UPDATE.name()
        );

        dispatchHomeNotification(
                home, actor, NotificationType.SHOPPING_LIST_UPDATE, title, body,
                null, Duration.ofMinutes(5), null, null, data
        );
    }

    public void notifyFamilyActivity(Home home, User actor, String activityTitle, String activityBody) {
        Map<String, String> data = Map.of(
                "action", "VIEW_HOME",
                "homeId", home.getId().toString(),
                "type", NotificationType.FAMILY_ACTIVITY.name()
        );

        dispatchHomeNotification(
                home, actor, NotificationType.FAMILY_ACTIVITY, activityTitle, activityBody,
                null, Duration.ofMinutes(2), null, null, data
        );
    }

    public void notifyPurchaseRecorded(Home home, User actor, Purchase purchase) {
        String actorName = actor != null ? actor.getFullName() : "Someone";
        String title = "Purchase recorded";
        String body = actorName + " added a ₹" + purchase.getTotalAmount() + " grocery purchase.";

        Map<String, String> data = Map.of(
                "action", "VIEW_PURCHASE",
                "entityId", purchase.getId().toString(),
                "homeId", home.getId().toString(),
                "type", NotificationType.PURCHASE_RECORDED.name()
        );

        dispatchHomeNotification(
                home, actor, NotificationType.PURCHASE_RECORDED, title, body,
                "PURCHASE:" + purchase.getId(), Duration.ofHours(1), null, null, data
        );
    }

    public void notifyStockUpdated(Home home, User actor, InventoryItem item, BigDecimal change, String unit) {
        String actorName = actor != null ? actor.getFullName() : "A family member";
        String title = "Stock updated";
        String body = actorName + " updated " + item.getName() + " stock (" + change + " " + unit + ").";

        Map<String, String> data = Map.of(
                "action", "VIEW_ITEM",
                "entityId", item.getId().toString(),
                "homeId", home.getId().toString(),
                "type", NotificationType.STOCK_UPDATED.name()
        );

        dispatchHomeNotification(
                home, actor, NotificationType.STOCK_UPDATED, title, body,
                null, Duration.ofMinutes(2), item.getQuantity(), null, data
        );
    }

    public void notifySmartRestock(Home home, InventoryItem item, String rationale) {
        String dedupKey = "SMART_RESTOCK:" + home.getId() + ":" + item.getId();
        String title = "Restock reminder for " + item.getName();
        String body = "You usually buy " + item.getName() + " around this time. Check your stock?";

        Map<String, String> data = Map.of(
                "action", "VIEW_ITEM",
                "entityId", item.getId().toString(),
                "homeId", home.getId().toString(),
                "type", NotificationType.SMART_RESTOCK_SUGGESTION.name()
        );

        dispatchHomeNotification(
                home, null, NotificationType.SMART_RESTOCK_SUGGESTION, title, body, dedupKey,
                Duration.ofHours(restockCooldownHours), item.getQuantity(), "RESTOCK_SUGGESTION", data
        );
    }

    public void notifyWeeklyInsight(Home home, BigDecimal weeklySpend, String topItem, int expiringCount) {
        String dedupKey = "WEEKLY_INSIGHT:" + home.getId() + ":" + (System.currentTimeMillis() / (7 * 24 * 3600 * 1000));
        String title = "Your HomeStock weekly insight";

        StringBuilder sb = new StringBuilder();
        if (weeklySpend != null && weeklySpend.compareTo(BigDecimal.ZERO) > 0) {
            sb.append("You spent ₹").append(weeklySpend).append(" this week. ");
        }
        if (topItem != null && !topItem.isBlank()) {
            sb.append(topItem).append(" was your most purchased item. ");
        }
        if (expiringCount > 0) {
            sb.append(expiringCount).append(" items are close to expiry.");
        }
        if (sb.isEmpty()) {
            sb.append("Your household pantry is running smoothly this week.");
        }

        Map<String, String> data = Map.of(
                "action", "VIEW_ANALYTICS",
                "homeId", home.getId().toString(),
                "type", NotificationType.WEEKLY_INSIGHT.name()
        );

        dispatchHomeNotification(
                home, null, NotificationType.WEEKLY_INSIGHT, title, sb.toString().trim(), dedupKey,
                Duration.ofDays(6), null, null, data
        );
    }

    public void notifyMonthlyReport(Home home, BigDecimal monthlySpend, int totalPurchases) {
        String dedupKey = "MONTHLY_REPORT:" + home.getId() + ":" + (System.currentTimeMillis() / (30 * 24 * 3600 * 1000));
        String title = "Your HomeStock monthly report";
        String body = "You recorded ₹" + (monthlySpend != null ? monthlySpend : BigDecimal.ZERO) +
                " across " + totalPurchases + " household purchase(s) this month.";

        Map<String, String> data = Map.of(
                "action", "VIEW_ANALYTICS",
                "homeId", home.getId().toString(),
                "type", NotificationType.MONTHLY_REPORT.name()
        );

        dispatchHomeNotification(
                home, null, NotificationType.MONTHLY_REPORT, title, body, dedupKey,
                Duration.ofDays(25), null, null, data
        );
    }

    /**
     * Broadcast a lightweight realtime event to all other members of the home
     * so their devices trigger an incremental sync.
     * Silent data-only push (title=null, body=null), sent ONLY to other members.
     */
    public void notifyHomeChanged(Home home, UUID actorUserId) {
        if (home == null) return;
        List<HomeMember> members = homeMemberRepository.findAllByHomeId(home.getId());
        List<UUID> recipientIds = new ArrayList<>();
        for (HomeMember member : members) {
            User u = member.getUser();
            // ONLY notify other members of the household; never notify the person who triggered the sync
            if (u != null && actorUserId != null && !u.getId().equals(actorUserId)) {
                recipientIds.add(u.getId());
            }
        }
        if (!recipientIds.isEmpty()) {
            List<DeviceToken> activeTokens = deviceTokenService.getActiveTokensForUsers(recipientIds);
            if (!activeTokens.isEmpty()) {
                Map<String, String> data = Map.of(
                        "type", "HOME_CHANGED",
                        "homeId", home.getId().toString(),
                        "action", "SYNC_HOME"
                );
                // Silent data-only push: title and body MUST be null so no UI alert or popup is shown
                firebaseNotificationProvider.sendPushNotification(
                        activeTokens,
                        NotificationType.SYSTEM,
                        NotificationPriority.LOW,
                        null,
                        null,
                        data
                );
            }
        }
    }
}

