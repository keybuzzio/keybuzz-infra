#!/bin/bash
# PH-SHOPIFY-PROD-APP-SETUP-01 — Verify PROD readiness before promotion
#
# Run this BEFORE promoting the Shopify API build to PROD.
# It checks that all prerequisites are met.

set -euo pipefail

echo "============================================"
echo " Shopify PROD Readiness Check"
echo "============================================"

PASS=0
FAIL=0

check() {
  if [ "$1" = "ok" ]; then
    echo "  [OK] $2"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] $2"
    FAIL=$((FAIL+1))
  fi
}

echo ""
echo "=== 1. Secret keybuzz-shopify in keybuzz-api-prod ==="
if kubectl get secret keybuzz-shopify -n keybuzz-api-prod >/dev/null 2>&1; then
  KEYS=$(kubectl get secret keybuzz-shopify -n keybuzz-api-prod -o jsonpath='{.data}' | python3 -c "import json,sys; d=json.load(sys.stdin); print(' '.join(d.keys()))")
  for KEY in SHOPIFY_CLIENT_ID SHOPIFY_CLIENT_SECRET SHOPIFY_ENCRYPTION_KEY; do
    if echo "$KEYS" | grep -q "$KEY"; then
      check "ok" "$KEY present in secret"
    else
      check "fail" "$KEY MISSING from secret"
    fi
  done
else
  check "fail" "Secret keybuzz-shopify does not exist in keybuzz-api-prod"
fi

echo ""
echo "=== 2. PROD API image includes Shopify code ==="
IMAGE=$(kubectl get deployment keybuzz-api -n keybuzz-api-prod -o jsonpath='{.spec.template.spec.containers[0].image}')
echo "  Current image: $IMAGE"
echo "  (Manual check: image must include Shopify modules)"

echo ""
echo "=== 3. Shopify env vars in PROD deployment ==="
SHOPIFY_ENVS=$(kubectl get deployment keybuzz-api -n keybuzz-api-prod -o json | python3 -c "
import json,sys
d = json.load(sys.stdin)
envs = d['spec']['template']['spec']['containers'][0].get('env', [])
found = [e['name'] for e in envs if 'SHOPIFY' in e.get('name','')]
print(' '.join(found))
")
for VAR in SHOPIFY_REDIRECT_URI SHOPIFY_CLIENT_REDIRECT_URL SHOPIFY_CLIENT_ID SHOPIFY_CLIENT_SECRET SHOPIFY_ENCRYPTION_KEY SHOPIFY_WEBHOOK_URL; do
  if echo "$SHOPIFY_ENVS" | grep -q "$VAR"; then
    check "ok" "$VAR configured in deployment"
  else
    check "fail" "$VAR MISSING from deployment"
  fi
done

echo ""
echo "=== 4. PROD API health ==="
HEALTH=$(curl -s https://api.keybuzz.io/health)
if echo "$HEALTH" | grep -q '"ok"'; then
  check "ok" "API healthy"
else
  check "fail" "API unhealthy: $HEALTH"
fi

echo ""
echo "============================================"
echo " Results: $PASS passed, $FAIL failed"
echo "============================================"

if [ "$FAIL" -gt 0 ]; then
  echo " STATUS: NOT READY — fix failures before promotion"
  exit 1
else
  echo " STATUS: READY FOR PROMOTION"
  exit 0
fi
