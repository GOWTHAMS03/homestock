-- V13: AI Bill Pipeline Upgrade — Multi-Stage Extraction, Confidence Scoring, Audit Trail

-- 1. Add processing pipeline fields to purchased_bills
ALTER TABLE purchased_bills ADD COLUMN IF NOT EXISTS processing_status VARCHAR(30) DEFAULT 'UPLOADED';
ALTER TABLE purchased_bills ADD COLUMN IF NOT EXISTS image_quality_score NUMERIC(5,2);
ALTER TABLE purchased_bills ADD COLUMN IF NOT EXISTS ocr_provider VARCHAR(50);
ALTER TABLE purchased_bills ADD COLUMN IF NOT EXISTS ai_provider VARCHAR(50);
ALTER TABLE purchased_bills ADD COLUMN IF NOT EXISTS overall_confidence NUMERIC(5,2);
ALTER TABLE purchased_bills ADD COLUMN IF NOT EXISTS image_hash VARCHAR(64);
ALTER TABLE purchased_bills ADD COLUMN IF NOT EXISTS item_fingerprint VARCHAR(128);
ALTER TABLE purchased_bills ADD COLUMN IF NOT EXISTS needs_review BOOLEAN DEFAULT false;
ALTER TABLE purchased_bills ADD COLUMN IF NOT EXISTS review_notes TEXT;
ALTER TABLE purchased_bills ADD COLUMN IF NOT EXISTS validation_status VARCHAR(30);
ALTER TABLE purchased_bills ADD COLUMN IF NOT EXISTS validation_discrepancy NUMERIC(12,2);
ALTER TABLE purchased_bills ADD COLUMN IF NOT EXISTS processing_duration_ms INTEGER;

-- 2. Add per-field confidence and correction fields to purchased_bill_items
ALTER TABLE purchased_bill_items ADD COLUMN IF NOT EXISTS ocr_confidence NUMERIC(5,2);
ALTER TABLE purchased_bill_items ADD COLUMN IF NOT EXISTS name_confidence NUMERIC(5,2);
ALTER TABLE purchased_bill_items ADD COLUMN IF NOT EXISTS quantity_confidence NUMERIC(5,2);
ALTER TABLE purchased_bill_items ADD COLUMN IF NOT EXISTS price_confidence NUMERIC(5,2);
ALTER TABLE purchased_bill_items ADD COLUMN IF NOT EXISTS needs_review BOOLEAN DEFAULT false;
ALTER TABLE purchased_bill_items ADD COLUMN IF NOT EXISTS review_reason TEXT;
ALTER TABLE purchased_bill_items ADD COLUMN IF NOT EXISTS ai_raw_name VARCHAR(200);
ALTER TABLE purchased_bill_items ADD COLUMN IF NOT EXISTS user_corrected_name VARCHAR(200);
ALTER TABLE purchased_bill_items ADD COLUMN IF NOT EXISTS user_corrected_price NUMERIC(12,2);
ALTER TABLE purchased_bill_items ADD COLUMN IF NOT EXISTS user_corrected_quantity NUMERIC(12,3);
ALTER TABLE purchased_bill_items ADD COLUMN IF NOT EXISTS line_valid BOOLEAN DEFAULT true;

-- 3. Create bill_extraction_audit table — full audit trail for every pipeline stage
CREATE TABLE IF NOT EXISTS bill_extraction_audit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_id UUID NOT NULL REFERENCES purchased_bills(id) ON DELETE CASCADE,
    stage VARCHAR(50) NOT NULL,
    provider VARCHAR(50),
    model VARCHAR(100),
    raw_input TEXT,
    raw_output TEXT,
    structured_output JSONB,
    confidence NUMERIC(5,2),
    duration_ms INTEGER,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_extraction_audit_bill ON bill_extraction_audit(bill_id);

-- 4. Create bill_user_corrections table — track user edits for future learning
CREATE TABLE IF NOT EXISTS bill_user_corrections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_item_id UUID NOT NULL REFERENCES purchased_bill_items(id) ON DELETE CASCADE,
    field_name VARCHAR(50) NOT NULL,
    ai_value TEXT,
    user_value TEXT,
    merchant_name VARCHAR(150),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_corrections_item ON bill_user_corrections(bill_item_id);
CREATE INDEX IF NOT EXISTS idx_user_corrections_merchant ON bill_user_corrections(merchant_name);

-- 5. Add reference tracking to stock_transactions
ALTER TABLE stock_transactions ADD COLUMN IF NOT EXISTS reference_type VARCHAR(30);
ALTER TABLE stock_transactions ADD COLUMN IF NOT EXISTS reference_id UUID;

CREATE INDEX IF NOT EXISTS idx_stock_tx_reference ON stock_transactions(reference_type, reference_id);

-- 6. Backfill existing bills with processing_status = 'CONFIRMED' where status = 'CONFIRMED'
UPDATE purchased_bills SET processing_status = status WHERE processing_status IS NULL OR processing_status = 'UPLOADED';
