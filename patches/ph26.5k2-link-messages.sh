#!/bin/bash
# PH26.5K2: Link ExternalMessage to messages via timestamp

echo "=== Messages table with matching timestamps ==="
kubectl run psql-k2-7 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://keybuzz_api_dev:IfVXI5kTGZ87Rh4LH9kVY3sGgDq3jNwR@10.0.0.10:5432/keybuzz' -c "
SELECT 
  LEFT(id, 20) as msg_id,
  direction,
  LEFT(body, 40) as body_preview,
  raw_mime_key IS NOT NULL as has_raw,
  created_at
FROM messages
WHERE tenant_id = 'ecomlg-001'
  AND direction = 'inbound'
ORDER BY created_at DESC
LIMIT 10;
"

echo ""
echo "=== Try to match by timestamp window (1 second) ==="
kubectl run psql-k2-8 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
WITH ext AS (
  SELECT 
    id as ext_id,
    raw->>'body' as body,
    LENGTH(raw->>'body') as body_len,
    \"createdAt\" as ext_created
  FROM \"ExternalMessage\"
  WHERE \"tenantId\" = 'ecomlg-001'
    AND raw IS NOT NULL
),
msg AS (
  SELECT 
    id as msg_id,
    body as msg_body,
    created_at as msg_created
  FROM keybuzz.messages
  WHERE tenant_id = 'ecomlg-001'
    AND direction = 'inbound'
)
SELECT 
  LEFT(e.ext_id, 15) as ext_id,
  LEFT(m.msg_id, 15) as msg_id,
  e.body_len,
  LEFT(m.msg_body, 30) as msg_body,
  e.ext_created,
  m.msg_created
FROM ext e
LEFT JOIN msg m ON ABS(EXTRACT(EPOCH FROM (e.ext_created - m.msg_created))) < 2
ORDER BY e.ext_created DESC
LIMIT 10;
"
