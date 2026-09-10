package com.homestock.modules.notification.dto;

import com.homestock.modules.notification.entity.NotificationPreference;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationPreferenceDto {
    private Boolean lowStockEnabled;
    private Boolean outOfStockEnabled;
    private Boolean expiryEnabled;
    private Boolean shoppingListEnabled;
    private Boolean familyActivityEnabled;
    private Boolean purchaseEnabled;
    private Boolean smartSuggestionEnabled;
    private Boolean weeklyInsightEnabled;
    private Boolean monthlyReportEnabled;
    private Boolean quietHoursEnabled;
    private LocalTime quietHoursStart;
    private LocalTime quietHoursEnd;

    public static NotificationPreferenceDto fromEntity(NotificationPreference entity) {
        if (entity == null) return null;
        return NotificationPreferenceDto.builder()
                .lowStockEnabled(entity.getLowStockEnabled())
                .outOfStockEnabled(entity.getOutOfStockEnabled())
                .expiryEnabled(entity.getExpiryEnabled())
                .shoppingListEnabled(entity.getShoppingListEnabled())
                .familyActivityEnabled(entity.getFamilyActivityEnabled())
                .purchaseEnabled(entity.getPurchaseEnabled())
                .smartSuggestionEnabled(entity.getSmartSuggestionEnabled())
                .weeklyInsightEnabled(entity.getWeeklyInsightEnabled())
                .monthlyReportEnabled(entity.getMonthlyReportEnabled())
                .quietHoursEnabled(entity.getQuietHoursEnabled())
                .quietHoursStart(entity.getQuietHoursStart())
                .quietHoursEnd(entity.getQuietHoursEnd())
                .build();
    }
}

