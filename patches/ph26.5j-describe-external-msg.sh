#!/bin/bash
# PH26.5J: Describe ExternalMessage columns

kubectl run psql-j3 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'ExternalMessage'
ORDER BY ordinal_position;
"
