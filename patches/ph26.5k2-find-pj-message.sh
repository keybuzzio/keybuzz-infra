#!/bin/bash
# PH26.5K2: Find the message with attachment

echo "=== Find message with placeholder body ==="
kubectl run psql-k2-11 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://keybuzz_api_dev:IfVXI5kTGZ87Rh4LH9kVY3sGgDq3jNwR@10.0.0.10:5432/keybuzz' -c "
SELECT 
  m.id as msg_id,
  m.body,
  m.created_at,
  ma.id as att_id,
  ma.filename,
  ma.size_bytes
FROM messages m
LEFT JOIN message_attachments ma ON ma.message_id = m.id
WHERE m.tenant_id = 'ecomlg-001'
  AND m.body = '[PiÃ¨ce jointe reÃ§ue]'
ORDER BY m.created_at DESC
LIMIT 5;
"

echo ""
echo "=== Find ExternalMessage around same time ==="
kubectl run psql-k2-12 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
SELECT 
  id,
  \"tenantId\",
  raw->>'subject' as subject,
  LENGTH(raw->>'body') as body_len,
  \"createdAt\"
FROM \"ExternalMessage\"
WHERE \"tenantId\" = 'ecomlg-001'
  AND \"createdAt\" > '2026-01-30 14:09:00'
  AND \"createdAt\" < '2026-01-30 14:10:00'
ORDER BY \"createdAt\";
"
