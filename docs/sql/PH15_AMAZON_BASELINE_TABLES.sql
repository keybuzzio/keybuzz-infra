-- =============================================================================
-- PH15_AMAZON_BASELINE_TABLES.sql
-- Création des tables manquantes pour Amazon/Inbound Email
-- Date: 2026-01-07
-- Auteur: KeyBuzz CE
-- =============================================================================
-- IDEMPOTENT: Utilise IF NOT EXISTS / DO $$ ... END $$ pour éviter les erreurs
-- =============================================================================

-- ============================================
-- 1) CRÉATION DES TYPES ENUM
-- ============================================

-- MarketplaceType enum
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'MarketplaceType') THEN
        CREATE TYPE "MarketplaceType" AS ENUM ('AMAZON', 'FNAC', 'CDISCOUNT', 'OTHER');
    END IF;
END$$;

-- MarketplaceConnectionStatus enum
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'MarketplaceConnectionStatus') THEN
        CREATE TYPE "MarketplaceConnectionStatus" AS ENUM ('PENDING', 'CONNECTED', 'ERROR', 'DISABLED');
    END IF;
END$$;

-- InboundConnectionStatus enum
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'InboundConnectionStatus') THEN
        CREATE TYPE "InboundConnectionStatus" AS ENUM ('DRAFT', 'WAITING_EMAIL', 'WAITING_AMAZON', 'READY', 'DEGRADED', 'ERROR');
    END IF;
END$$;

-- InboundValidationStatus enum
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'InboundValidationStatus') THEN
        CREATE TYPE "InboundValidationStatus" AS ENUM ('PENDING', 'VALIDATED', 'FAILED');
    END IF;
END$$;

-- ============================================
-- 2) TABLE marketplace_connections
-- ============================================

CREATE TABLE IF NOT EXISTS "marketplace_connections" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "type" "MarketplaceType" NOT NULL,
    "status" "MarketplaceConnectionStatus" NOT NULL DEFAULT 'PENDING',
    "displayName" TEXT,
    "region" TEXT,
    "marketplaceId" TEXT,
    "vaultPath" TEXT,
    "lastSyncAt" TIMESTAMP(3),
    "lastError" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "marketplace_connections_pkey" PRIMARY KEY ("id")
);

-- Indexes for marketplace_connections
CREATE INDEX IF NOT EXISTS "marketplace_connections_tenantId_type_idx" 
    ON "marketplace_connections"("tenantId", "type");

-- ============================================
-- 3) TABLE inbound_connections
-- ============================================

CREATE TABLE IF NOT EXISTS "inbound_connections" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "marketplace" TEXT NOT NULL,
    "countries" JSONB NOT NULL,
    "status" "InboundConnectionStatus" NOT NULL DEFAULT 'DRAFT',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "inbound_connections_pkey" PRIMARY KEY ("id")
);

-- Unique constraint: one connection per tenant+marketplace
CREATE UNIQUE INDEX IF NOT EXISTS "inbound_connections_tenantId_marketplace_key" 
    ON "inbound_connections"("tenantId", "marketplace");

-- Index on status
CREATE INDEX IF NOT EXISTS "inbound_connections_status_idx" 
    ON "inbound_connections"("status");

-- Foreign key to tenants (if table exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tenants') THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'inbound_connections_tenantId_fkey'
        ) THEN
            ALTER TABLE "inbound_connections" 
            ADD CONSTRAINT "inbound_connections_tenantId_fkey" 
            FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;
        END IF;
    END IF;
END$$;

-- ============================================
-- 4) TABLE inbound_addresses
-- ============================================

CREATE TABLE IF NOT EXISTS "inbound_addresses" (
    "id" TEXT NOT NULL,
    "connectionId" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "marketplace" TEXT NOT NULL,
    "country" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "emailAddress" TEXT NOT NULL,
    "validationStatus" "InboundValidationStatus" NOT NULL DEFAULT 'PENDING',
    "pipelineStatus" "InboundValidationStatus" NOT NULL DEFAULT 'PENDING',
    "marketplaceStatus" "InboundValidationStatus" NOT NULL DEFAULT 'PENDING',
    "lastInboundAt" TIMESTAMP(3),
    "lastInboundMessageId" TEXT,
    "lastError" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "inbound_addresses_pkey" PRIMARY KEY ("id")
);

-- Unique constraint: one address per tenant+marketplace+country
CREATE UNIQUE INDEX IF NOT EXISTS "inbound_addresses_tenantId_marketplace_country_key" 
    ON "inbound_addresses"("tenantId", "marketplace", "country");

-- Index on validation status + last inbound
CREATE INDEX IF NOT EXISTS "inbound_addresses_validationStatus_lastInboundAt_idx" 
    ON "inbound_addresses"("validationStatus", "lastInboundAt");

-- Index on pipeline + marketplace status
CREATE INDEX IF NOT EXISTS "inbound_addresses_pipelineStatus_marketplaceStatus_idx" 
    ON "inbound_addresses"("pipelineStatus", "marketplaceStatus");

-- Foreign key to inbound_connections
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'inbound_addresses_connectionId_fkey'
    ) THEN
        ALTER TABLE "inbound_addresses" 
        ADD CONSTRAINT "inbound_addresses_connectionId_fkey" 
        FOREIGN KEY ("connectionId") REFERENCES "inbound_connections"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    END IF;
END$$;

-- Foreign key to tenants (if table exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tenants') THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'inbound_addresses_tenantId_fkey'
        ) THEN
            ALTER TABLE "inbound_addresses" 
            ADD CONSTRAINT "inbound_addresses_tenantId_fkey" 
            FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;
        END IF;
    END IF;
END$$;

-- ============================================
-- 5) TABLE oauth_states
-- ============================================

CREATE TABLE IF NOT EXISTS "oauth_states" (
    "id" TEXT NOT NULL,
    "state" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "connectionId" TEXT,
    "marketplaceType" "MarketplaceType" NOT NULL DEFAULT 'AMAZON',
    "used" BOOLEAN NOT NULL DEFAULT false,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "usedAt" TIMESTAMP(3),

    CONSTRAINT "oauth_states_pkey" PRIMARY KEY ("id")
);

-- Unique constraint on state (anti-CSRF token)
CREATE UNIQUE INDEX IF NOT EXISTS "oauth_states_state_key" 
    ON "oauth_states"("state");

-- Indexes for oauth_states
CREATE INDEX IF NOT EXISTS "oauth_states_state_idx" 
    ON "oauth_states"("state");
CREATE INDEX IF NOT EXISTS "oauth_states_tenantId_idx" 
    ON "oauth_states"("tenantId");
CREATE INDEX IF NOT EXISTS "oauth_states_connectionId_idx" 
    ON "oauth_states"("connectionId");
CREATE INDEX IF NOT EXISTS "oauth_states_expiresAt_idx" 
    ON "oauth_states"("expiresAt");

-- ============================================
-- 6) TABLE marketplace_sync_states (bonus - utilisé par poller)
-- ============================================

CREATE TABLE IF NOT EXISTS "marketplace_sync_states" (
    "id" TEXT NOT NULL,
    "connectionId" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "type" "MarketplaceType" NOT NULL,
    "cursor" TEXT,
    "lastPolledAt" TIMESTAMP(3),
    "lastSuccessAt" TIMESTAMP(3),
    "lastError" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "marketplace_sync_states_pkey" PRIMARY KEY ("id")
);

-- Indexes for marketplace_sync_states
CREATE INDEX IF NOT EXISTS "marketplace_sync_states_tenantId_type_idx" 
    ON "marketplace_sync_states"("tenantId", "type");
CREATE INDEX IF NOT EXISTS "marketplace_sync_states_connectionId_idx" 
    ON "marketplace_sync_states"("connectionId");

-- ============================================
-- 7) VERIFICATION FINALE
-- ============================================

DO $$
DECLARE
    table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN ('marketplace_connections', 'inbound_connections', 'inbound_addresses', 'oauth_states', 'marketplace_sync_states');
    
    RAISE NOTICE 'PH15 BASELINE: % tables créées sur 5 attendues', table_count;
END$$;

-- ============================================
-- FIN DU SCRIPT
-- ============================================
