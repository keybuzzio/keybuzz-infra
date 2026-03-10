#!/bin/bash
# PH26.5K2: Find messages with attachments

echo "=== All messages with attachments ==="
kubectl run psql-k2-13 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://keybuzz_api_dev:IfVXI5kTGZ87Rh4LH9kVY3sGgDq3jNwR@10.0.0.10:5432/keybuzz' -c "
SELECT 
  m.id as msg_id,
  LEFT(m.body, 30) as body_preview,
  m.created_at,
  ma.filename,
  ma.size_bytes
FROM messages m
JOIN message_attachments ma ON ma.message_id = m.id
WHERE m.tenant_id = 'ecomlg-001'
ORDER BY m.created_at DESC
LIMIT 10;
"

echo ""
echo "=== Find messages with body containing 'jointe' ==="
kubectl run psql-k2-14 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://keybuzz_api_dev:IfVXI5kTGZ87Rh4LH9kVY3sGgDq3jNwR@10.0.0.10:5432/keybuzz' -c "
SELECT 
  id,
  body,
  created_at
FROM messages
WHERE tenant_id = 'ecomlg-001'
  AND body LIKE '%jointe%'
LIMIT 5;
"

echo ""
echo "=== ExternalMessage body for cml0ym4g7 ==="
kubectl run psql-k2-15 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
SELECT 
  id,
  raw->>'body' as body,
  raw
FROM \"ExternalMessage\"
WHERE id LIKE 'cml0ym4g7%'
LIMIT 1;
"
