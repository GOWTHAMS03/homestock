-- ===================================================================
-- HomeStock Product Catalog & Barcode Scanner Database Schema
-- ===================================================================

-- Canonical Product Catalog (Shared across homes)
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    barcode VARCHAR(50) UNIQUE,
    barcode_type VARCHAR(30) NOT NULL DEFAULT 'EAN_13',
    name VARCHAR(200) NOT NULL,
    normalized_name VARCHAR(200) NOT NULL,
    brand VARCHAR(100),
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    category_name VARCHAR(100),
    package_size NUMERIC(10, 3),
    unit VARCHAR(20) NOT NULL DEFAULT 'pcs',
    image_url VARCHAR(512),
    source VARCHAR(50) NOT NULL DEFAULT 'MANUAL',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);
CREATE INDEX IF NOT EXISTS idx_products_normalized_name ON products(normalized_name);
CREATE INDEX IF NOT EXISTS idx_products_brand ON products(brand);

-- Add barcode and product_id to inventory_items
ALTER TABLE inventory_items 
    ADD COLUMN IF NOT EXISTS barcode VARCHAR(50),
    ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES products(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_inventory_items_barcode ON inventory_items(home_id, barcode);
CREATE INDEX IF NOT EXISTS idx_inventory_items_product ON inventory_items(home_id, product_id);

-- Add barcode to shopping_list_items
ALTER TABLE shopping_list_items
    ADD COLUMN IF NOT EXISTS barcode VARCHAR(50),
    ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES products(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_shopping_items_barcode ON shopping_list_items(shopping_list_id, barcode);
