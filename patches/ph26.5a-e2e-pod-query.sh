#!/bin/bash
# PH26.5A-E2E: Query messages via Kubernetes pod

POD=$(kubectl get pods -n keybuzz-backend-dev --field-selector=status.phase=Running -o name | grep keybuzz-backend | head -1 | sed 's|pod/||')
echo "Using pod: $POD"

echo ""
echo "=== Step 1: Messages for order 171-9818805-2516327 ==="
kubectl exec -n keybuzz-backend-dev $POD -- sh -c '
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d keybuzz_product -c "
SELECT 
  m.id as msg_id, 
  c.tenant_id, 
  m.direction, 
  CASE WHEN LENGTH(m.body) > 60 THEN SUBSTRING(m.body, 1, 60) || '\''...'\'' ELSE m.body END as preview,
  LENGTH(m.body) as body_len
FROM messages m 
JOIN conversations c ON m.conversation_id = c.id 
WHERE c.order_ref = '\''171-9818805-2516327'\''
ORDER BY m.created_at DESC LIMIT 5;"
'

echo ""
echo "=== Step 2: Attachments for this order ==="
kubectl exec -n keybuzz-backend-dev $POD -- sh -c '
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d keybuzz_product -c "
SELECT 
  ma.id as att_id,
  ma.message_id,
  ma.filename,
  ma.mime_type,
  ma.size_bytes,
  ma.status
FROM message_attachments ma
JOIN messages m ON ma.message_id = m.id
JOIN conversations c ON m.conversation_id = c.id 
WHERE c.order_ref = '\''171-9818805-2516327'\''
ORDER BY ma.created_at DESC LIMIT 5;"
'

echo ""
echo "=== Step 3: Full body of latest inbound ==="
kubectl exec -n keybuzz-backend-dev $POD -- sh -c '
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d keybuzz_product -t -c "
SELECT m.body
FROM messages m 
JOIN conversations c ON m.conversation_id = c.id 
WHERE c.order_ref = '\''171-9818805-2516327'\'' AND m.direction = '\''inbound'\''
ORDER BY m.created_at DESC LIMIT 1;"
'

echo ""
echo "=== Step 4: ExternalMessage raw (backend DB) ==="
kubectl exec -n keybuzz-backend-dev $POD -- sh -c '
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d keybuzz_backend -c "
SELECT 
  id,
  \"tenantId\",
  \"externalId\",
  CASE WHEN LENGTH(raw::text) > 100 THEN SUBSTRING(raw::text, 1, 100) || '\''...'\'' ELSE raw::text END as raw_preview
FROM \"ExternalMessage\"
WHERE raw::text LIKE '\''%171-9818805-2516327%'\''
ORDER BY \"receivedAt\" DESC LIMIT 3;"
'
