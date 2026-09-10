package com.homestock.modules.notification.entity;

public enum NotificationType {
    LOW_STOCK,
    OUT_OF_STOCK,
    EXPIRY_REMINDER,
    SHOPPING_LIST_UPDATE,
    FAMILY_ACTIVITY,
    PURCHASE_RECORDED,
    STOCK_UPDATED,
    SMART_RESTOCK_SUGGESTION,
    WEEKLY_INSIGHT,
    MONTHLY_REPORT,
    SYNC_COMPLETED,
    SYSTEM,

    // Backward-compatibility aliases (map to EXPIRY_REMINDER)
    EXPIRING_SOON,
    EXPIRED;

    public NotificationType canonical() {
        if (this == EXPIRING_SOON || this == EXPIRED) {
            return EXPIRY_REMINDER;
        }
        return this;
    }
}
