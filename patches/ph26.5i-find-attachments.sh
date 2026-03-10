#!/bin/bash
# PH26.5I: Find recent image attachments

kubectl run psql-i2 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
SELECT 
  ma.id,
  ma.filename,
  ma.mime_type,
  ma.size_bytes,
  ma.storage_path,
  ma.created_at
FROM message_attachments ma 
ORDER BY ma.created_at DESC 
LIMIT 15;
"
