#!/bin/bash
NS=keybuzz-studio-api-prod

echo "=== SECRETS ==="
kubectl get secrets -n $NS --no-headers | awk '{print $1}'

echo ""
echo "=== DB SECRET KEYS ==="
for s in keybuzz-studio-api-db keybuzz-studio-db studio-db database; do
  echo "--- $s ---"
  keys=$(kubectl get secret "$s" -n $NS -o json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(','.join(d.get('data',{}).keys()))" 2>/dev/null)
  if [ -n "$keys" ]; then
    echo "Keys: $keys"
  else
    echo "not found"
  fi
done

echo ""
echo "=== ENV VARS IN API POD ==="
kubectl exec -n $NS deploy/keybuzz-studio-api -- env 2>/dev/null | grep -i "db\|database\|postgres\|pg" | head -10
