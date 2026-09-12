-- ===================================================================
-- HomeStock Real-Time Best Deal & Product Validation Engine (V9)
-- ===================================================================

-- 1. Real-Time Validated Deals
CREATE TABLE IF NOT EXISTS deals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    canonical_product_id VARCHAR(200),
    source VARCHAR(50) NOT NULL,
    external_product_id VARCHAR(200) NOT NULL,
    product_name VARCHAR(300) NOT NULL,
    brand VARCHAR(150),
    variant VARCHAR(100),
    quantity NUMERIC(12, 3),
    unit VARCHAR(30),
    pack_count INTEGER NOT NULL DEFAULT 1,
    price NUMERIC(12, 2) NOT NULL,
    delivery_charge NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    discount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    coupon_discount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    final_price NUMERIC(12, 2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    stock_status VARCHAR(50) NOT NULL DEFAULT 'IN_STOCK',
    delivery_status VARCHAR(100),
    seller_name VARCHAR(150),
    product_url VARCHAR(1000) NOT NULL,
    affiliate_url VARCHAR(1000),
    image_url VARCHAR(500),
    match_score NUMERIC(5, 4) NOT NULL DEFAULT 1.0000,
    confidence_score NUMERIC(5, 2) NOT NULL DEFAULT 100.00,
    validation_status VARCHAR(50) NOT NULL DEFAULT 'VALID',
    last_verified_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_deal_source_external UNIQUE (source, external_product_id)
);

CREATE INDEX IF NOT EXISTS idx_deals_product_id ON deals(product_id);
CREATE INDEX IF NOT EXISTS idx_deals_source_ext ON deals(source, external_product_id);
CREATE INDEX IF NOT EXISTS idx_deals_validation_status ON deals(validation_status);
CREATE INDEX IF NOT EXISTS idx_deals_last_verified ON deals(last_verified_at);
CREATE INDEX IF NOT EXISTS idx_deals_final_price ON deals(final_price);
CREATE INDEX IF NOT EXISTS idx_deals_canonical_id ON deals(canonical_product_id);

-- 2. Deal Price Change History
CREATE TABLE IF NOT EXISTS deal_price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deal_id UUID REFERENCES deals(id) ON DELETE CASCADE,
    old_price NUMERIC(12, 2) NOT NULL,
    new_price NUMERIC(12, 2) NOT NULL,
    source VARCHAR(50) NOT NULL,
    detected_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    reason VARCHAR(200),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dph_deal_id ON deal_price_history(deal_id);
CREATE INDEX IF NOT EXISTS idx_dph_detected_at ON deal_price_history(detected_at);
