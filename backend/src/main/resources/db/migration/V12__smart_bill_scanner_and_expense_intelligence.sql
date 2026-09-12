-- V12: Smart Purchased Bill Scanner & Expense Intelligence

-- 1. Create purchased_bills table
CREATE TABLE IF NOT EXISTS purchased_bills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    home_id UUID NOT NULL REFERENCES homes(id) ON DELETE CASCADE,
    store_id UUID REFERENCES stores(id) ON DELETE SET NULL,
    shop_name VARCHAR(150),
    bill_number VARCHAR(100),
    bill_date DATE NOT NULL,
    subtotal NUMERIC(12, 2) DEFAULT 0.00,
    tax_amount NUMERIC(12, 2) DEFAULT 0.00,
    discount_amount NUMERIC(12, 2) DEFAULT 0.00,
    total_amount NUMERIC(12, 2) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'INR',
    idempotency_key VARCHAR(128) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'SCANNED',
    raw_ocr_text TEXT,
    receipt_image_url VARCHAR(512),
    recorded_by UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    confirmed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_purchased_bills_idempotency UNIQUE (home_id, idempotency_key)
);

-- Indexes for efficient querying by home and date
CREATE INDEX IF NOT EXISTS idx_purchased_bills_home_date ON purchased_bills(home_id, bill_date DESC);
CREATE INDEX IF NOT EXISTS idx_purchased_bills_home_status ON purchased_bills(home_id, status);

-- 2. Create purchased_bill_items table
CREATE TABLE IF NOT EXISTS purchased_bill_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_id UUID NOT NULL REFERENCES purchased_bills(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    inventory_item_id UUID REFERENCES inventory_items(id) ON DELETE SET NULL,
    shopping_list_item_id UUID REFERENCES shopping_list_items(id) ON DELETE SET NULL,
    raw_item_name VARCHAR(200) NOT NULL,
    normalized_item_name VARCHAR(200),
    quantity NUMERIC(12, 3) NOT NULL,
    unit VARCHAR(20) NOT NULL DEFAULT 'pcs',
    mrp NUMERIC(10, 2),
    unit_price NUMERIC(10, 2) NOT NULL,
    discount NUMERIC(10, 2) DEFAULT 0.00,
    tax NUMERIC(10, 2) DEFAULT 0.00,
    final_price NUMERIC(12, 2) NOT NULL,
    standard_unit_price NUMERIC(10, 2),
    match_confidence NUMERIC(5, 2) DEFAULT 0.00,
    match_status VARCHAR(30) NOT NULL DEFAULT 'NEW_PRODUCT',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_bill_items_bill_id ON purchased_bill_items(bill_id);
CREATE INDEX IF NOT EXISTS idx_bill_items_product ON purchased_bill_items(product_id);
CREATE INDEX IF NOT EXISTS idx_bill_items_inventory ON purchased_bill_items(inventory_item_id);

-- 3. Create product_price_history table
CREATE TABLE IF NOT EXISTS product_price_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    home_id UUID NOT NULL REFERENCES homes(id) ON DELETE CASCADE,
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    inventory_item_id UUID REFERENCES inventory_items(id) ON DELETE SET NULL,
    store_id UUID REFERENCES stores(id) ON DELETE SET NULL,
    store_name VARCHAR(150),
    purchase_date DATE NOT NULL,
    quantity NUMERIC(12, 3) NOT NULL,
    unit VARCHAR(20) NOT NULL DEFAULT 'pcs',
    unit_price NUMERIC(10, 2) NOT NULL,
    standard_unit_price NUMERIC(10, 2) NOT NULL,
    total_price NUMERIC(12, 2) NOT NULL,
    bill_item_id UUID REFERENCES purchased_bill_items(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_price_history_home_date ON product_price_history(home_id, purchase_date DESC);
CREATE INDEX IF NOT EXISTS idx_price_history_home_product ON product_price_history(home_id, product_id, purchase_date DESC);
CREATE INDEX IF NOT EXISTS idx_price_history_home_item ON product_price_history(home_id, inventory_item_id, purchase_date DESC);

-- 4. Add purchased_quantity and status to shopping_list_items if not already existing
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'shopping_list_items' AND column_name = 'purchased_quantity'
    ) THEN
        ALTER TABLE shopping_list_items ADD COLUMN purchased_quantity NUMERIC(12, 3) DEFAULT 0.000;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'shopping_list_items' AND column_name = 'status'
    ) THEN
        ALTER TABLE shopping_list_items ADD COLUMN status VARCHAR(30) DEFAULT 'PENDING';
    END IF;
END $$;
