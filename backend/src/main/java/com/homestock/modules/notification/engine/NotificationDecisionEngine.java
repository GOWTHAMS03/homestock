package com.homestock.modules.notification.engine;

import com.homestock.modules.notification.composer.NotificationComposer;
import com.homestock.modules.notification.dto.NotificationCandidate;
import com.homestock.modules.notification.dto.NotificationDecision;
import com.homestock.modules.notification.entity.*;
import com.homestock.modules.notification.ml.NotificationFatigueService;
import com.homestock.modules.notification.ml.NotificationScoringService;
import com.homestock.modules.notification.ml.NotificationTimingService;
import com.homestock.modules.notification.repository.NotificationPreferenceRepository;
import com.homestock.modules.shopping.repository.ShoppingListItemRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.Optional;
import java.util.UUID;

/**
 * NotificationDecisionEngine:
 * Central brain of HomeStock's ML Smart Notification Engine.
 * Decides whether a notification candidate should be:
 * - SEND_NOW (Immediate Push or In-App)
 * - SCHEDULE (Delayed until user's peak interaction window)
 * - IN_APP_ONLY (Low priority or push fatigue exceeded)
 * - GROUP (Consolidated into a multi-item digest)
 * - SUPPRESS (Duplicate, fatigue limit, user preference, or already completed action)
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class NotificationDecisionEngine {

    private final NotificationPreferenceRepository preferenceRepository;
    private final ShoppingListItemRepository shoppingListItemRepository;
    private final NotificationDeduplicationService deduplicationService;
    private final NotificationFatigueService fatigueService;
    private final NotificationScoringService scoringService;
    private final NotificationTimingService timingService;
    private final NotificationComposer notificationComposer;

    @Transactional(readOnly = true)
    public NotificationDecision evaluateCandidate(NotificationCandidate candidate) {
        UUID userId = candidate.getRecipientUser() != null ? candidate.getRecipientUser().getId() : null;
        UUID homeId = candidate.getHome() != null ? candidate.getHome().getId() : null;
        UUID itemId = candidate.getInventoryItem() != null ? candidate.getInventoryItem().getId() : null;

        // 1. User Preferences Check
        NotificationPreference preference = null;
        if (userId != null) {
            preference = preferenceRepository.findByUserId(userId).orElse(null);
            if (preference != null && candidate.getType() != null && !preference.isNotificationTypeEnabled(candidate.getType())) {
                return buildSuppressedDecision(candidate, "Notification type disabled in user preferences");
            }
        }

        // 2. Offline Sync & Pre-existing Action Check (e.g. item already on shopping list)
        if (candidate.getType() == NotificationType.LOW_STOCK || candidate.getType() == NotificationType.SMART_RESTOCK_SUGGESTION) {
            if (homeId != null && itemId != null) {
                boolean alreadyOnList = shoppingListItemRepository.findActiveItemByHomeIdAndInventoryItemId(homeId, itemId).isPresent();
                if (alreadyOnList) {
                    return buildSuppressedDecision(candidate, "Item is already present on the household shopping list");
                }
            }
        }

        // 3. Family Action Check (did another family member buy or restock this item?)
        if (candidate.getTriggerUser() != null && userId != null && !candidate.getTriggerUser().getId().equals(userId)) {
            // Family member triggered the action (e.g., Dad bought oil)
            if (candidate.getType() == NotificationType.LOW_STOCK) {
                return buildSuppressedDecision(candidate, "Suppressed low-stock alert; family member recently acted on item");
            }
        }

        // 4. Deduplication & Cooldown Check
        Duration cooldown = resolveCooldown(candidate);
        NotificationDeduplicationService.DeduplicationCheck dedupCheck = deduplicationService.isDuplicate(candidate, cooldown);
        if (dedupCheck.isDuplicate() && candidate.getBasePriority() != NotificationPriority.CRITICAL) {
            return buildSuppressedDecision(candidate, dedupCheck.reason());
        }

        // 5. Fatigue Assessment
        NotificationFatigueService.FatigueAssessment fatigue = fatigueService.calculateFatigue(userId);

        // 6. ML Scoring
        NotificationScoringService.NotificationScoringResult scores = scoringService.scoreCandidate(
                candidate, fatigue.fatigueScore(), 0.45
        );

        // 7. Threshold & Value Check
        boolean isCritical = candidate.getBasePriority() == NotificationPriority.CRITICAL;
        if (!isCritical && scores.finalScore().compareTo(new BigDecimal("0.35")) < 0) {
            return buildSuppressedDecision(candidate, "Low relevance/value score: " + scores.finalScore());
        }

        // 8. Compose Copy & Action
        NotificationComposer.ComposedNotification composed = notificationComposer.compose(candidate);

        // 9. Channel Selection & Fatigue Limits
        NotificationChannel targetChannel = NotificationChannel.PUSH;
        NotificationDecisionType decisionType;

        if (fatigue.isDailyPushExceeded() || fatigue.isHourlyExceeded()) {
            if (!isCritical) {
                targetChannel = NotificationChannel.IN_APP; // Downgrade to in-app
            }
        } else if (scores.finalScore().compareTo(new BigDecimal("0.60")) < 0 && !isCritical) {
            targetChannel = NotificationChannel.IN_APP;
        }

        // 10. Timing Optimization
        NotificationTimingService.TimingRecommendation timing = timingService.determineDeliveryTime(candidate, preference);
        if (timing.sendImmediately()) {
            decisionType = (targetChannel == NotificationChannel.PUSH) ?
                    NotificationDecisionType.SEND_NOW : NotificationDecisionType.IN_APP_ONLY;
        } else {
            decisionType = NotificationDecisionType.SCHEDULE;
        }

        return NotificationDecision.builder()
                .candidate(candidate)
                .decisionType(decisionType)
                .channel(targetChannel)
                .resolvedPriority(candidate.getBasePriority() != null ? candidate.getBasePriority() : NotificationPriority.MEDIUM)
                .finalTitle(composed.title())
                .finalBody(composed.body())
                .actionLabel(composed.actionLabel())
                .actionDeepLink(composed.actionRoute())
                .urgencyScore(scores.urgencyScore())
                .relevanceScore(scores.relevanceScore())
                .confidenceScore(scores.confidenceScore())
                .actionProbability(scores.actionProbability())
                .fatigueScore(scores.fatigueScore())
                .finalScore(scores.finalScore())
                .scheduledFor(timing.deliveryTimestamp())
                .rationale(timing.reason() + "; " + fatigue.diagnosticReason())
                .grouped(false)
                .build();
    }

    private NotificationDecision buildSuppressedDecision(NotificationCandidate candidate, String reason) {
        return NotificationDecision.builder()
                .candidate(candidate)
                .decisionType(NotificationDecisionType.SUPPRESS)
                .channel(NotificationChannel.SILENT)
                .resolvedPriority(NotificationPriority.LOW)
                .finalTitle(candidate.getProposedTitle())
                .finalBody(candidate.getProposedBody())
                .urgencyScore(BigDecimal.ZERO)
                .relevanceScore(BigDecimal.ZERO)
                .confidenceScore(BigDecimal.ZERO)
                .actionProbability(BigDecimal.ZERO)
                .fatigueScore(BigDecimal.ONE)
                .finalScore(BigDecimal.ZERO)
                .rationale(reason)
                .grouped(false)
                .build();
    }

    private Duration resolveCooldown(NotificationCandidate candidate) {
        if (candidate.getType() == null) return Duration.ofHours(24);
        return switch (candidate.getType().canonical()) {
            case OUT_OF_STOCK -> Duration.ofHours(12);
            case LOW_STOCK -> Duration.ofHours(24);
            case EXPIRY_REMINDER -> Duration.ofHours(24);
            case SMART_RESTOCK_SUGGESTION -> Duration.ofHours(72);
            default -> Duration.ofHours(24);
        };
    }
}
