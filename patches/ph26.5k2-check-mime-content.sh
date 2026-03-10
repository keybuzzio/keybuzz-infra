#!/bin/bash
# PH26.5K2: Check MIME content in ExternalMessage

echo "=== Messages with MIME content (Content-Type header) ==="
kubectl run psql-k2-4 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
SELECT 
  LEFT(id, 15) as ext_id,
  LENGTH(raw->>'body') as body_len,
  CASE 
    WHEN (raw->>'body') LIKE '%Content-Type:%' THEN 'YES'
    ELSE 'NO'
  END as has_mime,
  CASE 
    WHEN (raw->>'body') LIKE '%base64%' THEN 'YES'
    ELSE 'NO'
  END as has_base64,
  CASE 
    WHEN (raw->>'body') LIKE '%attachment%' THEN 'YES'
    ELSE 'NO'
  END as has_attachment,
  \"createdAt\"
FROM \"ExternalMessage\"
WHERE \"tenantId\" = 'ecomlg-001'
  AND raw IS NOT NULL
ORDER BY \"createdAt\" DESC
LIMIT 15;
"

echo ""
echo "=== Link ExternalMessage to messages table ==="
kubectl run psql-k2-5 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'ExternalMessage'
ORDER BY ordinal_position;
"

echo ""
echo "=== Check ticketId linkage ==="
kubectl run psql-k2-6 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
SELECT 
  LEFT(e.id, 15) as ext_id,
  e.\"ticketId\",
  e.\"threadId\",
  e.\"orderId\",
  LENGTH(e.raw->>'body') as body_len
FROM \"ExternalMessage\" e
WHERE e.\"tenantId\" = 'ecomlg-001'
  AND e.raw IS NOT NULL
ORDER BY e.\"createdAt\" DESC
LIMIT 10;
"
