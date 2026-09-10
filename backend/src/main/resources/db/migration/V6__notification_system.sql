-- ===================================================================
-- HomeStock Notification System Migration (V6)
-- Adds priorities, deduplication keys, quiet hours preferences,
-- device tokens, and deduplication tracking.
-- ===================================================================

-- 1. Upgrade existing notifications table
ALTER TABLE notifications
    ADD COLUMN IF NOT EXISTS priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    ADD COLUMN IF NOT EXISTS read_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS dedup_key VARCHAR(255);

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_dedup_key ON notifications(dedup_key);

-- 2. Device Tokens for Firebase Push Notifications
CREATE TABLE IF NOT EXISTS device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_token VARCHAR(500) NOT NULL,
    platform VARCHAR(20) NOT NULL DEFAULT 'ANDROID',
    device_name VARCHAR(120),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_seen_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_device_token UNIQUE (device_token)
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens(user_id);

-- 3. User Notification Preferences & Quiet Hours
CREATE TABLE IF NOT EXISTS notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    low_stock_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    out_of_stock_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    expiry_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    shopping_list_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    family_activity_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    purchase_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    smart_suggestion_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    weekly_insight_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    monthly_report_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    quiet_hours_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    quiet_hours_start TIME NOT NULL DEFAULT '22:00:00',
    quiet_hours_end TIME NOT NULL DEFAULT '07:00:00',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_user_preferences UNIQUE (user_id)
);

CREATE INDEX IF NOT EXISTS idx_notif_pref_user ON notification_preferences(user_id);

-- 4. Notification Deduplication Tracking & Cooldowns
CREATE TABLE IF NOT EXISTS notification_deduplications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dedup_key VARCHAR(255) NOT NULL UNIQUE,
    home_id UUID NOT NULL,
    last_sent_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_quantity NUMERIC(12, 3),
    last_status VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_notif_dedup_key ON notification_deduplications(dedup_key);
CREATE INDEX IF NOT EXISTS idx_notif_dedup_home ON notification_deduplications(home_id);

