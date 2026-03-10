#!/bin/bash
# PH26.5K: Try with keybuzz_api_dev user

echo "=== Checking user privileges ==="

kubectl run psql-k5 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://keybuzz_api_dev:IfVXI5kTGZ87Rh4LH9kVY3sGgDq3jNwR@10.0.0.10:5432/keybuzz' -c "
SELECT 
  has_table_privilege('keybuzz_api_dev', 'messages', 'SELECT') as can_select,
  has_table_privilege('keybuzz_api_dev', 'messages', 'INSERT') as can_insert,
  has_table_privilege('keybuzz_api_dev', 'messages', 'UPDATE') as can_update;
"

echo ""
echo "=== Trying ALTER TABLE ==="

kubectl run psql-k6 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://keybuzz_api_dev:IfVXI5kTGZ87Rh4LH9kVY3sGgDq3jNwR@10.0.0.10:5432/keybuzz' -c "
ALTER TABLE messages ADD COLUMN IF NOT EXISTS raw_mime_key TEXT;
"
