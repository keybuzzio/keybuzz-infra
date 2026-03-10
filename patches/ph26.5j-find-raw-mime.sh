#!/bin/bash
# PH26.5J: Find raw MIME for the Alycia message with attachment

echo "=== Finding message with attachment att_abc40e20df9a9cc959669813 ==="
kubectl run psql-j1 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz' -c "
SELECT 
  ma.message_id,
  m.conversation_id,
  m.body,
  LENGTH(m.body) as body_length,
  ma.filename,
  ma.size_bytes
FROM message_attachments ma
JOIN messages m ON ma.message_id = m.id
WHERE ma.id = 'att_abc40e20df9a9cc959669813'
LIMIT 1;
"
