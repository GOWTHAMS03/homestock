-- Rollback V12
DROP TABLE IF EXISTS product_price_history CASCADE;
DROP TABLE IF EXISTS purchased_bill_items CASCADE;
DROP TABLE IF EXISTS purchased_bills CASCADE;

ALTER TABLE shopping_list_items DROP COLUMN IF EXISTS purchased_quantity;
ALTER TABLE shopping_list_items DROP COLUMN IF EXISTS status;
