#!/usr/bin/env bash
set -euo pipefail

# PH-STUDIO-04A — Apply auth migration to Studio DB (DEV + PROD)
echo "=== PH-STUDIO-04A MIGRATION ==="

MIGRATION_SQL=$(cat <<'EOSQL'
-- PH-STUDIO-04A — Auth Foundation
DO $$ BEGIN
    ALTER TABLE users ADD COLUMN status VARCHAR(50) NOT NULL DEFAULT 'active';
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS auth_identities (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider            VARCHAR(50)  NOT NULL DEFAULT 'email',
    provider_identifier VARCHAR(320) NOT NULL,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    UNIQUE(provider, provider_identifier)
);
CREATE INDEX IF NOT EXISTS idx_auth_identities_user   ON auth_identities(user_id);
CREATE INDEX IF NOT EXISTS idx_auth_identities_lookup ON auth_identities(provider, provider_identifier);

CREATE TABLE IF NOT EXISTS email_otp_codes (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email       VARCHAR(320) NOT NULL,
    code_hash   TEXT         NOT NULL,
    purpose     VARCHAR(50)  NOT NULL DEFAULT 'login',
    expires_at  TIMESTAMPTZ  NOT NULL,
    consumed_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_otp_email_purpose ON email_otp_codes(email, purpose);
CREATE INDEX IF NOT EXISTS idx_otp_expires       ON email_otp_codes(expires_at);

CREATE TABLE IF NOT EXISTS sessions (
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workspace_id       UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    session_token_hash TEXT NOT NULL UNIQUE,
    expires_at         TIMESTAMPTZ NOT NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_sessions_user    ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_token   ON sessions(session_token_hash);
CREATE INDEX IF NOT EXISTS idx_sessions_expires ON sessions(expires_at);
EOSQL
)

# DEV migration
echo "--- Migrating keybuzz_studio (DEV) ---"
PGPASSWORD="CHANGE_ME_LATER_VIA_VAULT" psql -h 10.0.0.10 -U postgres -d keybuzz_studio -c "$MIGRATION_SQL" 2>&1
echo "DEV migration done."

# PROD migration
echo "--- Migrating keybuzz_studio_prod (PROD) ---"
PGPASSWORD="CHANGE_ME_LATER_VIA_VAULT" psql -h 10.0.0.10 -U postgres -d keybuzz_studio_prod -c "$MIGRATION_SQL" 2>&1
echo "PROD migration done."

echo "=== MIGRATION COMPLETE ==="
