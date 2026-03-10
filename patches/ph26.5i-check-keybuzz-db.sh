#!/bin/bash
# PH26.5I: Check keybuzz product DB for message_attachments

echo "=== Checking keybuzz.message_attachments ==="
kubectl run psql-i7 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz' -c "
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
