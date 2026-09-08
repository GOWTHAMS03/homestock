-- ===================================================================
-- HomeStock Smart Shopping & Multi-Provider Price Comparison Engine (V5)
-- ===================================================================

-- 1. Enrich Canonical Products catalog
ALTER TABLE products
    ADD COLUMN IF NOT EXISTS sub_category VARCHAR(100),
    ADD COLUMN IF NOT EXISTS gtin VARCHAR(50),
    ADD COLUMN IF NOT EXISTS variant VARCHAR(100),
    ADD COLUMN IF NOT EXISTS description TEXT,
    ADD COLUMN IF NOT EXISTS package_unit VARCHAR(30);

CREATE INDEX IF NOT EXISTS idx_products_gtin ON products(gtin);
CREATE INDEX IF NOT EXISTS idx_products_variant ON products(variant);

-- 2. Product Identifiers (GTIN, ASIN, FSN, Barcodes, SKU)
CREATE TABLE IF NOT EXISTS product_identifiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    identifier_type VARCHAR(30) NOT NULL,
    identifier_value VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pi_type_val ON product_identifiers(identifier_type, identifier_value);
CREATE INDEX IF NOT EXISTS idx_pi_product_id ON product_identifiers(product_id);

-- 3. Product Aliases & Brand Synonyms
CREATE TABLE IF NOT EXISTS product_aliases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    alias_name VARCHAR(200) NOT NULL,
    confidence NUMERIC(3, 2) NOT NULL DEFAULT 1.0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pa_alias_name ON product_aliases(alias_name);
CREATE INDEX IF NOT EXISTS idx_pa_product_id ON product_aliases(product_id);

-- 4. Provider Capabilities Declaration
CREATE TABLE IF NOT EXISTS provider_capabilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_name VARCHAR(50) NOT NULL,
    capability VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_provider_capability UNIQUE (provider_name, capability)
);

CREATE INDEX IF NOT EXISTS idx_pc_provider ON provider_capabilities(provider_name);

-- 5. Provider Products Mapping
CREATE TABLE IF NOT EXISTS provider_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_name VARCHAR(50) NOT NULL,
    provider_product_id VARCHAR(200) NOT NULL,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    title VARCHAR(300) NOT NULL,
    brand VARCHAR(150),
    variant VARCHAR(100),
    package_size VARCHAR(50),
    unit VARCHAR(30),
    url VARCHAR(1000),
    image_url VARCHAR(500),
    last_synced_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_provider_product UNIQUE (provider_name, provider_product_id)
);

CREATE INDEX IF NOT EXISTS idx_pp_provider_product ON provider_products(provider_name, provider_product_id);
CREATE INDEX IF NOT EXISTS idx_pp_canonical_product ON provider_products(product_id);

-- 6. Shopping Sessions (Tracking User Decision & Basket Lifecycle)
CREATE TABLE IF NOT EXISTS shopping_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    home_id UUID NOT NULL REFERENCES homes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(30) NOT NULL DEFAULT 'CREATED',
    selected_providers VARCHAR(200),
    estimated_total NUMERIC(12, 2),
    actual_total NUMERIC(12, 2),
    potential_savings NUMERIC(12, 2),
    recommended_option VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ss_home_user ON shopping_sessions(home_id, user_id);
CREATE INDEX IF NOT EXISTS idx_ss_status ON shopping_sessions(status);
CREATE INDEX IF NOT EXISTS idx_ss_started_at ON shopping_sessions(started_at);

-- 7. Shopping Session Items
CREATE TABLE IF NOT EXISTS shopping_session_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES shopping_sessions(id) ON DELETE CASCADE,
    shopping_list_item_id UUID REFERENCES shopping_list_items(id) ON DELETE SET NULL,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    item_name VARCHAR(200) NOT NULL,
    selected_provider VARCHAR(50),
    provider_product_id VARCHAR(200),
    quantity NUMERIC(12, 3) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    estimated_unit_price NUMERIC(12, 2),
    estimated_total_price NUMERIC(12, 2),
    actual_price NUMERIC(12, 2),
    is_purchased BOOLEAN NOT NULL DEFAULT FALSE,
    match_score NUMERIC(5, 4),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ssi_session ON shopping_session_items(session_id);

-- 8. Enrich Shopping List Items with User Preferences
ALTER TABLE shopping_list_items
    ADD COLUMN IF NOT EXISTS preferred_brand VARCHAR(100),
    ADD COLUMN IF NOT EXISTS preferred_package_size VARCHAR(50),
    ADD COLUMN IF NOT EXISTS preferred_provider VARCHAR(50),
    ADD COLUMN IF NOT EXISTS normalized_product_id UUID REFERENCES products(id) ON DELETE SET NULL;

-- 9. Enrich Price History for Multi-Provider & Local Reporting
ALTER TABLE price_history
    ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS unit_price NUMERIC(12, 4),
    ADD COLUMN IF NOT EXISTS availability VARCHAR(50),
    ADD COLUMN IF NOT EXISTS is_user_reported BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS reported_by UUID REFERENCES users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS store_name VARCHAR(150);

CREATE INDEX IF NOT EXISTS idx_ph_product_id ON price_history(product_id);
CREATE INDEX IF NOT EXISTS idx_ph_user_reported ON price_history(is_user_reported);

-- 10. Enrich Affiliate Clicks
ALTER TABLE affiliate_clicks
    ADD COLUMN IF NOT EXISTS session_id UUID REFERENCES shopping_sessions(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS source_screen VARCHAR(50);
