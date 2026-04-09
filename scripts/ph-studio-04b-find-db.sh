#!/usr/bin/env bash
set -euo pipefail

echo "=== Finding PostgreSQL pods ==="
kubectl get pods -A | grep -iE 'postgres|pg|patro|spilo' || echo "No postgres pods found"

echo ""
echo "=== DB Secret ==="
kubectl get secret keybuzz-studio-api-db -n keybuzz-studio-api-dev -o jsonpath='{.data}' | python3 -c "
import sys, json, base64
d = json.load(sys.stdin)
for k, v in d.items():
    print(f'{k}: {base64.b64decode(v).decode()}')
"

echo ""
echo "=== Trying psql from postgres pods ==="
for ns in default keybuzz-db postgres postgresql; do
  pods=$(kubectl get pods -n "$ns" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
  if [ -n "$pods" ]; then
    echo "Namespace $ns: $pods"
  fi
done
