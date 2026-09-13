-- ============================================================================
-- U11: Rollback Script for V11 Production Optimizations
-- Use this script if rolling back V11 changes.
-- ============================================================================

-- 1. Drop Added Constraints
ALTER TABLE inventory_items DROP CONSTRAINT IF EXISTS chk_inventory_quantity_non_neg;
ALTER TABLE inventory_items DROP CONSTRAINT IF EXISTS chk_inventory_min_qty_non_neg;
ALTER TABLE inventory_items DROP CONSTRAINT IF EXISTS chk_inventory_purchase_price_non_neg;
ALTER TABLE purchases DROP CONSTRAINT IF EXISTS chk_purchases_total_non_neg;
ALTER TABLE purchase_items DROP CONSTRAINT IF EXISTS chk_purchase_items_qty_pos;
ALTER TABLE purchase_items DROP CONSTRAINT IF EXISTS chk_purchase_items_unit_price_non_neg;
ALTER TABLE purchase_items DROP CONSTRAINT IF EXISTS chk_purchase_items_total_price_non_neg;
ALTER TABLE shopping_list_items DROP CONSTRAINT IF EXISTS chk_shopping_items_qty_pos;
ALTER TABLE stock_transactions DROP CONSTRAINT IF EXISTS chk_stock_tx_qty_change_non_neg;
ALTER TABLE stock_transactions DROP CONSTRAINT IF EXISTS chk_stock_tx_new_qty_non_neg;
ALTER TABLE deals DROP CONSTRAINT IF EXISTS chk_deals_final_price_non_neg;
ALTER TABLE deals DROP CONSTRAINT IF EXISTS chk_deals_price_non_neg;

-- 2. Drop Added Indexes
DROP INDEX IF EXISTS idx_inventory_items_home_active;
DROP INDEX IF EXISTS idx_inventory_items_home_stock;
DROP INDEX IF EXISTS idx_inventory_items_home_expiry;
DROP INDEX IF EXISTS idx_inventory_items_home_updated;
DROP INDEX IF EXISTS idx_inventory_items_category;

DROP INDEX IF EXISTS idx_stock_tx_home_created;
DROP INDEX IF EXISTS idx_stock_tx_item_created;
DROP INDEX IF EXISTS idx_stock_tx_user_created;

DROP INDEX IF EXISTS idx_shopping_lists_home_default;
DROP INDEX IF EXISTS idx_shopping_items_list_status;
DROP INDEX IF EXISTS idx_shopping_items_list_inv;
DROP INDEX IF EXISTS idx_shopping_items_added_by;
DROP INDEX IF EXISTS idx_shopping_items_category;

DROP INDEX IF EXISTS idx_purchases_home_date;
DROP INDEX IF EXISTS idx_purchases_home_updated;
DROP INDEX IF EXISTS idx_purchases_recorded_by;
DROP INDEX IF EXISTS idx_purchases_store;

DROP INDEX IF EXISTS idx_purchase_items_purchase;
DROP INDEX IF EXISTS idx_purchase_items_inventory;
DROP INDEX IF EXISTS idx_purchase_items_category;

DROP INDEX IF EXISTS idx_change_log_home_created;
DROP INDEX IF EXISTS idx_processed_op_home_processed;

DROP INDEX IF EXISTS idx_notifications_read_created;
DROP INDEX IF EXISTS idx_notifications_home;
DROP INDEX IF EXISTS idx_deals_canonical_lookup;
DROP INDEX IF EXISTS idx_deals_product_lookup;
DROP INDEX IF EXISTS idx_pi_value;
DROP INDEX IF EXISTS idx_stores_home;
DROP INDEX IF EXISTS idx_refresh_tokens_user;

-- 3. Recreate Dropped Indexes (if necessary for legacy compatibility)
CREATE INDEX IF NOT EXISTS idx_room_members_room_id ON room_members(room_id);
