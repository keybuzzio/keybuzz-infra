#!/bin/bash
# PH26.5J: Find ExternalMessage with raw content

echo "=== Finding ExternalMessage for conversation cmml0ym4qxa9a931e430248f4 ==="
kubectl run psql-j2 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
SELECT 
  id,
  \"externalId\",
  \"rawPayloadPath\",
  LENGTH(raw::text) as raw_length,
  \"createdAt\"
FROM \"ExternalMessage\"
WHERE \"conversationId\" = 'cmml0ym4qxa9a931e430248f4'
ORDER BY \"createdAt\" DESC
LIMIT 5;
"
