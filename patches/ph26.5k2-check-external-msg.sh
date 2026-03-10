#!/bin/bash
# PH26.5K2: Check if ExternalMessage contains raw email body

echo "=== Checking ExternalMessage raw content ==="
kubectl run psql-k2-1 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
SELECT 
  LEFT(id, 15) as ext_id,
  \"tenantId\",
  type,
  LENGTH(raw::text) as raw_length,
  raw->>'body' IS NOT NULL as has_body,
  LENGTH(raw->>'body') as body_length,
  raw->>'subject' as subject,
  \"createdAt\"
FROM \"ExternalMessage\"
WHERE \"tenantId\" = 'ecomlg-001'
  AND raw IS NOT NULL
ORDER BY \"createdAt\" DESC
LIMIT 10;
"

echo ""
echo "=== Sample raw content structure ==="
kubectl run psql-k2-2 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
SELECT 
  jsonb_object_keys(raw) as keys
FROM \"ExternalMessage\"
WHERE \"tenantId\" = 'ecomlg-001'
  AND raw IS NOT NULL
LIMIT 1;
"

echo ""
echo "=== Check if body contains MIME markers ==="
kubectl run psql-k2-3 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
SELECT 
  LEFT(id, 15) as ext_id,
  LENGTH(raw->>'body') as body_len,
  (raw->>'body') LIKE '%Content-Type:%' as has_content_type,
  (raw->>'body') LIKE '%boundary=%' as has_boundary,
  (raw->>'body') LIKE '%base64%' as has_base64
FROM \"ExternalMessage\"
WHERE \"tenantId\" = 'ecomlg-001'
  AND raw IS NOT NULL
  AND LENGTH(raw->>'body') > 1000
ORDER BY \"createdAt\" DESC
LIMIT 10;
"
