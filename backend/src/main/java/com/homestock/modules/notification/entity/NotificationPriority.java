package com.homestock.modules.notification.entity;

public enum NotificationPriority {
    CRITICAL,
    HIGH,
    MEDIUM,
    LOW;

    public static NotificationPriority fromType(NotificationType type) {
        if (type == null) return MEDIUM;
        return switch (type.canonical()) {
            case OUT_OF_STOCK -> CRITICAL;
            case EXPIRY_REMINDER -> HIGH;
            case LOW_STOCK, FAMILY_ACTIVITY, SHOPPING_LIST_UPDATE, SMART_RESTOCK_SUGGESTION -> MEDIUM;
            case WEEKLY_INSIGHT, MONTHLY_REPORT, PURCHASE_RECORDED, STOCK_UPDATED, SYNC_COMPLETED, SYSTEM -> LOW;
            default -> MEDIUM;
        };
    }
}

