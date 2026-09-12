-- ============================================================================
-- V10: Authentication Identities, Stable User Identity, and Room Memberships
-- ============================================================================

-- 1. Extend users table for stable identity & soft deletion
ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name VARCHAR(120);
ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(60);
ALTER TABLE users ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE';
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

-- Populate display_name from full_name if empty
UPDATE users
SET display_name = full_name
WHERE display_name IS NULL;

-- Backfill usernames where missing
UPDATE users
SET username = LOWER(REGEXP_REPLACE(SPLIT_PART(email, '@', 1), '[^a-z0-9_]', '', 'g')) || '_' || SUBSTR(REPLACE(id::text, '-', ''), 1, 6)
WHERE username IS NULL;

-- Add unique constraint on username if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_users_username'
    ) THEN
        ALTER TABLE users ADD CONSTRAINT uq_users_username UNIQUE (username);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);

-- 2. Create auth_identities table (multi-identity support: Google, Local, etc.)
CREATE TABLE IF NOT EXISTS auth_identities (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL,
    provider_subject VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_auth_identity UNIQUE (provider, provider_subject)
);

CREATE INDEX IF NOT EXISTS idx_auth_identities_user_id ON auth_identities(user_id);
CREATE INDEX IF NOT EXISTS idx_auth_identities_provider_sub ON auth_identities(provider, provider_subject);

-- Backfill local auth identity for existing users
INSERT INTO auth_identities (id, user_id, provider, provider_subject, created_at, updated_at)
SELECT
    gen_random_uuid(),
    u.id,
    'LOCAL',
    u.email,
    NOW(),
    NOW()
FROM users u
WHERE NOT EXISTS (
    SELECT 1 FROM auth_identities ai
    WHERE ai.user_id = u.id AND ai.provider = 'LOCAL'
);

-- 3. Create rooms table
CREATE TABLE IF NOT EXISTS rooms (
    id UUID PRIMARY KEY,
    room_code VARCHAR(32) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    owner_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rooms_room_code ON rooms(room_code);
CREATE INDEX IF NOT EXISTS idx_rooms_owner_user_id ON rooms(owner_user_id);
CREATE INDEX IF NOT EXISTS idx_rooms_status ON rooms(status);

-- 4. Create room_members table
CREATE TABLE IF NOT EXISTS room_members (
    id UUID PRIMARY KEY,
    room_id UUID NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'MEMBER',
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_seen_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT uq_room_member UNIQUE(room_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_room_members_room_id ON room_members(room_id);
CREATE INDEX IF NOT EXISTS idx_room_members_user_id ON room_members(user_id);
CREATE INDEX IF NOT EXISTS idx_room_members_status ON room_members(status);

-- Backfill rooms from existing homes
INSERT INTO rooms (id, room_code, name, owner_user_id, status, created_at, updated_at)
SELECT
    h.id,
    h.invite_code,
    h.name,
    h.created_by,
    'ACTIVE',
    h.created_at,
    h.updated_at
FROM homes h
WHERE NOT EXISTS (
    SELECT 1 FROM rooms r WHERE r.id = h.id
);

-- Backfill room_members from existing home_members
INSERT INTO room_members (id, room_id, user_id, role, status, joined_at, created_at, updated_at)
SELECT
    hm.id,
    hm.home_id,
    hm.user_id,
    hm.role,
    'ACTIVE',
    hm.joined_at,
    COALESCE(hm.joined_at, NOW()),
    hm.updated_at
FROM home_members hm
WHERE NOT EXISTS (
    SELECT 1 FROM room_members rm WHERE rm.room_id = hm.home_id AND rm.user_id = hm.user_id
);
