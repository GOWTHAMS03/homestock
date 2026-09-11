-- V8: While You Were Away - Smart Household Gap Intelligence Schema

-- 1. User Activity Logs Table (Heartbeat and Action Tracking)
CREATE TABLE IF NOT EXISTS user_activity_logs (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    home_id UUID NOT NULL REFERENCES homes(id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL,
    metadata VARCHAR(500),
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_activity_user_time ON user_activity_logs(user_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_home_time ON user_activity_logs(home_id, occurred_at DESC);

-- 2. Away Period Summaries Table
CREATE TABLE IF NOT EXISTS away_period_summaries (
    id UUID PRIMARY KEY,
    home_id UUID NOT NULL REFERENCES homes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    away_days INT NOT NULL,
    from_date TIMESTAMPTZ NOT NULL,
    to_date TIMESTAMPTZ NOT NULL,
    important_changes INT NOT NULL DEFAULT 0,
    predicted_low_stock INT NOT NULL DEFAULT 0,
    predicted_finished INT NOT NULL DEFAULT 0,
    expiry_risks INT NOT NULL DEFAULT 0,
    is_reviewed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_away_summary_home_user ON away_period_summaries(home_id, user_id, is_reviewed);
CREATE INDEX IF NOT EXISTS idx_away_summary_created ON away_period_summaries(created_at DESC);

-- 3. Away Predictions Table (Item-level predicted changes)
CREATE TABLE IF NOT EXISTS away_predictions (
    id UUID PRIMARY KEY,
    summary_id UUID NOT NULL REFERENCES away_period_summaries(id) ON DELETE CASCADE,
    inventory_item_id UUID NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
    item_name VARCHAR(150) NOT NULL,
    prediction_type VARCHAR(40) NOT NULL,
    event_classification VARCHAR(30) NOT NULL DEFAULT 'PREDICTED_EVENT',
    stock_before_away NUMERIC(12, 3),
    estimated_quantity NUMERIC(12, 3) NOT NULL,
    estimated_consumed NUMERIC(12, 3) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    confidence NUMERIC(5, 4) NOT NULL,
    reason VARCHAR(255) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    is_top_priority BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_away_pred_summary ON away_predictions(summary_id);
CREATE INDEX IF NOT EXISTS idx_away_pred_item ON away_predictions(inventory_item_id);

-- 4. Prediction Feedback Table (Learning from user confirmations and corrections)
CREATE TABLE IF NOT EXISTS prediction_feedback (
    id UUID PRIMARY KEY,
    prediction_id UUID REFERENCES away_predictions(id) ON DELETE SET NULL,
    inventory_item_id UUID NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
    home_id UUID NOT NULL REFERENCES homes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    feedback_type VARCHAR(30) NOT NULL,
    predicted_quantity NUMERIC(12, 3) NOT NULL,
    actual_quantity NUMERIC(12, 3),
    error_delta NUMERIC(12, 3),
    learning_adjustment_factor NUMERIC(8, 4) NOT NULL DEFAULT 1.0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pred_feedback_item ON prediction_feedback(inventory_item_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_pred_feedback_home ON prediction_feedback(home_id);
