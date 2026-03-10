#!/bin/bash
# PH26.5I: List all tables

kubectl run psql-i4 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend' -c "
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;
"
