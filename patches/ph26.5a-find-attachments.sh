#!/bin/bash
# PH26.5A-E2E: Find messages with attachments

DB_URL="postgresql://keybuzz_api_dev:IfVXI5kTGZ87Rh4LH9kVY3sGgDq3jNwR@10.0.0.10:5432/keybuzz"

echo "=== Messages with attachments ==="
echo "SELECT ma.id, ma.message_id, ma.filename, ma.mime_type, ma.size_bytes, ma.created_at FROM message_attachments ma ORDER BY ma.created_at DESC LIMIT 10;" | kubectl run psql-findatt --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- psql "$DB_URL" 2>&1 || true

echo ""
echo "=== Get message details for attachments ==="
echo "SELECT m.id as msg_id, c.order_ref, SUBSTRING(m.body, 1, 80) as body_preview, LENGTH(m.body) as body_len, m.created_at FROM messages m JOIN message_attachments ma ON ma.message_id = m.id JOIN conversations c ON m.conversation_id = c.id ORDER BY ma.created_at DESC LIMIT 5;" | kubectl run psql-findmsg --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- psql "$DB_URL" 2>&1 || true
