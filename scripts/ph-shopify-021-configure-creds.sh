#!/bin/bash
# PH-SHOPIFY-02.1: Configure Shopify credentials via K8s secret
# Following existing pattern: K8s secrets referenced via secretKeyRef
# Credentials are NEVER committed in clear text

set -euo pipefail

NS="keybuzz-api-dev"

echo "=== Step 1: Create K8s secret keybuzz-shopify ==="
# Delete if exists (idempotent)
kubectl delete secret keybuzz-shopify -n "$NS" --ignore-not-found=true

# Create from literals (values passed as script args)
kubectl create secret generic keybuzz-shopify \
  --from-literal=SHOPIFY_CLIENT_ID="$1" \
  --from-literal=SHOPIFY_CLIENT_SECRET="$2" \
  --from-literal=SHOPIFY_ENCRYPTION_KEY="$3" \
  -n "$NS"

echo "Secret created."

echo ""
echo "=== Step 2: Verify secret ==="
kubectl get secret keybuzz-shopify -n "$NS" -o jsonpath='{.data}' | python3 -c "
import sys, json, base64
d = json.load(sys.stdin)
for k in sorted(d.keys()):
    v = base64.b64decode(d[k]).decode()
    print(f'  {k}: {v[:8]}***{v[-4:]} (len={len(v)})')
"

echo ""
echo "=== Step 3: Patch deployment to use secretKeyRef ==="
# Remove old plain-value env vars and add secretKeyRef versions
POD_BEFORE=$(kubectl get pods -n "$NS" -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}')

# Use kubectl patch to replace the env var sources
kubectl set env deployment/keybuzz-api -n "$NS" \
  SHOPIFY_CLIENT_ID- \
  SHOPIFY_CLIENT_SECRET- \
  SHOPIFY_ENCRYPTION_KEY-

# Now add them back from the secret
kubectl patch deployment keybuzz-api -n "$NS" --type='json' -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/env/-","value":{"name":"SHOPIFY_CLIENT_ID","valueFrom":{"secretKeyRef":{"name":"keybuzz-shopify","key":"SHOPIFY_CLIENT_ID"}}}},
  {"op":"add","path":"/spec/template/spec/containers/0/env/-","value":{"name":"SHOPIFY_CLIENT_SECRET","valueFrom":{"secretKeyRef":{"name":"keybuzz-shopify","key":"SHOPIFY_CLIENT_SECRET"}}}},
  {"op":"add","path":"/spec/template/spec/containers/0/env/-","value":{"name":"SHOPIFY_ENCRYPTION_KEY","valueFrom":{"secretKeyRef":{"name":"keybuzz-shopify","key":"SHOPIFY_ENCRYPTION_KEY"}}}}
]'

echo "Deployment patched."

echo ""
echo "=== Step 4: Wait for rollout ==="
kubectl rollout status deployment/keybuzz-api -n "$NS" --timeout=90s

echo ""
echo "=== Step 5: Verify env in new pod ==="
NEW_POD=$(kubectl get pods -n "$NS" -l app=keybuzz-api --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
echo "New pod: $NEW_POD"
kubectl exec -n "$NS" "$NEW_POD" -- env | grep SHOPIFY | sort | while read line; do
  KEY=$(echo "$line" | cut -d= -f1)
  VAL=$(echo "$line" | cut -d= -f2-)
  if [ ${#VAL} -gt 12 ]; then
    echo "  $KEY=${VAL:0:8}***${VAL: -4} (len=${#VAL})"
  else
    echo "  $KEY=$VAL"
  fi
done

echo ""
echo "=== Step 6: Test Shopify connect endpoint ==="
kubectl exec -n "$NS" "$NEW_POD" -- curl -s -X POST 'http://127.0.0.1:3001/shopify/connect' \
  -H 'Content-Type: application/json' \
  -H 'X-User-Email: ludo.gonthier@gmail.com' \
  -H 'X-Tenant-Id: ecomlg-001' \
  -d '{"shopDomain":"keybuzz-dev.myshopify.com"}'

echo ""
echo ""
echo "=== DONE ==="
