#!/bin/bash
# PH26.5K: Find table owner

kubectl run psql-k4 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz' -c "
SELECT tableowner FROM pg_tables WHERE tablename = 'messages';
"
