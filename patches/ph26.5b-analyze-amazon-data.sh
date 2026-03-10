#!/bin/bash
# PH26.5B: Analyze Amazon data structure for backfill design

DB_URL="postgresql://keybuzz_api_dev:IfVXI5kTGZ87Rh4LH9kVY3sGgDq3jNwR@10.0.0.10:5432/keybuzz"
DB_URL_BACKEND="postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend"

echo "=== PH26.5B: Analyze Amazon conversation/thread structure ==="

echo ""
echo "--- 1. Conversations with multiple messages (order_ref based) ---"
echo "SELECT c.order_ref, c.tenant_id, c.channel, COUNT(m.id) as msg_count, MIN(m.created_at)::date as first_msg, MAX(m.created_at)::date as last_msg FROM conversations c JOIN messages m ON m.conversation_id = c.id WHERE c.order_ref IS NOT NULL GROUP BY c.id, c.order_ref, c.tenant_id, c.channel HAVING COUNT(m.id) > 1 ORDER BY msg_count DESC LIMIT 10;" | kubectl run psql-b1 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- psql "$DB_URL" 2>&1 || true

echo ""
echo "--- 2. ExternalMessage structure (check for threadId/conversationId) ---"
echo "SELECT id, \"tenantId\", \"externalId\", raw->'amazonIds' as amazon_ids, raw->'threadKey' as thread_key FROM \"ExternalMessage\" WHERE \"tenantId\" = 'ecomlg-001' ORDER BY \"receivedAt\" DESC LIMIT 5;" | kubectl run psql-b2 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- psql "$DB_URL_BACKEND" 2>&1 || true

echo ""
echo "--- 3. Check if we have SP-API credentials ---"
echo "SELECT id, \"tenantId\", \"marketplaceType\", status, \"lastSyncAt\" FROM \"MarketplaceConnection\" WHERE \"marketplaceType\" = 'AMAZON' LIMIT 5;" | kubectl run psql-b3 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- psql "$DB_URL_BACKEND" 2>&1 || true

echo ""
echo "--- 4. Conversations table structure ---"
echo "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'conversations' ORDER BY ordinal_position;" | kubectl run psql-b4 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- psql "$DB_URL" 2>&1 || true

echo ""
echo "=== Done ==="
