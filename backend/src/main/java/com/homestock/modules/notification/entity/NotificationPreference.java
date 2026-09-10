package com.homestock.modules.notification.entity;

import com.homestock.core.common.BaseEntity;
import com.homestock.modules.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalTime;

@Entity
@Table(name = "notification_preferences", indexes = {
    @Index(name = "idx_notif_pref_user", columnList = "user_id", unique = true)
})
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationPreference extends BaseEntity {

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Builder.Default
    @Column(name = "low_stock_enabled", nullable = false)
    private Boolean lowStockEnabled = true;

    @Builder.Default
    @Column(name = "out_of_stock_enabled", nullable = false)
    private Boolean outOfStockEnabled = true;

    @Builder.Default
    @Column(name = "expiry_enabled", nullable = false)
    private Boolean expiryEnabled = true;

    @Builder.Default
    @Column(name = "shopping_list_enabled", nullable = false)
    private Boolean shoppingListEnabled = true;

    @Builder.Default
    @Column(name = "family_activity_enabled", nullable = false)
    private Boolean familyActivityEnabled = true;

    @Builder.Default
    @Column(name = "purchase_enabled", nullable = false)
    private Boolean purchaseEnabled = true;

    @Builder.Default
    @Column(name = "smart_suggestion_enabled", nullable = false)
    private Boolean smartSuggestionEnabled = true;

    @Builder.Default
    @Column(name = "weekly_insight_enabled", nullable = false)
    private Boolean weeklyInsightEnabled = true;

    @Builder.Default
    @Column(name = "monthly_report_enabled", nullable = false)
    private Boolean monthlyReportEnabled = true;

    @Builder.Default
    @Column(name = "quiet_hours_enabled", nullable = false)
    private Boolean quietHoursEnabled = true;

    @Builder.Default
    @Column(name = "quiet_hours_start", nullable = false)
    private LocalTime quietHoursStart = LocalTime.of(22, 0);

    @Builder.Default
    @Column(name = "quiet_hours_end", nullable = false)
    private LocalTime quietHoursEnd = LocalTime.of(7, 0);

    public boolean isNotificationTypeEnabled(NotificationType type) {
        if (type == null) return true;
        return switch (type.canonical()) {
            case LOW_STOCK -> Boolean.TRUE.equals(lowStockEnabled);
            case OUT_OF_STOCK -> Boolean.TRUE.equals(outOfStockEnabled);
            case EXPIRY_REMINDER -> Boolean.TRUE.equals(expiryEnabled);
            case SHOPPING_LIST_UPDATE -> Boolean.TRUE.equals(shoppingListEnabled);
            case FAMILY_ACTIVITY, STOCK_UPDATED -> Boolean.TRUE.equals(familyActivityEnabled);
            case PURCHASE_RECORDED -> Boolean.TRUE.equals(purchaseEnabled);
            case SMART_RESTOCK_SUGGESTION -> Boolean.TRUE.equals(smartSuggestionEnabled);
            case WEEKLY_INSIGHT -> Boolean.TRUE.equals(weeklyInsightEnabled);
            case MONTHLY_REPORT -> Boolean.TRUE.equals(monthlyReportEnabled);
            case SYNC_COMPLETED, SYSTEM -> true;
            default -> true;
        };
    }

    /**
     * Checks if a given time falls inside quiet hours, properly supporting midnight-crossing ranges (e.g. 22:00 -> 07:00).
     */
    public boolean isInsideQuietHours(LocalTime time) {
        if (!Boolean.TRUE.equals(quietHoursEnabled) || quietHoursStart == null || quietHoursEnd == null) {
            return false;
        }
        if (quietHoursStart.equals(quietHoursEnd)) {
            return false;
        }
        if (quietHoursStart.isBefore(quietHoursEnd)) {
            // Same day range (e.g., 01:00 to 06:00)
            return !time.isBefore(quietHoursStart) && time.isBefore(quietHoursEnd);
        } else {
            // Midnight-crossing range (e.g., 22:00 to 07:00)
            return !time.isBefore(quietHoursStart) || time.isBefore(quietHoursEnd);
        }
    }
}

