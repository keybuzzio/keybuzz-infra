#!/bin/bash
# PH26.5K Validation: Check raw MIME storage

echo "=== Step 1: Check messages with raw_mime_key ==="
kubectl run psql-v1 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://keybuzz_api_dev:IfVXI5kTGZ87Rh4LH9kVY3sGgDq3jNwR@10.0.0.10:5432/keybuzz' -c "
SELECT 
  LEFT(id, 10) || '...' as msg_id_trunc,
  tenant_id,
  direction,
  LEFT(body, 50) as body_preview,
  raw_mime_key IS NOT NULL as has_raw_mime,
  raw_mime_size_bytes,
  LEFT(raw_mime_sha256, 16) as sha256_prefix,
  created_at
FROM messages
WHERE tenant_id = 'ecomlg-001'
ORDER BY created_at DESC
LIMIT 10;
"

echo ""
echo "=== Step 2: Count messages with/without raw_mime ==="
kubectl run psql-v2 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://keybuzz_api_dev:IfVXI5kTGZ87Rh4LH9kVY3sGgDq3jNwR@10.0.0.10:5432/keybuzz' -c "
SELECT 
  COUNT(*) FILTER (WHERE raw_mime_key IS NOT NULL) as with_raw_mime,
  COUNT(*) FILTER (WHERE raw_mime_key IS NULL) as without_raw_mime,
  COUNT(*) as total
FROM messages
WHERE tenant_id = 'ecomlg-001';
"

echo ""
echo "=== Step 3: Find placeholder messages ==="
kubectl run psql-v3 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://keybuzz_api_dev:IfVXI5kTGZ87Rh4LH9kVY3sGgDq3jNwR@10.0.0.10:5432/keybuzz' -c "
SELECT 
  LEFT(id, 15) || '...' as msg_id,
  direction,
  body,
  raw_mime_key IS NOT NULL as has_raw,
  created_at
FROM messages
WHERE tenant_id = 'ecomlg-001'
  AND (body = '[PiÃ¨ce jointe reÃ§ue]' OR body IS NULL OR LENGTH(body) < 10)
ORDER BY created_at DESC
LIMIT 5;
"
