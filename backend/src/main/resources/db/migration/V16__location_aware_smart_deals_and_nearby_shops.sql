-- ===================================================================
-- V16: Location-Aware Smart Deals & Nearby Shop Intelligence
-- ===================================================================

-- 1. Nearby Physical Shops (Supermarkets, Provision Stores, Hypermarkets, etc.)
CREATE TABLE IF NOT EXISTS nearby_shops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(150) NOT NULL,
    shop_type VARCHAR(50) NOT NULL DEFAULT 'SUPERMARKET', -- SUPERMARKET, GROCERY, HYPERMARKET, PROVISION, WHOLESALE, DEPARTMENT
    address VARCHAR(300),
    area VARCHAR(100),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) DEFAULT 'Tamil Nadu',
    postal_code VARCHAR(20),
    latitude NUMERIC(10, 7) NOT NULL,
    longitude NUMERIC(10, 7) NOT NULL,
    geohash VARCHAR(12),
    phone VARCHAR(30),
    rating NUMERIC(3, 2) DEFAULT 4.2,
    review_count INTEGER DEFAULT 0,
    opening_hours VARCHAR(100) DEFAULT '8:00 AM - 10:00 PM',
    is_open BOOLEAN NOT NULL DEFAULT TRUE,
    is_verified BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ns_coords ON nearby_shops(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_ns_city ON nearby_shops(city);
CREATE INDEX IF NOT EXISTS idx_ns_postal_code ON nearby_shops(postal_code);
CREATE INDEX IF NOT EXISTS idx_ns_shop_type ON nearby_shops(shop_type);

-- 2. Shop-Specific Product Offers (Local Physical Store Inventory & Prices)
CREATE TABLE IF NOT EXISTS shop_product_offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES nearby_shops(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    raw_product_name VARCHAR(255) NOT NULL,
    normalized_name VARCHAR(255) NOT NULL,
    brand VARCHAR(100),
    package_size NUMERIC(10, 3),
    unit VARCHAR(30),
    price NUMERIC(12, 2) NOT NULL,
    mrp NUMERIC(12, 2),
    effective_price NUMERIC(12, 2) NOT NULL,
    price_per_unit NUMERIC(12, 4),
    price_per_unit_label VARCHAR(50),
    stock_status VARCHAR(50) NOT NULL DEFAULT 'IN_STOCK', -- IN_STOCK, LOW_STOCK, OUT_OF_STOCK, UNCONFIRMED
    source VARCHAR(50) NOT NULL DEFAULT 'SHOP_CATALOG', -- SHOP_CATALOG, USER_REPORTED, BILL_HISTORY, PARTNER_FEED
    confidence VARCHAR(20) NOT NULL DEFAULT 'HIGH', -- HIGH, MEDIUM, LOW
    last_verified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_spo_shop_id ON shop_product_offers(shop_id);
CREATE INDEX IF NOT EXISTS idx_spo_product_id ON shop_product_offers(product_id);
CREATE INDEX IF NOT EXISTS idx_spo_normalized_name ON shop_product_offers(normalized_name);
CREATE INDEX IF NOT EXISTS idx_spo_last_verified ON shop_product_offers(last_verified_at);

-- 3. User Location Preferences (Private, User-Isolated, Never Shared)
CREATE TABLE IF NOT EXISTS user_location_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    latitude NUMERIC(10, 7),
    longitude NUMERIC(10, 7),
    approximate_area VARCHAR(150),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    geohash VARCHAR(12),
    is_manual BOOLEAN NOT NULL DEFAULT FALSE,
    preferred_radius_km NUMERIC(5, 2) NOT NULL DEFAULT 5.0,
    include_travel_cost BOOLEAN NOT NULL DEFAULT FALSE,
    travel_cost_per_km NUMERIC(6, 2) NOT NULL DEFAULT 10.0,
    sort_preference VARCHAR(50) NOT NULL DEFAULT 'BEST_VALUE', -- CHEAPEST, NEAREST, BEST_VALUE, ONE_STORE, MAX_SAVING
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ulp_user_id ON user_location_preferences(user_id);

-- 4. Deal Click & Attribution Analytics
CREATE TABLE IF NOT EXISTS deal_click_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    deal_id UUID,
    shop_id UUID REFERENCES nearby_shops(id) ON DELETE SET NULL,
    provider VARCHAR(50) NOT NULL,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    external_url VARCHAR(1000),
    clicked_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dce_user ON deal_click_events(user_id);
CREATE INDEX IF NOT EXISTS idx_dce_provider ON deal_click_events(provider);
CREATE INDEX IF NOT EXISTS idx_dce_clicked_at ON deal_click_events(clicked_at);

-- 5. Product Match Feedback (Continuous Machine Learning / Rule Tuning)
CREATE TABLE IF NOT EXISTS product_match_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    candidate_title VARCHAR(300) NOT NULL,
    is_correct_match BOOLEAN NOT NULL,
    feedback_note TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 6. Initial Seed Data: Realistic Local Grocery Shops in Mettur / Salem / Chennai
INSERT INTO nearby_shops (id, name, shop_type, address, area, city, postal_code, latitude, longitude, geohash, phone, rating, review_count, opening_hours, is_open, is_verified)
VALUES
    ('a0000000-0000-0000-0000-000000000001', 'Local Supermarket', 'SUPERMARKET', '14 Bazaar Street, Near Bus Stand', 'Mettur Dam', 'Mettur', '636401', 11.7968, 77.8013, 'tdpxh1', '+91 94431 23456', 4.6, 215, '7:30 AM - 10:00 PM', TRUE, TRUE),
    ('a0000000-0000-0000-0000-000000000002', 'Sri Grocery & Provision Store', 'PROVISION', '42 Main Road, RS Market', 'Mettur RS', 'Mettur', '636402', 11.7925, 77.8095, 'tdpxh4', '+91 98427 65432', 4.4, 98, '8:00 AM - 9:30 PM', TRUE, TRUE),
    ('a0000000-0000-0000-0000-000000000003', 'Reliance Smart Point', 'SUPERMARKET', 'Opposite Municipal Office, Thoppur Road', 'Mettur', 'Mettur', '636401', 11.8021, 77.7954, 'tdpxh3', '+91 80000 12345', 4.3, 340, '7:00 AM - 10:00 PM', TRUE, TRUE),
    ('a0000000-0000-0000-0000-000000000004', 'Kannan Departmental Store', 'DEPARTMENT', 'Omalur Main Road, Fairlands', 'Fairlands', 'Salem', '636016', 11.6643, 78.1460, 'tdpwn5', '+91 97890 11223', 4.5, 520, '8:00 AM - 10:30 PM', TRUE, TRUE),
    ('a0000000-0000-0000-0000-000000000005', 'Sri Murugan Wholesale Provision', 'WHOLESALE', 'Shevapet Market Lane', 'Shevapet', 'Salem', '636002', 11.6521, 78.1388, 'tdpwn1', '+91 94432 99887', 4.7, 410, '6:30 AM - 9:00 PM', TRUE, TRUE)
ON CONFLICT (id) DO NOTHING;

-- Seed verified staple prices for Local Supermarket and Sri Grocery Store
INSERT INTO shop_product_offers (id, shop_id, raw_product_name, normalized_name, brand, package_size, unit, price, mrp, effective_price, price_per_unit, price_per_unit_label, stock_status, source, confidence, last_verified_at)
VALUES
    -- Local Supermarket (Mettur)
    ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'Ponni Raw Rice 5 KG', 'Ponni Rice', 'Local Premium', 5.0, 'KG', 275.00, 310.00, 275.00, 55.0000, '₹55.00 / KG', 'IN_STOCK', 'SHOP_CATALOG', 'HIGH', NOW() - INTERVAL '30 minutes'),
    ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Refined White Sugar 5 KG', 'Sugar', 'Madhur', 5.0, 'KG', 225.00, 250.00, 225.00, 45.0000, '₹45.00 / KG', 'IN_STOCK', 'SHOP_CATALOG', 'HIGH', NOW() - INTERVAL '1 hour'),
    ('b0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'Gold Winner Sunflower Oil 2 L', 'Sunflower Oil', 'Gold Winner', 2.0, 'L', 270.00, 300.00, 270.00, 135.0000, '₹135.00 / L', 'IN_STOCK', 'SHOP_CATALOG', 'HIGH', NOW() - INTERVAL '45 minutes'),
    ('b0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'Tata Sampann Toor Dal 1 KG', 'Toor Dal', 'Tata Sampann', 1.0, 'KG', 158.00, 185.00, 158.00, 158.0000, '₹158.00 / KG', 'IN_STOCK', 'SHOP_CATALOG', 'HIGH', NOW() - INTERVAL '2 hours'),
    ('b0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000001', 'Aashirvaad Superior MP Atta 5 KG', 'Atta', 'Aashirvaad', 5.0, 'KG', 265.00, 295.00, 265.00, 53.0000, '₹53.00 / KG', 'IN_STOCK', 'SHOP_CATALOG', 'HIGH', NOW() - INTERVAL '3 hours'),

    -- Sri Grocery Store (Mettur RS)
    ('b0000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000002', 'Deluxe Ponni Rice 5 KG', 'Ponni Rice', 'Sri Brand', 5.0, 'KG', 280.00, 300.00, 280.00, 56.0000, '₹56.00 / KG', 'IN_STOCK', 'USER_REPORTED', 'MEDIUM', NOW() - INTERVAL '4 hours'),
    ('b0000000-0000-0000-0000-000000000007', 'a0000000-0000-0000-0000-000000000002', 'Pure Crystal Sugar 5 KG', 'Sugar', 'Local Mill', 5.0, 'KG', 220.00, 240.00, 220.00, 44.0000, '₹44.00 / KG', 'IN_STOCK', 'USER_REPORTED', 'HIGH', NOW() - INTERVAL '5 hours'),
    ('b0000000-0000-0000-0000-000000000008', 'a0000000-0000-0000-0000-000000000002', 'Fortune Sunlite Sunflower Oil 2 L', 'Sunflower Oil', 'Fortune', 2.0, 'L', 268.00, 290.00, 268.00, 134.0000, '₹134.00 / L', 'IN_STOCK', 'SHOP_CATALOG', 'HIGH', NOW() - INTERVAL '2 hours'),
    ('b0000000-0000-0000-0000-000000000009', 'a0000000-0000-0000-0000-000000000002', 'Unpolished Toor Dal 1 KG', 'Toor Dal', 'Sri Special', 1.0, 'KG', 152.00, 175.00, 152.00, 152.0000, '₹152.00 / KG', 'IN_STOCK', 'USER_REPORTED', 'HIGH', NOW() - INTERVAL '6 hours')
ON CONFLICT (id) DO NOTHING;
