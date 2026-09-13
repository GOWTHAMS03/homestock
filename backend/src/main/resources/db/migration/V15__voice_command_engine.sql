-- ============================================================================
-- V15: Production-Grade AI Voice Command Engine
-- Stores audit trail for all voice commands, recognized speech, dual confidences,
-- detected language, idempotency keys, and execution status.
-- ============================================================================

CREATE TABLE IF NOT EXISTS voice_command_audit (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    home_id             UUID NOT NULL REFERENCES homes(id) ON DELETE CASCADE,
    timestamp           TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    audio_hash          VARCHAR(64),
    recognized_text     TEXT,
    detected_language   VARCHAR(20),
    intent              VARCHAR(50),
    product_id          UUID REFERENCES inventory_items(id) ON DELETE SET NULL,
    product_name        VARCHAR(255),
    quantity            NUMERIC(10,3),
    unit                VARCHAR(30),
    target              VARCHAR(30),
    intent_confidence   NUMERIC(4,3),
    product_confidence  NUMERIC(4,3),
    execution_status    VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    error               TEXT,
    user_correction     TEXT,
    idempotency_key     VARCHAR(128),
    command_mode        VARCHAR(20) DEFAULT 'COMMAND',
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_voice_audit_home ON voice_command_audit(home_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_voice_audit_user ON voice_command_audit(user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_voice_audit_idem ON voice_command_audit(idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_voice_audit_created ON voice_command_audit(created_at);

