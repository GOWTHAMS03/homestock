package com.homestock.modules.notification.ml;

import com.homestock.modules.notification.dto.NotificationCandidate;
import lombok.Getter;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * NotificationScoringService:
 * Evaluates candidate alerts across Urgency, Relevance, Confidence, Action Probability,
 * and penalizes by Fatigue Score using configurable weights.
 */
@Slf4j
@Service
@Getter
@Setter
public class NotificationScoringService {

    @Value("${app.notifications.scoring.weight-urgency:0.30}")
    private double weightUrgency = 0.30;

    @Value("${app.notifications.scoring.weight-relevance:0.25}")
    private double weightRelevance = 0.25;

    @Value("${app.notifications.scoring.weight-confidence:0.20}")
    private double weightConfidence = 0.20;

    @Value("${app.notifications.scoring.weight-action-probability:0.15}")
    private double weightActionProbability = 0.15;

    @Value("${app.notifications.scoring.weight-fatigue:0.10}")
    private double weightFatigue = 0.10;

    public NotificationScoringResult scoreCandidate(NotificationCandidate candidate, double fatigueScore, double userHistoricalActionRate) {
        double urgency = calculateUrgency(candidate);
        double relevance = calculateRelevance(candidate);
        double confidence = calculateConfidence(candidate);
        double actionProb = calculateActionProbability(candidate, userHistoricalActionRate);

        // Configurable weighted formula
        double rawScore = (urgency * weightUrgency)
                + (relevance * weightRelevance)
                + (confidence * weightConfidence)
                + (actionProb * weightActionProbability)
                - (fatigueScore * weightFatigue);

        // Bound to [0.0, 1.0]
        double finalScore = Math.max(0.0, Math.min(1.0, rawScore));

        return new NotificationScoringResult(
                BigDecimal.valueOf(urgency).setScale(4, RoundingMode.HALF_UP),
                BigDecimal.valueOf(relevance).setScale(4, RoundingMode.HALF_UP),
                BigDecimal.valueOf(confidence).setScale(4, RoundingMode.HALF_UP),
                BigDecimal.valueOf(actionProb).setScale(4, RoundingMode.HALF_UP),
                BigDecimal.valueOf(fatigueScore).setScale(4, RoundingMode.HALF_UP),
                BigDecimal.valueOf(finalScore).setScale(4, RoundingMode.HALF_UP)
        );
    }

    private double calculateUrgency(NotificationCandidate candidate) {
        if (candidate.getType() == null) return 0.5;

        switch (candidate.getType().canonical()) {
            case OUT_OF_STOCK:
                return 1.00;

            case EXPIRY_REMINDER:
                return 0.85;

            case LOW_STOCK:
            case SMART_RESTOCK_SUGGESTION:
                if (candidate.getProbabilityWithin1Day() != null && candidate.getProbabilityWithin1Day() >= 0.75) {
                    return 0.95;
                } else if (candidate.getProbabilityWithin3Days() != null && candidate.getProbabilityWithin3Days() >= 0.70) {
                    return 0.80;
                } else if (candidate.getProbabilityWithin7Days() != null && candidate.getProbabilityWithin7Days() >= 0.60) {
                    return 0.50;
                }
                return 0.35;

            case FAMILY_ACTIVITY:
            case STOCK_UPDATED:
            case PURCHASE_RECORDED:
                return 0.65;

            case SHOPPING_LIST_UPDATE:
                return 0.60;

            case WEEKLY_INSIGHT:
            case MONTHLY_REPORT:
                return 0.30;

            default:
                return 0.50;
        }
    }

    private double calculateRelevance(NotificationCandidate candidate) {
        double relevance = 0.70;

        if (candidate.getInventoryItem() != null) {
            String name = candidate.getInventoryItem().getName() != null ? candidate.getInventoryItem().getName().toLowerCase() : "";
            // High staple relevance for essential household items
            if (name.contains("oil") || name.contains("rice") || name.contains("milk") ||
                    name.contains("dal") || name.contains("atta") || name.contains("salt")) {
                relevance += 0.20;
            }
        }

        // Boost if money-saving deal is available
        if (candidate.isDealAvailable()) {
            relevance += 0.10;
        }

        return Math.min(1.0, relevance);
    }

    private double calculateConfidence(NotificationCandidate candidate) {
        String conf = candidate.getConfidence();
        if ("HIGH".equalsIgnoreCase(conf)) return 0.95;
        if ("MEDIUM".equalsIgnoreCase(conf)) return 0.75;
        if ("LOW".equalsIgnoreCase(conf)) return 0.55;
        return 0.70;
    }

    private double calculateActionProbability(NotificationCandidate candidate, double historicalRate) {
        double base = historicalRate > 0 ? historicalRate : 0.45;

        // If high urgency or deal available, action probability increases
        if (candidate.isDealAvailable()) {
            base += 0.15;
        }
        if (candidate.getProbabilityWithin1Day() != null && candidate.getProbabilityWithin1Day() > 0.80) {
            base += 0.20;
        }

        return Math.min(1.0, Math.max(0.05, base));
    }

    public record NotificationScoringResult(
            BigDecimal urgencyScore,
            BigDecimal relevanceScore,
            BigDecimal confidenceScore,
            BigDecimal actionProbability,
            BigDecimal fatigueScore,
            BigDecimal finalScore
    ) {}
}
