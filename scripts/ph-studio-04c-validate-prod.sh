#!/usr/bin/env bash
set -euo pipefail

API="https://studio-api.keybuzz.io"
FE="https://studio.keybuzz.io"
COOKIE_JAR="/tmp/studio-04c-cookies.txt"
rm -f "$COOKIE_JAR"

echo "=== PH-STUDIO-04C — Validation PROD Complete ==="

echo ""
echo "--- 1. Health check ---"
curl -s -w " [HTTP %{http_code}]" "$API/health"
echo ""

echo ""
echo "--- 2. Setup status ---"
curl -s -w " [HTTP %{http_code}]" "$API/api/v1/auth/setup/status"
echo ""

echo ""
echo "--- 3. Request OTP ---"
OTP_RESP=$(curl -s -w "\n%{http_code}" -X POST "$API/api/v1/auth/request-otp" \
  -H "Content-Type: application/json" \
  -d '{"email":"ludovic@keybuzz.pro"}')
OTP_BODY=$(echo "$OTP_RESP" | head -1)
OTP_CODE=$(echo "$OTP_RESP" | tail -1)
echo "OTP response: $OTP_BODY [HTTP $OTP_CODE]"

echo ""
echo "--- 4. CORS simulation — request-otp ---"
curl -s -o /dev/null -w "  Preflight: HTTP %{http_code}\n" \
  -H "Origin: $FE" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type" \
  -X OPTIONS "$API/api/v1/auth/request-otp"

CORS_POST=$(curl -sv -X POST "$API/api/v1/auth/request-otp" \
  -H "Origin: $FE" \
  -H "Content-Type: application/json" \
  -d '{"email":"ludovic@keybuzz.pro"}' 2>&1)
ACAO=$(echo "$CORS_POST" | grep -i "access-control-allow-origin" | head -1)
echo "  POST ACAO header: $ACAO"

echo ""
echo "--- 5. Frontend pages ---"
for page in / /login /dashboard /knowledge /ideas /content; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${FE}${page}")
  echo "  $page => HTTP $STATUS"
done

echo ""
echo "--- 6. Verify baked URL in browser-served JS ---"
LOGIN_HTML=$(curl -s "$FE/login")
JS_FILES=$(echo "$LOGIN_HTML" | grep -oE '/_next/static/[^"]+\.js' | head -10)
FOUND_URL=""
for js in $JS_FILES; do
  MATCH=$(curl -s "${FE}${js}" | grep -oE 'https://studio-api[a-z\-]*\.keybuzz\.io' | head -1 || echo "")
  if [ -n "$MATCH" ]; then
    FOUND_URL="$MATCH"
    echo "  Baked URL in JS: $MATCH (from $js)"
    break
  fi
done
if [ -z "$FOUND_URL" ]; then
  echo "  Baked URL check: checked SSR, verifying server chunks..."
  PROD_POD=$(kubectl get pods -n keybuzz-studio-prod -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | awk '{print $1}')
  kubectl exec -n keybuzz-studio-prod "$PROD_POD" -- grep -r "studio-api" /app/.next/static/ 2>/dev/null | grep -oE 'https://studio-api[a-z\-]*\.keybuzz\.io' | sort -u
fi

echo ""
echo "--- 7. API Logs (last 20 lines) ---"
API_POD=$(kubectl get pods -n keybuzz-studio-api-prod -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | awk '{print $1}')
kubectl logs --tail=20 -n keybuzz-studio-api-prod "$API_POD" 2>&1 | tail -10

echo ""
echo "=== VALIDATION COMPLETE ==="
