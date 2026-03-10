#!/bin/bash
# PH26.5A-E2E: Get raw MIME for problematic message (ecomlg tenant)

DB_URL="postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend"

echo "=== Get raw MIME for ecomlg-001 messages with PJ around 2026-01-30 ==="
echo "SELECT id, \"tenantId\", \"externalId\", \"receivedAt\", LEFT(raw::text, 1500) as raw_preview FROM \"ExternalMessage\" WHERE \"tenantId\" = 'ecomlg-001' ORDER BY \"receivedAt\" DESC LIMIT 5;" | kubectl run psql-raw2 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- psql "$DB_URL" 2>&1 || true
