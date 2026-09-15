-- ===================================================================
-- V18: Shop Owner Ecosystem — Owned Shops, Verification, Catalog,
--      Deals, Subscriptions, and Demand Analytics
-- ===================================================================

-- 1. Add app-level role to users (orthogonal to HomeRole)
ALTER TABLE users ADD COLUMN IF NOT EXISTS app_role VARCHAR(20) NOT NULL DEFAULT 'USER';
CREATE INDEX IF NOT EXISTS idx_users_app_role ON users(app_role);

-- 2. Extend nearby_shops with Shop Owner fields
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS verification_status VARCHAR(20) NOT NULL DEFAULT 'VERIFIED';
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS owner_name VARCHAR(120);
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS whatsapp_number VARCHAR(30);
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS gst_number VARCHAR(30);
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS shop_image_url VARCHAR(512);
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS opening_time TIME;
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS closing_time TIME;
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS last_inventory_update TIMESTAMP WITH TIME ZONE;
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS email VARCHAR(180);
ALTER TABLE nearby_shops ADD COLUMN IF NOT EXISTS product_count INTEGER NOT NULL DEFAULT 0;

-- Backfill existing OSM/seed shops as VERIFIED (they were already visible)
UPDATE nearby_shops SET verification_status = 'VERIFIED' WHERE owner_id IS NULL;

CREATE INDEX IF NOT EXISTS idx_ns_owner_id ON nearby_shops(owner_id);
CREATE INDEX IF NOT EXISTS idx_ns_verification_status ON nearby_shops(verification_status);

-- 3. Extend shop_product_offers with availability and deal fields
ALTER TABLE shop_product_offers ADD COLUMN IF NOT EXISTS offer_price NUMERIC(12, 2);
ALTER TABLE shop_product_offers ADD COLUMN IF NOT EXISTS offer_start TIMESTAMP WITH TIME ZONE;
ALTER TABLE shop_product_offers ADD COLUMN IF NOT EXISTS offer_end TIMESTAMP WITH TIME ZONE;
ALTER TABLE shop_product_offers ADD COLUMN IF NOT EXISTS stock_quantity NUMERIC(10, 3);
ALTER TABLE shop_product_offers ADD COLUMN IF NOT EXISTS stock_visibility VARCHAR(20) NOT NULL DEFAULT 'STATUS_ONLY';
ALTER TABLE shop_product_offers ADD COLUMN IF NOT EXISTS availability_status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE';

CREATE INDEX IF NOT EXISTS idx_spo_availability ON shop_product_offers(availability_status);
CREATE INDEX IF NOT EXISTS idx_spo_shop_avail ON shop_product_offers(shop_id, availability_status);

-- 4. Shop Product Price History (audit trail)
CREATE TABLE IF NOT EXISTS shop_product_price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_product_id UUID NOT NULL REFERENCES shop_product_offers(id) ON DELETE CASCADE,
    old_price NUMERIC(12, 2) NOT NULL,
    new_price NUMERIC(12, 2) NOT NULL,
    old_offer_price NUMERIC(12, 2),
    new_offer_price NUMERIC(12, 2),
    changed_by UUID REFERENCES users(id) ON DELETE SET NULL,
    reason VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_spph_shop_product ON shop_product_price_history(shop_product_id);
CREATE INDEX IF NOT EXISTS idx_spph_created_at ON shop_product_price_history(created_at);

-- 5. Shop Deals (simple owner-created deals)
CREATE TABLE IF NOT EXISTS shop_deals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES nearby_shops(id) ON DELETE CASCADE,
    shop_product_id UUID REFERENCES shop_product_offers(id) ON DELETE SET NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    deal_type VARCHAR(30) NOT NULL DEFAULT 'DISCOUNT',
    original_price NUMERIC(12, 2),
    offer_price NUMERIC(12, 2),
    discount_percent NUMERIC(5, 2),
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sd_shop ON shop_deals(shop_id);
CREATE INDEX IF NOT EXISTS idx_sd_active ON shop_deals(is_active, end_date);
CREATE INDEX IF NOT EXISTS idx_sd_dates ON shop_deals(start_date, end_date);

-- 6. Shop Search Events (anonymous, aggregated demand intelligence)
CREATE TABLE IF NOT EXISTS shop_search_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    search_query VARCHAR(200) NOT NULL,
    normalized_query VARCHAR(200) NOT NULL,
    latitude NUMERIC(10, 7),
    longitude NUMERIC(10, 7),
    result_count INTEGER NOT NULL DEFAULT 0,
    searched_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sse_normalized ON shop_search_events(normalized_query);
CREATE INDEX IF NOT EXISTS idx_sse_searched_at ON shop_search_events(searched_at);
CREATE INDEX IF NOT EXISTS idx_sse_coords ON shop_search_events(latitude, longitude);

-- 7. Shop Product Views (anonymous view tracking)
CREATE TABLE IF NOT EXISTS shop_product_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES nearby_shops(id) ON DELETE CASCADE,
    shop_product_id UUID REFERENCES shop_product_offers(id) ON DELETE SET NULL,
    viewed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_spv_shop ON shop_product_views(shop_id);
CREATE INDEX IF NOT EXISTS idx_spv_viewed_at ON shop_product_views(viewed_at);
CREATE INDEX IF NOT EXISTS idx_spv_product ON shop_product_views(shop_product_id);

-- 8. Subscription Plans
CREATE TABLE IF NOT EXISTS subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(30) NOT NULL UNIQUE,
    display_name VARCHAR(60) NOT NULL,
    description TEXT,
    max_products INTEGER NOT NULL DEFAULT 50,
    analytics_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    featured_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    price_monthly NUMERIC(10, 2) NOT NULL DEFAULT 0,
    price_yearly NUMERIC(10, 2) NOT NULL DEFAULT 0,
    currency VARCHAR(3) NOT NULL DEFAULT 'INR',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Seed default plans
INSERT INTO subscription_plans (id, name, display_name, description, max_products, analytics_enabled, featured_enabled, price_monthly, price_yearly, sort_order)
VALUES
    ('c0000000-0000-0000-0000-000000000001', 'FREE', 'Free', 'Get started with up to 50 products', 50, FALSE, FALSE, 0, 0, 0),
    ('c0000000-0000-0000-0000-000000000002', 'STARTER', 'Starter', 'Grow your shop with up to 500 products', 500, FALSE, FALSE, 199, 1990, 1),
    ('c0000000-0000-0000-0000-000000000003', 'BUSINESS', 'Business', 'Unlimited products with basic analytics', 999999, TRUE, FALSE, 499, 4990, 2),
    ('c0000000-0000-0000-0000-000000000004', 'PREMIUM', 'Premium', 'Full analytics, featured listings, and priority support', 999999, TRUE, TRUE, 999, 9990, 3)
ON CONFLICT (name) DO NOTHING;

-- 9. Shop Subscriptions
CREATE TABLE IF NOT EXISTS shop_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES nearby_shops(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES subscription_plans(id),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    payment_provider VARCHAR(30),
    payment_reference VARCHAR(200),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_ss_shop_active ON shop_subscriptions(shop_id) WHERE status IN ('ACTIVE', 'TRIAL');
CREATE INDEX IF NOT EXISTS idx_ss_status ON shop_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_ss_expires ON shop_subscriptions(expires_at);
