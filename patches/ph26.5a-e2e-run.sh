#!/bin/bash
# PH26.5A-E2E: Run queries via psql pod

set -e

DB_URL="postgresql://keybuzz_api_dev:IfVXI5kTGZ87Rh4LH9kVY3sGgDq3jNwR@10.0.0.10:5432/keybuzz"
DB_URL_BACKEND="postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend"

echo "=== PH26.5A-E2E: Query messages for order 171-9818805-2516327 ==="

echo ""
echo "--- Step 1: Messages list ---"
echo "SELECT m.id, c.tenant_id, m.direction, SUBSTRING(m.body, 1, 60) as preview, LENGTH(m.body) as len FROM messages m JOIN conversations c ON m.conversation_id = c.id WHERE c.order_ref = '171-9818805-2516327' ORDER BY m.created_at DESC LIMIT 5;" | kubectl run psql-q1 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- psql "$DB_URL" 2>&1 || true

echo ""
echo "--- Step 2: Attachments ---"
echo "SELECT ma.id, ma.filename, ma.mime_type, ma.size_bytes, ma.status FROM message_attachments ma JOIN messages m ON ma.message_id = m.id JOIN conversations c ON m.conversation_id = c.id WHERE c.order_ref = '171-9818805-2516327' ORDER BY ma.created_at DESC LIMIT 5;" | kubectl run psql-q2 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- psql "$DB_URL" 2>&1 || true

echo ""
echo "--- Step 3: Full body of latest inbound ---"
echo "SELECT m.body FROM messages m JOIN conversations c ON m.conversation_id = c.id WHERE c.order_ref = '171-9818805-2516327' AND m.direction = 'inbound' ORDER BY m.created_at DESC LIMIT 1;" | kubectl run psql-q3 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- psql -t "$DB_URL" 2>&1 || true

echo ""
echo "--- Step 4: ExternalMessage raw (backend DB) ---"
echo "SELECT id, \"tenantId\", SUBSTRING(raw::text, 1, 150) as raw_preview FROM \"ExternalMessage\" WHERE raw::text LIKE '%171-9818805-2516327%' ORDER BY \"receivedAt\" DESC LIMIT 3;" | kubectl run psql-q4 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- psql "$DB_URL_BACKEND" 2>&1 || true

echo ""
echo "=== Done ==="
