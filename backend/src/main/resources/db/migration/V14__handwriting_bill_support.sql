-- V14: Handwriting Bill Support — Add document_type to purchased_bills
ALTER TABLE purchased_bills ADD COLUMN IF NOT EXISTS document_type VARCHAR(30) DEFAULT 'PRINTED';

CREATE INDEX IF NOT EXISTS idx_purchased_bills_document_type ON purchased_bills(document_type);
