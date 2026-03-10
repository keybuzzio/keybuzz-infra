#!/bin/bash
# PH26.5A-E2E: Get raw MIME for problematic message

DB_URL="postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend"

echo "=== Get raw MIME for message around 2026-01-30 14:09 ==="
echo "SELECT id, \"tenantId\", \"externalId\", SUBSTRING(raw::text, 1, 3000) as raw_body FROM \"ExternalMessage\" WHERE \"receivedAt\" > '2026-01-30 14:00:00' ORDER BY \"receivedAt\" DESC LIMIT 3;" | kubectl run psql-raw --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- psql "$DB_URL" 2>&1 || true
