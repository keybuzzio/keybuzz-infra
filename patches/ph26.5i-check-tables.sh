#!/bin/bash
# PH26.5I: Check attachment tables

echo "=== Checking message_attachments ==="
kubectl run psql-i6 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
SELECT 
  id,
  filename,
  mime_type,
  size_bytes,
  storage_key,
  created_at
FROM message_attachments
ORDER BY created_at DESC 
LIMIT 10;
"
