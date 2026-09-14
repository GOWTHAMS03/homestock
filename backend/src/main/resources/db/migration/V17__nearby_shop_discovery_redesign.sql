-- ===================================================================
-- V17: Production-Grade Nearby Shop Discovery Architecture
-- ===================================================================

-- 1. Extend nearby_shops table with deduplication, provenance, and confidence scoring
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS normalized_name VARCHAR(150);
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS source VARCHAR(50) NOT NULL DEFAULT 'OSM';
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS source_id VARCHAR(100);
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS category VARCHAR(50);
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS confidence_score INTEGER NOT NULL DEFAULT 70;
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS last_osm_sync_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS last_verified_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS user_report_count INTEGER NOT NULL DEFAULT 0;

-- Backfill normalized names for existing seed shops
UPDATE nearby_shops SET normalized_name = LOWER(name) WHERE normalized_name IS NULL;

-- Indexes for performance and location filtering
CREATE INDEX IF NOT EXISTS idx_ns_active ON nearby_shops(active);
CREATE INDEX IF NOT EXISTS idx_ns_normalized_name ON nearby_shops(normalized_name);
CREATE INDEX IF NOT EXISTS idx_ns_confidence ON nearby_shops(confidence_score);
CREATE INDEX IF NOT EXISTS idx_ns_source ON nearby_shops(source);

-- 2. Geographic Grid & Background Synchronization Metadata Table
CREATE TABLE IF NOT EXISTS shop_area_grids (
    grid_key VARCHAR(60) PRIMARY KEY,
    geohash VARCHAR(12),
    center_lat NUMERIC(10, 7) NOT NULL,
    center_lon NUMERIC(10, 7) NOT NULL,
    radius_meters INTEGER NOT NULL,
    last_sync_at TIMESTAMP WITH TIME ZONE,
    shop_count INTEGER NOT NULL DEFAULT 0,
    sync_status VARCHAR(30) NOT NULL DEFAULT 'PENDING', -- PENDING, SYNCING, COMPLETED, FAILED
    failure_reason VARCHAR(255),
    sync_attempts INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sag_sync_status ON shop_area_grids(sync_status);
CREATE INDEX IF NOT EXISTS idx_sag_last_sync ON shop_area_grids(last_sync_at);
CREATE INDEX IF NOT EXISTS idx_sag_coords ON shop_area_grids(center_lat, center_lon);
