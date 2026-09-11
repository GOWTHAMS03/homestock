package com.homestock.modules.notification.dto;

import com.homestock.modules.home.entity.Home;
import com.homestock.modules.inventory.entity.InventoryItem;
import com.homestock.modules.notification.entity.NotificationPriority;
import com.homestock.modules.notification.entity.NotificationType;
import com.homestock.modules.user.entity.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;

/**
 * NotificationCandidate:
 * A raw event or condition proposing a notification before passing through
 * the ML Smart Notification Engine.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationCandidate {

    private Home home;
    private User recipientUser;
    private User triggerUser; // e.g. Dad who made a purchase or updated stock
    private InventoryItem inventoryItem;

    private NotificationType type;
    private NotificationPriority basePriority;

    private String proposedTitle;
    private String proposedBody;
    private String dedupKey;

    private BigDecimal currentStock;
    private String unit;

    // ML Predictions (populated by StockPredictionService if applicable)
    private BigDecimal predictedDaysRemaining;
    private Double probabilityWithin1Day;
    private Double probabilityWithin3Days;
    private Double probabilityWithin7Days;
    private String confidence; // LOW, MEDIUM, HIGH

    // Deal context (if product deal is available)
    private boolean dealAvailable;
    private BigDecimal regularPrice;
    private BigDecimal dealPrice;
    private BigDecimal potentialSavings;
    private String dealUrl;
    private String dealStore;

    // Custom metadata payload
    private Map<String, String> payload;

    private Instant candidateTimestamp;
}
