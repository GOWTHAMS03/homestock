-- ===================================================================
-- HomeStock Smart Shopping & Price Comparison Database Schema
-- ===================================================================

-- Shopping Providers
CREATE TABLE IF NOT EXISTS shopping_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    logo_url VARCHAR(500),
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    provider_type VARCHAR(20) NOT NULL DEFAULT 'ONLINE',
    config_json TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sp_name ON shopping_providers(name);
CREATE INDEX IF NOT EXISTS idx_sp_enabled ON shopping_providers(is_enabled);

-- Product Offers (Cache)
CREATE TABLE IF NOT EXISTS product_offers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider VARCHAR(50) NOT NULL,
    provider_product_id VARCHAR(200) NOT NULL,
    canonical_product_id VARCHAR(200),
    product_name VARCHAR(300) NOT NULL,
    brand VARCHAR(150),
    description TEXT,
    package_size VARCHAR(50),
    unit VARCHAR(30),
    product_url VARCHAR(1000),
    affiliate_url VARCHAR(1000),
    image_url VARCHAR(500),
    price NUMERIC(12, 2),
    delivery_charge NUMERIC(12, 2),
    effective_price NUMERIC(12, 2),
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    availability VARCHAR(50),
    estimated_delivery VARCHAR(100),
    rating NUMERIC(3, 2),
    review_count INTEGER,
    match_confidence NUMERIC(5, 4),
    match_type VARCHAR(30),
    price_per_unit NUMERIC(12, 4),
    price_per_unit_label VARCHAR(50),
    last_checked_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_po_provider_product ON product_offers(provider, provider_product_id);
CREATE INDEX IF NOT EXISTS idx_po_canonical ON product_offers(canonical_product_id);
CREATE INDEX IF NOT EXISTS idx_po_last_checked ON product_offers(last_checked_at);

-- Affiliate Clicks (Analytics & Attribution)
CREATE TABLE IF NOT EXISTS affiliate_clicks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    home_id UUID NOT NULL,
    shopping_item_id UUID,
    provider VARCHAR(50) NOT NULL,
    provider_product_id VARCHAR(200) NOT NULL,
    clicked_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ac_home_user ON affiliate_clicks(home_id, user_id);
CREATE INDEX IF NOT EXISTS idx_ac_provider ON affiliate_clicks(provider);
CREATE INDEX IF NOT EXISTS idx_ac_clicked_at ON affiliate_clicks(clicked_at);

-- Price History
CREATE TABLE IF NOT EXISTS price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider VARCHAR(50) NOT NULL,
    provider_product_id VARCHAR(200) NOT NULL,
    price NUMERIC(12, 2) NOT NULL,
    delivery_charge NUMERIC(12, 2),
    effective_price NUMERIC(12, 2) NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ph_provider_product ON price_history(provider, provider_product_id);
CREATE INDEX IF NOT EXISTS idx_ph_recorded_at ON price_history(recorded_at);
