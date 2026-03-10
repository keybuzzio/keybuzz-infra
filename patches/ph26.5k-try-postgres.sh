#!/bin/bash
# PH26.5K: Try postgres superuser

echo "=== Trying postgres superuser ==="

# Try with placeholder password
kubectl run psql-k7 --rm -i --restart=Never --image=postgres:16-alpine -n keybuzz-backend-dev -- \
  psql 'postgresql://postgres:CHANGE_ME_LATER_VIA_VAULT@10.0.0.10:5432/keybuzz' -c "SELECT 'Connected as postgres' as status;" 2>&1 || echo "Failed with placeholder"
