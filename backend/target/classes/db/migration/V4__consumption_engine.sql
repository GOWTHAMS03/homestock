-- V4: Zero-Manual-Tracking & Smart Consumption Engine Schema
-- Adds consumption_profiles, consumption_cycles, and enhancements to inventory_items

-- 1. Update inventory_items with consumption status and source fields
ALTER TABLE inventory_items
    ADD COLUMN IF NOT EXISTS quantity_status VARCHAR(30) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS quantity_source VARCHAR(20) NOT NULL DEFAULT 'VERIFIED',
    ADD COLUMN IF NOT EXISTS last_verified_at TIMESTAMPTZ DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS last_estimated_at TIMESTAMPTZ DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS confidence VARCHAR(20) NOT NULL DEFAULT 'HIGH';

-- 2. Consumption Profiles Table
CREATE TABLE IF NOT EXISTS consumption_profiles (
    id UUID PRIMARY KEY,
    home_id UUID NOT NULL REFERENCES homes(id) ON DELETE CASCADE,
    inventory_item_id UUID NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    average_daily_consumption NUMERIC(12, 4) NOT NULL DEFAULT 0.0,
    weighted_daily_consumption NUMERIC(12, 4) NOT NULL DEFAULT 0.0,
    min_daily_consumption NUMERIC(12, 4) NOT NULL DEFAULT 0.0,
    max_daily_consumption NUMERIC(12, 4) NOT NULL DEFAULT 0.0,
    consumption_variability NUMERIC(8, 4) NOT NULL DEFAULT 0.0,
    average_purchase_interval NUMERIC(8, 2) NOT NULL DEFAULT 0.0,
    last_purchase_date DATE,
    last_purchase_quantity NUMERIC(10, 3),
    estimated_days_remaining INT,
    confidence VARCHAR(20) NOT NULL DEFAULT 'LOW',
    sample_count INT NOT NULL DEFAULT 0,
    last_calculated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_consumption_item UNIQUE (home_id, inventory_item_id)
);

CREATE INDEX IF NOT EXISTS idx_consumption_home ON consumption_profiles(home_id);
CREATE INDEX IF NOT EXISTS idx_consumption_item ON consumption_profiles(inventory_item_id);

-- 3. Consumption Cycles Table
CREATE TABLE IF NOT EXISTS consumption_cycles (
    id UUID PRIMARY KEY,
    home_id UUID NOT NULL REFERENCES homes(id) ON DELETE CASCADE,
    inventory_item_id UUID NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    previous_purchase_id UUID REFERENCES purchases(id) ON DELETE SET NULL,
    current_purchase_id UUID REFERENCES purchases(id) ON DELETE SET NULL,
    previous_purchase_date DATE NOT NULL,
    current_purchase_date DATE NOT NULL,
    quantity NUMERIC(10, 3) NOT NULL,
    interval_days INT NOT NULL,
    estimated_daily_consumption NUMERIC(12, 4) NOT NULL,
    is_anomaly BOOLEAN NOT NULL DEFAULT false,
    anomaly_reason VARCHAR(255),
    confidence VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_cycles_home_item ON consumption_cycles(home_id, inventory_item_id);
CREATE INDEX IF NOT EXISTS idx_cycles_current_date ON consumption_cycles(current_purchase_date DESC);
