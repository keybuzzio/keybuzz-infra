#!/bin/bash
# PH26.5I: List MessageAttachment table

kubectl run psql-i5 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
SELECT 
  id,
  filename,
  \"mimeType\",
  size,
  bucket,
  \"objectKey\",
  \"createdAt\"
FROM \"MessageAttachment\"
ORDER BY \"createdAt\" DESC 
LIMIT 15;
"
