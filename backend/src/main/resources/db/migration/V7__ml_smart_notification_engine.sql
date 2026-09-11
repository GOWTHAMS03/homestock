-- ===================================================================
-- HomeStock ML Smart Notification Engine Migration (V7)
-- Adds event tracking, ML features, scoring metadata,
-- user interaction outcomes, and grouped notification digests.
-- ===================================================================

-- 1. Notification Events Table (Audit & ML Training Dataset)
CREATE TABLE IF NOT EXISTS notification_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id UUID REFERENCES notifications(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    home_id UUID NOT NULL REFERENCES homes(id) ON DELETE CASCADE,
    inventory_item_id UUID REFERENCES inventory_items(id) ON DELETE SET NULL,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    
    notification_type VARCHAR(50) NOT NULL,
    priority VARCHAR(20) NOT NULL,
    channel VARCHAR(20) NOT NULL DEFAULT 'IN_APP',
    decision VARCHAR(30) NOT NULL,
    event_type VARCHAR(30) NOT NULL,
    action_type VARCHAR(40),
    
    urgency_score NUMERIC(5, 4) NOT NULL DEFAULT 0.0,
    relevance_score NUMERIC(5, 4) NOT NULL DEFAULT 0.0,
    confidence_score NUMERIC(5, 4) NOT NULL DEFAULT 0.0,
    action_probability NUMERIC(5, 4) NOT NULL DEFAULT 0.0,
    fatigue_score NUMERIC(5, 4) NOT NULL DEFAULT 0.0,
    final_score NUMERIC(5, 4) NOT NULL DEFAULT 0.0,
    predicted_days_remaining NUMERIC(6, 2),
    
    dedup_key VARCHAR(255),
    scheduled_for TIMESTAMP WITH TIME ZONE,
    occurred_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_notif_events_user ON notification_events(user_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_notif_events_home ON notification_events(home_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_notif_events_type ON notification_events(notification_type);
CREATE INDEX IF NOT EXISTS idx_notif_events_event_type ON notification_events(event_type);
CREATE INDEX IF NOT EXISTS idx_notif_events_item ON notification_events(inventory_item_id);
CREATE INDEX IF NOT EXISTS idx_notif_events_dedup ON notification_events(dedup_key);

-- 2. Notification Digests Table (Grouped Household Multi-Product Alerts)
CREATE TABLE IF NOT EXISTS notification_digests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    home_id UUID NOT NULL REFERENCES homes(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    summary_text TEXT NOT NULL,
    item_count INT NOT NULL DEFAULT 0,
    estimated_total_cost NUMERIC(12, 2) DEFAULT 0.00,
    item_ids_json TEXT,
    item_names_json TEXT,
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_notif_digests_home ON notification_digests(home_id, created_at DESC);
