#!/bin/bash
# PH26.5A-E2E: Query message for order 171-9818805-2516327

export PGPASSWORD=$(cat /var/run/secrets/keybuzz/db-password)

echo "=== Step 1: Find message for order 171-9818805-2516327 ==="
psql -h 10.0.0.6 -U keybuzz -d keybuzz_product -t -c "
SELECT 
  m.id as message_id, 
  m.conversation_id, 
  c.tenant_id, 
  m.direction, 
  LEFT(m.body, 100) as body_preview,
  LENGTH(m.body) as body_len,
  m.created_at,
  (SELECT COUNT(*) FROM message_attachments ma WHERE ma.message_id = m.id) as att_count 
FROM messages m 
JOIN conversations c ON m.conversation_id = c.id 
WHERE c.order_ref = '171-9818805-2516327' 
ORDER BY m.created_at DESC 
LIMIT 5;
"

echo ""
echo "=== Step 2: Check ExternalMessage raw in backend DB ==="
psql -h 10.0.0.6 -U keybuzz -d keybuzz_backend -t -c "
SELECT 
  id,
  \"externalId\",
  \"tenantId\",
  \"receivedAt\",
  LEFT(raw::text, 200) as raw_preview
FROM \"ExternalMessage\"
WHERE raw::text LIKE '%171-9818805-2516327%'
ORDER BY \"receivedAt\" DESC
LIMIT 3;
"

echo ""
echo "=== Step 3: Full body of latest inbound message ==="
psql -h 10.0.0.6 -U keybuzz -d keybuzz_product -t -c "
SELECT m.body
FROM messages m 
JOIN conversations c ON m.conversation_id = c.id 
WHERE c.order_ref = '171-9818805-2516327' 
  AND m.direction = 'inbound'
ORDER BY m.created_at DESC 
LIMIT 1;
"
