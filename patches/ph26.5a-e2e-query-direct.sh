#!/bin/bash
# PH26.5A-E2E: Direct PostgreSQL queries using extracted credentials

# Credentials from pod env
PGHOST="10.0.0.10"
PGPORT="5432"
PGUSER_BACKEND="kb_backend"
PGPASS_BACKEND="7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8"
PGUSER_PRODUCT="keybuzz_api_dev"
PGPASS_PRODUCT="IfVXI5kTGZ87Rh4LH9kVY3sGgDq3jNwR"

echo "=== PH26.5A-E2E: Querying databases directly ==="

# Create a temporary pod with psql
kubectl run psql-e2e --rm -i --restart=Never \
  --image=postgres:16-alpine \
  -n keybuzz-backend-dev \
  --overrides='{"spec":{"containers":[{"name":"psql-e2e","image":"postgres:16-alpine","stdin":true,"tty":false,"command":["sh","-c","sleep 60"]}]}}' \
  -- &

sleep 5

echo ""
echo "=== Step 1: Messages for order 171-9818805-2516327 (keybuzz product DB) ==="
kubectl exec -i -n keybuzz-backend-dev psql-e2e -- sh -c "PGPASSWORD='$PGPASS_PRODUCT' psql -h $PGHOST -p $PGPORT -U $PGUSER_PRODUCT -d keybuzz -c \"
SELECT 
  m.id as msg_id, 
  c.tenant_id, 
  m.direction, 
  CASE WHEN LENGTH(m.body) > 60 THEN SUBSTRING(m.body, 1, 60) || '...' ELSE m.body END as preview,
  LENGTH(m.body) as body_len
FROM messages m 
JOIN conversations c ON m.conversation_id = c.id 
WHERE c.order_ref = '171-9818805-2516327'
ORDER BY m.created_at DESC LIMIT 5;
\""

echo ""
echo "=== Step 2: Attachments for this order ==="
kubectl exec -i -n keybuzz-backend-dev psql-e2e -- sh -c "PGPASSWORD='$PGPASS_PRODUCT' psql -h $PGHOST -p $PGPORT -U $PGUSER_PRODUCT -d keybuzz -c \"
SELECT 
  ma.id as att_id,
  ma.filename,
  ma.mime_type,
  ma.size_bytes,
  ma.status
FROM message_attachments ma
JOIN messages m ON ma.message_id = m.id
JOIN conversations c ON m.conversation_id = c.id 
WHERE c.order_ref = '171-9818805-2516327'
ORDER BY ma.created_at DESC LIMIT 5;
\""

echo ""
echo "=== Step 3: Full body of latest inbound ==="
kubectl exec -i -n keybuzz-backend-dev psql-e2e -- sh -c "PGPASSWORD='$PGPASS_PRODUCT' psql -h $PGHOST -p $PGPORT -U $PGUSER_PRODUCT -d keybuzz -t -c \"
SELECT m.body
FROM messages m 
JOIN conversations c ON m.conversation_id = c.id 
WHERE c.order_ref = '171-9818805-2516327' AND m.direction = 'inbound'
ORDER BY m.created_at DESC LIMIT 1;
\""

echo ""
echo "=== Step 4: ExternalMessage in backend DB ==="
kubectl exec -i -n keybuzz-backend-dev psql-e2e -- sh -c "PGPASSWORD='$PGPASS_BACKEND' psql -h $PGHOST -p $PGPORT -U $PGUSER_BACKEND -d keybuzz_backend -c \"
SELECT 
  id,
  \\\"tenantId\\\",
  CASE WHEN LENGTH(raw::text) > 100 THEN SUBSTRING(raw::text, 1, 100) || '...' ELSE raw::text END as raw_preview
FROM \\\"ExternalMessage\\\"
WHERE raw::text LIKE '%171-9818805-2516327%'
ORDER BY \\\"receivedAt\\\" DESC LIMIT 3;
\""

# Cleanup
kubectl delete pod psql-e2e -n keybuzz-backend-dev --ignore-not-found=true 2>/dev/null || true
