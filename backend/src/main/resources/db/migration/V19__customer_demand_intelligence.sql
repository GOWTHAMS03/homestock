-- ===================================================================
-- V19: Customer Demand Intelligence for Shop Owners
--      Privacy-safe aggregated interaction events, spatial indexes,
--      and realistic initial local commerce demand seed data
-- ===================================================================

CREATE TABLE IF NOT EXISTS customer_demand_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(30) NOT NULL, -- SEARCH, PRODUCT_VIEW, BARCODE_SCAN, SHOPPING_LIST_ADD, VOICE_ADD, NEARBY_SEARCH, SHOP_PRODUCT_VIEW
    query_text VARCHAR(255) NOT NULL,
    normalized_query VARCHAR(255) NOT NULL,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    category_name VARCHAR(100),
    latitude NUMERIC(10, 7) NOT NULL,
    longitude NUMERIC(10, 7) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cde_coords_created ON customer_demand_events(created_at, latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_cde_norm_created ON customer_demand_events(normalized_query, created_at);
CREATE INDEX IF NOT EXISTS idx_cde_product_created ON customer_demand_events(product_id, created_at);
CREATE INDEX IF NOT EXISTS idx_cde_type_created ON customer_demand_events(event_type, created_at);

-- Seed realistic recent demand events around metropolitan area (12.9716, 77.5946)
-- Spanning today, last 7 days, and previous 7-14 days for immediate trend detection

-- 1. Rice (High Demand, Rising trend: ~220 current vs ~170 previous)
INSERT INTO customer_demand_events (event_type, query_text, normalized_query, category_name, latitude, longitude, created_at)
SELECT 
    CASE (i % 5)
        WHEN 0 THEN 'SEARCH'
        WHEN 1 THEN 'NEARBY_SEARCH'
        WHEN 2 THEN 'SHOPPING_LIST_ADD'
        WHEN 3 THEN 'VOICE_ADD'
        ELSE 'PRODUCT_VIEW'
    END,
    'Ponni Boiled Rice',
    'ponni boiled rice',
    'Grains & Rice',
    12.9716 + (sin(i) * 0.02),
    77.5946 + (cos(i) * 0.02),
    NOW() - (i % 7) * INTERVAL '1 day' - (i * 12) * INTERVAL '1 minute'
FROM generate_series(1, 140) AS i;

INSERT INTO customer_demand_events (event_type, query_text, normalized_query, category_name, latitude, longitude, created_at)
SELECT 
    'SEARCH',
    'Ponni Boiled Rice',
    'ponni boiled rice',
    'Grains & Rice',
    12.9716 + (sin(i) * 0.02),
    77.5946 + (cos(i) * 0.02),
    NOW() - (7 + (i % 7)) * INTERVAL '1 day'
FROM generate_series(1, 100) AS i;

-- 2. Sugar (Steady High Demand)
INSERT INTO customer_demand_events (event_type, query_text, normalized_query, category_name, latitude, longitude, created_at)
SELECT 
    CASE (i % 4)
        WHEN 0 THEN 'SEARCH'
        WHEN 1 THEN 'SHOPPING_LIST_ADD'
        WHEN 2 THEN 'NEARBY_SEARCH'
        ELSE 'VOICE_ADD'
    END,
    'White Crystal Sugar',
    'white crystal sugar',
    'Staples',
    12.9716 + (cos(i) * 0.015),
    77.5946 + (sin(i) * 0.015),
    NOW() - (i % 7) * INTERVAL '1 day' - (i * 15) * INTERVAL '1 minute'
FROM generate_series(1, 110) AS i;

INSERT INTO customer_demand_events (event_type, query_text, normalized_query, category_name, latitude, longitude, created_at)
SELECT 
    'SEARCH',
    'White Crystal Sugar',
    'white crystal sugar',
    'Staples',
    12.9716 + (cos(i) * 0.015),
    77.5946 + (sin(i) * 0.015),
    NOW() - (7 + (i % 7)) * INTERVAL '1 day'
FROM generate_series(1, 95) AS i;

-- 3. Sunflower Oil (Rising: 90 current vs 50 previous)
INSERT INTO customer_demand_events (event_type, query_text, normalized_query, category_name, latitude, longitude, created_at)
SELECT 
    'NEARBY_SEARCH',
    'Sunflower Oil 1L',
    'sunflower oil 1l',
    'Edible Oils',
    12.9716 + (sin(i * 2) * 0.025),
    77.5946 + (cos(i * 2) * 0.025),
    NOW() - (i % 7) * INTERVAL '1 day' - (i * 25) * INTERVAL '1 minute'
FROM generate_series(1, 90) AS i;

INSERT INTO customer_demand_events (event_type, query_text, normalized_query, category_name, latitude, longitude, created_at)
SELECT 
    'SEARCH',
    'Sunflower Oil 1L',
    'sunflower oil 1l',
    'Edible Oils',
    12.9716 + (sin(i * 2) * 0.025),
    77.5946 + (cos(i * 2) * 0.025),
    NOW() - (7 + (i % 7)) * INTERVAL '1 day'
FROM generate_series(1, 50) AS i;

-- 4. Aashirvaad Atta (High Demand Missing Product: 85 searches current)
INSERT INTO customer_demand_events (event_type, query_text, normalized_query, category_name, latitude, longitude, created_at)
SELECT 
    CASE (i % 3)
        WHEN 0 THEN 'SEARCH'
        WHEN 1 THEN 'NEARBY_SEARCH'
        ELSE 'SHOPPING_LIST_ADD'
    END,
    'Aashirvaad Whole Wheat Atta 5kg',
    'aashirvaad whole wheat atta 5kg',
    'Atta & Flours',
    12.9716 + (cos(i) * 0.018),
    77.5946 + (sin(i) * 0.018),
    NOW() - (i % 7) * INTERVAL '1 day' - (i * 30) * INTERVAL '1 minute'
FROM generate_series(1, 85) AS i;

-- 5. Toor Dal (Normal: 65 current vs 60 previous)
INSERT INTO customer_demand_events (event_type, query_text, normalized_query, category_name, latitude, longitude, created_at)
SELECT 
    'SEARCH',
    'Organic Toor Dal 1kg',
    'organic toor dal 1kg',
    'Dals & Pulses',
    12.9716 + (sin(i * 3) * 0.02),
    77.5946 + (cos(i * 3) * 0.02),
    NOW() - (i % 7) * INTERVAL '1 day' - (i * 45) * INTERVAL '1 minute'
FROM generate_series(1, 65) AS i;

INSERT INTO customer_demand_events (event_type, query_text, normalized_query, category_name, latitude, longitude, created_at)
SELECT 
    'SEARCH',
    'Organic Toor Dal 1kg',
    'organic toor dal 1kg',
    'Dals & Pulses',
    12.9716 + (sin(i * 3) * 0.02),
    77.5946 + (cos(i * 3) * 0.02),
    NOW() - (7 + (i % 7)) * INTERVAL '1 day'
FROM generate_series(1, 60) AS i;
