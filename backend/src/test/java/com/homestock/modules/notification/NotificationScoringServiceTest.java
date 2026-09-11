package com.homestock.modules.notification;

import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.notification.dto.NotificationCandidate;
import com.homestock.modules.notification.entity.NotificationPriority;
import com.homestock.modules.notification.entity.NotificationType;
import com.homestock.modules.notification.ml.NotificationScoringService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.*;

class NotificationScoringServiceTest {

    private NotificationScoringService scoringService;

    @BeforeEach
    void setUp() {
        scoringService = new NotificationScoringService();
    }

    @Test
    @DisplayName("High urgency staple with deal should achieve high notification score")
    void testHighUrgencyStapleScore() {
        InventoryItem oil = InventoryItem.builder()
                .name("Fortune Sunflower Oil")
                .quantity(new BigDecimal("0.2"))
                .unit("L")
                .build();

        NotificationCandidate candidate = NotificationCandidate.builder()
                .inventoryItem(oil)
                .type(NotificationType.LOW_STOCK)
                .basePriority(NotificationPriority.HIGH)
                .probabilityWithin1Day(0.85)
                .probabilityWithin3Days(0.96)
                .confidence("HIGH")
                .dealAvailable(true)
                .regularPrice(new BigDecimal("145.00"))
                .dealPrice(new BigDecimal("119.00"))
                .potentialSavings(new BigDecimal("26.00"))
                .build();

        var scores = scoringService.scoreCandidate(candidate, 0.10, 0.60);

        assertNotNull(scores);
        assertTrue(scores.finalScore().compareTo(new BigDecimal("0.70")) >= 0,
                "Expected score >= 0.70, but was: " + scores.finalScore());
        assertTrue(scores.urgencyScore().compareTo(new BigDecimal("0.90")) >= 0);
        assertTrue(scores.relevanceScore().compareTo(new BigDecimal("0.90")) >= 0);
    }

    @Test
    @DisplayName("High fatigue should penalize and reduce the final notification score")
    void testFatiguePenalization() {
        InventoryItem item = InventoryItem.builder().name("Salt").build();
        NotificationCandidate candidate = NotificationCandidate.builder()
                .inventoryItem(item)
                .type(NotificationType.SMART_RESTOCK_SUGGESTION)
                .basePriority(NotificationPriority.MEDIUM)
                .probabilityWithin7Days(0.50)
                .confidence("MEDIUM")
                .build();

        var lowFatigueScores = scoringService.scoreCandidate(candidate, 0.05, 0.40);
        var highFatigueScores = scoringService.scoreCandidate(candidate, 0.95, 0.40);

        assertTrue(highFatigueScores.finalScore().compareTo(lowFatigueScores.finalScore()) < 0,
                "Score with high fatigue should be lower than low fatigue");
    }
}
