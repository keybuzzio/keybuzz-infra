#!/bin/bash
# PH26.5J: Get raw JSONB content

kubectl run psql-j4 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
SELECT 
  id,
  \"externalId\",
  LENGTH(raw::text) as raw_length,
  raw->'body' IS NOT NULL as has_body,
  LENGTH(raw->>'body') as body_length,
  \"createdAt\"
FROM \"ExternalMessage\"
WHERE \"tenantId\" = 'ecomlg-001'
  AND raw IS NOT NULL
  AND LENGTH(raw::text) > 100000
ORDER BY \"createdAt\" DESC
LIMIT 10;
"
