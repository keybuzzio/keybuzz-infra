#!/usr/bin/env bash
set -euo pipefail

echo "=== PH-STUDIO-04C — Diagnostic ==="

echo ""
echo "--- 1. Check baked API URL in PROD frontend JS ---"
curl -s https://studio.keybuzz.io/login > /tmp/prod-login.html
echo "HTML fetched: $(wc -c < /tmp/prod-login.html) bytes"

JS_URLS=$(grep -oE 'https://studio-api[a-z\-]*\.keybuzz\.io' /tmp/prod-login.html || echo "NOT_IN_HTML")
echo "API URLs in HTML: $JS_URLS"

SCRIPT_SRCS=$(grep -oE '/_next/static/[^"]+\.js' /tmp/prod-login.html | head -5)
echo "JS bundles found: $(echo "$SCRIPT_SRCS" | wc -l)"

for js in $SCRIPT_SRCS; do
  CONTENT=$(curl -s "https://studio.keybuzz.io${js}")
  FOUND=$(echo "$CONTENT" | grep -oE 'https://studio-api[a-z\-]*\.keybuzz\.io' | head -1 || echo "")
  if [ -n "$FOUND" ]; then
    echo "  FOUND in $js: $FOUND"
  fi
done

echo ""
echo "--- 2. Check PROD API CORS from browser perspective ---"
CORS_RESP=$(curl -sv -o /dev/null -H "Origin: https://studio.keybuzz.io" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type" \
  -X OPTIONS https://studio-api.keybuzz.io/api/v1/auth/request-otp 2>&1)
echo "$CORS_RESP" | grep -iE 'access-control|HTTP/' || echo "No CORS headers"

echo ""
echo "--- 3. Check DEV API CORS for PROD origin ---"
DEV_CORS=$(curl -sv -o /dev/null -H "Origin: https://studio.keybuzz.io" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type" \
  -X OPTIONS https://studio-api-dev.keybuzz.io/api/v1/auth/request-otp 2>&1)
echo "$DEV_CORS" | grep -iE 'access-control|HTTP/' || echo "No CORS headers"

echo ""
echo "--- 4. Direct POST to PROD API (no CORS) ---"
curl -s -w "\nHTTP: %{http_code}\n" -X POST \
  https://studio-api.keybuzz.io/api/v1/auth/request-otp \
  -H "Content-Type: application/json" \
  -d '{"email":"ludovic@keybuzz.pro"}'

echo ""
echo "--- 5. Check PROD container JS for baked URL ---"
PROD_POD=$(kubectl get pods -n keybuzz-studio-prod -o jsonpath='{.items[0].metadata.name}')
echo "PROD pod: $PROD_POD"
kubectl exec -n keybuzz-studio-prod "$PROD_POD" -- find /app/.next -name "*.js" -exec grep -l "studio-api" {} \; 2>/dev/null | head -5 || echo "find failed"
kubectl exec -n keybuzz-studio-prod "$PROD_POD" -- grep -r "studio-api" /app/.next/static/ 2>/dev/null | grep -oE 'https://studio-api[a-z\-]*\.keybuzz\.io' | sort -u || echo "grep in container failed"

echo ""
echo "=== DIAGNOSTIC COMPLETE ==="
