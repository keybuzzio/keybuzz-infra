#!/bin/bash
# PH26.5K2: Verify what's stored in ExternalMessage for the PJ message

echo "=== ExternalMessage for the attachment message ==="
kubectl run psql-k2-16 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
SELECT 
  id,
  LENGTH(raw->>'body') as body_len,
  raw->>'body' as body,
  raw->>'subject' as subject,
  \"createdAt\"
FROM \"ExternalMessage\"
WHERE \"createdAt\" > '2026-01-30 14:09:00'
  AND \"createdAt\" < '2026-01-30 14:10:00';
"

echo ""
echo "=== Check if raw contains base64 anywhere ==="
kubectl run psql-k2-17 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
SELECT 
  LEFT(id, 15) as ext_id,
  LENGTH(raw::text) as raw_total_len,
  (raw::text LIKE '%base64%') as has_base64_anywhere,
  (raw::text LIKE '%image/jpeg%') as has_jpeg_marker
FROM \"ExternalMessage\"
WHERE \"tenantId\" = 'ecomlg-001'
ORDER BY \"createdAt\" DESC
LIMIT 20;
"
