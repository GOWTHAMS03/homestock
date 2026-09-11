package com.homestock.modules.notification.scheduler;

import com.homestock.modules.home.entity.Home;
import com.homestock.modules.home.entity.HomeMember;
import com.homestock.modules.home.repository.HomeMemberRepository;
import com.homestock.modules.home.repository.HomeRepository;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.inventory.repository.InventoryItemRepository;
import com.homestock.modules.notification.dto.NotificationCandidate;
import com.homestock.modules.notification.dto.NotificationDecision;
import com.homestock.modules.notification.engine.NotificationDecisionEngine;
import com.homestock.modules.notification.engine.NotificationDeduplicationService;
import com.homestock.modules.notification.engine.NotificationGroupingService;
import com.homestock.modules.notification.entity.*;
import com.homestock.modules.notification.ml.StockPredictionService;
import com.homestock.modules.notification.ml.model.StockPredictionResult;
import com.homestock.modules.notification.repository.NotificationEventRepository;
import com.homestock.modules.notification.service.NotificationEngine;
import com.homestock.modules.smartshopping.dto.ProductDealDto;
import com.homestock.modules.smartshopping.dto.ProductDealSearchResponse;
import com.homestock.modules.smartshopping.service.ProductDealService;
import com.homestock.modules.user.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.*;

/**
 * MLNotificationScheduler:
 * Orchestrates periodic ML stock depletion predictions, deal-enhancement,
 * smart multi-product grouping, and intelligent decision-based notification dispatching.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class MLNotificationScheduler {

    private final HomeRepository homeRepository;
    private final HomeMemberRepository homeMemberRepository;
    private final InventoryItemRepository inventoryItemRepository;
    private final StockPredictionService stockPredictionService;
    private final NotificationGroupingService groupingService;
    private final NotificationDecisionEngine decisionEngine;
    private final NotificationDeduplicationService deduplicationService;
    private final NotificationEngine notificationEngine;
    private final NotificationEventRepository eventRepository;

    @Autowired(required = false)
    private ProductDealService dealService;

    @Value("${app.scheduler.ml-notification.enabled:true}")
    private boolean enabled = true;

    /**
     * Executes ML smart notification cycle (Default: every 4 hours).
     */
    @Scheduled(cron = "${app.scheduler.ml-notification.cron:0 0 */4 * * *}")
    @Transactional
    public void runSmartNotificationCycle() {
        if (!enabled) {
            log.debug("[MLNotificationScheduler] ML notification scheduler is disabled, skipping cycle.");
            return;
        }

        log.info("[MLNotificationScheduler] Starting ML smart notification evaluation cycle...");
        List<Home> homes = homeRepository.findAll();

        for (Home home : homes) {
            try {
                processHousehold(home);
            } catch (Exception e) {
                log.error("[MLNotificationScheduler] Error processing household '{}': {}", home.getId(), e.getMessage(), e);
            }
        }

        log.info("[MLNotificationScheduler] Completed ML smart notification cycle.");
    }

    private void processHousehold(Home home) {
        List<HomeMember> members = homeMemberRepository.findAllByHomeId(home.getId());
        if (members.isEmpty()) return;

        User primaryUser = members.get(0).getUser();
        List<InventoryItem> items = inventoryItemRepository.findAllByHomeIdOrderByNameAsc(home.getId());

        List<NotificationCandidate> candidates = new ArrayList<>();

        for (InventoryItem item : items) {
            StockPredictionResult prediction = stockPredictionService.predictDepletion(item, primaryUser.getId());

            BigDecimal currentStock = item.getQuantity() != null ? item.getQuantity() : BigDecimal.ZERO;
            boolean isDepleted = currentStock.compareTo(BigDecimal.ZERO) <= 0;
            boolean isImminent = prediction.getDaysUntilEmpty().compareTo(new BigDecimal("3.0")) <= 0
                    || prediction.getProbabilityWithin3Days() >= 0.70;

            if (isDepleted || isImminent) {
                NotificationType type = isDepleted ? NotificationType.OUT_OF_STOCK : NotificationType.LOW_STOCK;
                NotificationPriority priority = isDepleted ? NotificationPriority.CRITICAL : NotificationPriority.HIGH;

                NotificationCandidate.NotificationCandidateBuilder builder = NotificationCandidate.builder()
                        .home(home)
                        .recipientUser(primaryUser)
                        .inventoryItem(item)
                        .type(type)
                        .basePriority(priority)
                        .currentStock(currentStock)
                        .unit(item.getUnit())
                        .predictedDaysRemaining(prediction.getDaysUntilEmpty())
                        .probabilityWithin1Day(prediction.getProbabilityWithin1Day())
                        .probabilityWithin3Days(prediction.getProbabilityWithin3Days())
                        .probabilityWithin7Days(prediction.getProbabilityWithin7Days())
                        .confidence(prediction.getConfidence())
                        .candidateTimestamp(Instant.now());

                // Check smart shopping deals if item is low stock
                if (dealService != null && !isDepleted) {
                    attachDealContext(home.getId(), item, builder);
                }

                candidates.add(builder.build());
            }
        }

        if (candidates.isEmpty()) {
            return;
        }

        // Apply Multi-Item Smart Grouping
        List<NotificationCandidate> processedCandidates = groupingService.processGrouping(home, candidates);

        // Evaluate Decisions and Dispatch
        for (NotificationCandidate candidate : processedCandidates) {
            NotificationDecision decision = decisionEngine.evaluateCandidate(candidate);
            executeDecision(candidate, decision);
        }
    }

    private void attachDealContext(UUID homeId, InventoryItem item, NotificationCandidate.NotificationCandidateBuilder builder) {
        try {
            ProductDealSearchResponse deals = dealService.searchDeals(
                    homeId, item.getName(), item.getBarcode(), null, item.getUnit(), null, null, null, "default"
            );
            if (deals != null && deals.getHighlights() != null && deals.getHighlights().getLowestPrice() != null) {
                ProductDealDto deal = deals.getHighlights().getLowestPrice();
                if (deal.getSavingsVsHighest() != null && deal.getSavingsVsHighest().compareTo(BigDecimal.ZERO) > 0) {
                    builder.dealAvailable(true)
                            .regularPrice(deal.getMrp())
                            .dealPrice(deal.getBestPrice())
                            .potentialSavings(deal.getSavingsVsHighest())
                            .dealStore(deal.getBestProvider())
                            .dealUrl(deal.getProductUrl());
                }
            }
        } catch (Exception e) {
            log.debug("[MLNotificationScheduler] Could not fetch deal for item '{}': {}", item.getName(), e.getMessage());
        }
    }

    private void executeDecision(NotificationCandidate candidate, NotificationDecision decision) {
        log.info("[MLNotificationScheduler] Candidate='{}', Decision={}, Channel={}, Score={}",
                candidate.getInventoryItem() != null ? candidate.getInventoryItem().getName() : candidate.getProposedTitle(),
                decision.getDecisionType(), decision.getChannel(), decision.getFinalScore());

        // 1. Log Decision Event in Audit / ML Training Dataset
        NotificationEvent event = NotificationEvent.builder()
                .user(candidate.getRecipientUser())
                .home(candidate.getHome())
                .inventoryItem(candidate.getInventoryItem())
                .notificationType(candidate.getType() != null ? candidate.getType() : NotificationType.SYSTEM)
                .priority(decision.getResolvedPriority())
                .channel(decision.getChannel())
                .decision(decision.getDecisionType())
                .eventType(resolveEventType(decision))
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

        // 2. Dispatch if SEND_NOW or IN_APP_ONLY
        if (decision.getDecisionType() == NotificationDecisionType.SEND_NOW ||
                decision.getDecisionType() == NotificationDecisionType.IN_APP_ONLY) {

            Map<String, String> payload = new HashMap<>();
            if (decision.getActionLabel() != null) payload.put("actionLabel", decision.getActionLabel());
            if (decision.getActionDeepLink() != null) payload.put("actionRoute", decision.getActionDeepLink());
            if (candidate.isDealAvailable() && candidate.getDealUrl() != null) payload.put("dealUrl", candidate.getDealUrl());

            notificationEngine.dispatchHomeNotification(
                    candidate.getHome(),
                    null,
                    candidate.getType() != null ? candidate.getType() : NotificationType.LOW_STOCK,
                    decision.getFinalTitle(),
                    decision.getFinalBody(),
                    candidate.getDedupKey(),
                    Duration.ofHours(24),
                    candidate.getCurrentStock(),
                    candidate.getType() != null ? candidate.getType().name() : "LOW_STOCK",
                    payload
            );

            deduplicationService.recordDispatch(candidate);
        }
    }

    private NotificationEventType resolveEventType(NotificationDecision decision) {
        if (decision.getDecisionType() == NotificationDecisionType.SUPPRESS) {
            return NotificationEventType.SUPPRESSED;
        } else if (decision.getDecisionType() == NotificationDecisionType.SEND_NOW ||
                decision.getDecisionType() == NotificationDecisionType.IN_APP_ONLY) {
            return NotificationEventType.SENT;
        } else {
            return NotificationEventType.GENERATED;
        }
    }
}
