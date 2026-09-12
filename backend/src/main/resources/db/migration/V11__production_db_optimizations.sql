-- ============================================================================
-- V11: Production Database Optimizations for HomeStock
-- Scale Target: 1,000 to 10,000+ Concurrent Users
--
-- Optimizations included:
-- 1. High-throughput composite and partial indexes based on actual query patterns
-- 2. Foreign key indexes to eliminate sequential scans and lock contention
-- 3. Redundant duplicate index cleanup to reduce write amplification
-- 4. Data integrity CHECK constraints with safe catalog existence guards
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Inventory & Event Ledger Optimizations
-- ----------------------------------------------------------------------------

-- Covering index for household active inventory queries (main grid, sorted by name)
CREATE INDEX IF NOT EXISTS idx_inventory_items_home_active 
    ON inventory_items(home_id, is_archived, name);

-- Covering index for low stock and out of stock dashboard aggregations
CREATE INDEX IF NOT EXISTS idx_inventory_items_home_stock 
    ON inventory_items(home_id, is_archived, quantity);

-- Partial index for active expiring items (compact, ignores nulls and archived)
CREATE INDEX IF NOT EXISTS idx_inventory_items_home_expiry 
    ON inventory_items(home_id, is_archived, expiry_date) 
    WHERE is_archived = false AND expiry_date IS NOT NULL;

-- High-throughput timestamp cursor index for offline delta sync
CREATE INDEX IF NOT EXISTS idx_inventory_items_home_updated 
    ON inventory_items(home_id, updated_at DESC);

-- Foreign key index on category_id for fast filtering and cascade protection
CREATE INDEX IF NOT EXISTS idx_inventory_items_category 
    ON inventory_items(category_id);

-- Stock Transaction History (Inventory Events) - family feed pagination
CREATE INDEX IF NOT EXISTS idx_stock_tx_home_created 
    ON stock_transactions(home_id, created_at DESC);

-- Stock Transaction History - per-item audit trail pagination
CREATE INDEX IF NOT EXISTS idx_stock_tx_item_created 
    ON stock_transactions(item_id, created_at DESC);

-- Stock Transaction History - per-user activity audit
CREATE INDEX IF NOT EXISTS idx_stock_tx_user_created 
    ON stock_transactions(user_id, created_at DESC);


-- ----------------------------------------------------------------------------
-- 2. Shopping List & Item Optimizations
-- ----------------------------------------------------------------------------

-- Household default shopping list lookup
CREATE INDEX IF NOT EXISTS idx_shopping_lists_home_default 
    ON shopping_lists(home_id, is_default);

-- Covering index for shopping list items (ordered: active first, then newest)
CREATE INDEX IF NOT EXISTS idx_shopping_items_list_status 
    ON shopping_list_items(shopping_list_id, is_completed, created_at DESC);

-- Partial index for active item presence check by inventory item id
CREATE INDEX IF NOT EXISTS idx_shopping_items_list_inv 
    ON shopping_list_items(shopping_list_id, inventory_item_id) 
    WHERE is_completed = false;

-- Foreign key indexes for shopping list items
CREATE INDEX IF NOT EXISTS idx_shopping_items_added_by 
    ON shopping_list_items(added_by);

CREATE INDEX IF NOT EXISTS idx_shopping_items_category 
    ON shopping_list_items(category_id);


-- ----------------------------------------------------------------------------
-- 3. Purchases & Expense Analytics Optimizations
-- ----------------------------------------------------------------------------

-- Paged receipt history ordered by purchase date and creation date
CREATE INDEX IF NOT EXISTS idx_purchases_home_date 
    ON purchases(home_id, purchase_date DESC, created_at DESC);

-- Delta sync index for purchases
CREATE INDEX IF NOT EXISTS idx_purchases_home_updated 
    ON purchases(home_id, updated_at DESC);

-- Foreign key indexes on purchases
CREATE INDEX IF NOT EXISTS idx_purchases_recorded_by 
    ON purchases(recorded_by);

CREATE INDEX IF NOT EXISTS idx_purchases_store 
    ON purchases(store_id);

-- Purchase Items foreign keys and consumption engine analysis
CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase 
    ON purchase_items(purchase_id);

CREATE INDEX IF NOT EXISTS idx_purchase_items_inventory 
    ON purchase_items(inventory_item_id);

CREATE INDEX IF NOT EXISTS idx_purchase_items_category 
    ON purchase_items(category_id);


-- ----------------------------------------------------------------------------
-- 4. Sync Sequence, Cursor & Idempotency Optimizations
-- ----------------------------------------------------------------------------

-- Home Change Log creation timeline & retention purge index
CREATE INDEX IF NOT EXISTS idx_change_log_home_created 
    ON home_change_log(home_id, created_at DESC);

-- Processed Operations cleanup and audit index
CREATE INDEX IF NOT EXISTS idx_processed_op_home_processed 
    ON processed_operations(home_id, processed_at DESC);


-- ----------------------------------------------------------------------------
-- 5. Notifications & Real-Time Deals Optimizations
-- ----------------------------------------------------------------------------

-- Partial index for 90-day retention cleanup of read notifications
CREATE INDEX IF NOT EXISTS idx_notifications_read_created 
    ON notifications(is_read, created_at) 
    WHERE is_read = true;

-- Foreign key index on home_id for notifications
CREATE INDEX IF NOT EXISTS idx_notifications_home 
    ON notifications(home_id);

-- Best deal lookup for valid/price-changed deals by canonical product
CREATE INDEX IF NOT EXISTS idx_deals_canonical_lookup 
    ON deals(canonical_product_id, expires_at, final_price) 
    WHERE validation_status IN ('VALID', 'PRICE_CHANGED');

-- Best deal lookup for valid/price-changed deals by product id
CREATE INDEX IF NOT EXISTS idx_deals_product_lookup 
    ON deals(product_id, expires_at, final_price) 
    WHERE validation_status IN ('VALID', 'PRICE_CHANGED');

-- Fast standalone lookup on product identifiers (GTIN, ASIN, SKU)
CREATE INDEX IF NOT EXISTS idx_pi_value 
    ON product_identifiers(identifier_value);

-- Foreign key index on stores
CREATE INDEX IF NOT EXISTS idx_stores_home 
    ON stores(home_id);

-- Foreign key index on refresh tokens for fast user logout session invalidation
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user 
    ON refresh_tokens(user_id);


-- ----------------------------------------------------------------------------
-- 6. Redundant Index Cleanup (Eliminates Write Amplification)
-- ----------------------------------------------------------------------------

-- Drop redundant single-column index on room_members (already covered by uq_room_member(room_id, user_id))
DROP INDEX IF EXISTS idx_room_members_room_id;


-- ----------------------------------------------------------------------------
-- 7. Data Integrity CHECK Constraints
-- ----------------------------------------------------------------------------

DO $$
BEGIN
    -- Inventory items quantity constraints
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_inventory_quantity_non_neg') THEN
        ALTER TABLE inventory_items ADD CONSTRAINT chk_inventory_quantity_non_neg CHECK (quantity >= 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_inventory_min_qty_non_neg') THEN
        ALTER TABLE inventory_items ADD CONSTRAINT chk_inventory_min_qty_non_neg CHECK (minimum_quantity >= 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_inventory_purchase_price_non_neg') THEN
        ALTER TABLE inventory_items ADD CONSTRAINT chk_inventory_purchase_price_non_neg CHECK (purchase_price IS NULL OR purchase_price >= 0);
    END IF;

    -- Purchases amount constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_purchases_total_non_neg') THEN
        ALTER TABLE purchases ADD CONSTRAINT chk_purchases_total_non_neg CHECK (total_amount >= 0);
    END IF;

    -- Purchase items constraints
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_purchase_items_qty_pos') THEN
        ALTER TABLE purchase_items ADD CONSTRAINT chk_purchase_items_qty_pos CHECK (quantity > 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_purchase_items_unit_price_non_neg') THEN
        ALTER TABLE purchase_items ADD CONSTRAINT chk_purchase_items_unit_price_non_neg CHECK (unit_price >= 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_purchase_items_total_price_non_neg') THEN
        ALTER TABLE purchase_items ADD CONSTRAINT chk_purchase_items_total_price_non_neg CHECK (total_price >= 0);
    END IF;

    -- Shopping list items constraint
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_shopping_items_qty_pos') THEN
        ALTER TABLE shopping_list_items ADD CONSTRAINT chk_shopping_items_qty_pos CHECK (quantity > 0);
    END IF;

    -- Stock transactions constraints
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_stock_tx_qty_change_non_neg') THEN
        ALTER TABLE stock_transactions ADD CONSTRAINT chk_stock_tx_qty_change_non_neg CHECK (quantity_change >= 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_stock_tx_new_qty_non_neg') THEN
        ALTER TABLE stock_transactions ADD CONSTRAINT chk_stock_tx_new_qty_non_neg CHECK (new_quantity >= 0);
    END IF;

    -- Deals pricing constraints
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_deals_final_price_non_neg') THEN
        ALTER TABLE deals ADD CONSTRAINT chk_deals_final_price_non_neg CHECK (final_price >= 0);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_deals_price_non_neg') THEN
        ALTER TABLE deals ADD CONSTRAINT chk_deals_price_non_neg CHECK (price >= 0);
    END IF;
END $$;
