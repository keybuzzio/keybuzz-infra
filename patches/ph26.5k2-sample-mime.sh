#!/bin/bash
# PH26.5K2: Sample MIME content from ExternalMessage

echo "=== Sample MIME content (first 2000 chars) ==="
kubectl run psql-k2-9 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
SELECT 
  LEFT(id, 15) as ext_id,
  LEFT(raw->>'body', 2000) as body_sample
FROM \"ExternalMessage\"
WHERE \"tenantId\" = 'ecomlg-001'
  AND raw IS NOT NULL
  AND LENGTH(raw->>'body') > 30000
ORDER BY \"createdAt\" DESC
LIMIT 1;
"

echo ""
echo "=== Check the placeholder message raw ==="
kubectl run psql-k2-10 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
SELECT 
  id,
  raw->>'body' as body,
  raw->>'subject' as subject,
  raw
FROM \"ExternalMessage\"
WHERE id = 'cml0ym4g7000e8h';
"
