#!/bin/bash
# PH142-I — Pre-PROD Safety Check
# Obligatoire avant chaque push PROD
# Usage: bash /opt/keybuzz/keybuzz-infra/scripts/pre-prod-check.sh [dev|prod]

set -euo pipefail

ENV="${1:-dev}"
PASS=0
FAIL=0
TOTAL=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$ENV" = "prod" ]; then
  API_NS="keybuzz-api-prod"
  CLIENT_URL="https://client.keybuzz.io"
  API_URL="https://api.keybuzz.io"
else
  API_NS="keybuzz-api-dev"
  CLIENT_URL="https://client-dev.keybuzz.io"
  API_URL="https://api-dev.keybuzz.io"
fi

POD=$(kubectl get pods -n "$API_NS" -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

check() {
  local name="$1"
  local result="$2"
  TOTAL=$((TOTAL + 1))
  if [ "$result" = "OK" ]; then
    PASS=$((PASS + 1))
    printf "  %-4s %-45s\n" "[OK]" "$name"
  else
    FAIL=$((FAIL + 1))
    printf "  %-6s %-43s %s\n" "[FAIL]" "$name" "$result"
  fi
}

echo ""
echo "============================================"
echo "  PRE-PROD SAFETY CHECK — $ENV"
echo "============================================"
echo ""

# --- 1. API health ---
API_HEALTH=$(curl -s --max-time 5 "$API_URL/health" 2>/dev/null || echo "TIMEOUT")
if echo "$API_HEALTH" | grep -q '"ok"'; then
  check "API health ($API_URL)" "OK"
else
  check "API health ($API_URL)" "$API_HEALTH"
fi

# --- 2. Client health ---
CLIENT_HTTP=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$CLIENT_URL" 2>/dev/null || echo "000")
if [ "$CLIENT_HTTP" = "200" ]; then
  check "Client health ($CLIENT_URL)" "OK"
else
  check "Client health ($CLIENT_URL)" "HTTP $CLIENT_HTTP"
fi

# --- 3-10. Internal checks via kubectl exec ---
if [ -z "$POD" ]; then
  check "API pod found in $API_NS" "NO POD"
  echo ""
  echo "  RESULT: $PASS/$TOTAL passed, $FAIL failed"
  exit 1
fi

kubectl cp "$SCRIPT_DIR/pre-prod-checks.js" "$API_NS/$POD:/app/pre-prod-checks.js" 2>/dev/null
RESULTS=$(kubectl exec -n "$API_NS" "$POD" -- node /app/pre-prod-checks.js 2>/dev/null || echo '{"error":"exec failed"}')
kubectl exec -n "$API_NS" "$POD" -- rm -f /app/pre-prod-checks.js 2>/dev/null || true

if echo "$RESULTS" | grep -q '"error"\|"timeout"'; then
  check "Internal checks (kubectl exec)" "EXEC FAILED"
else
  for KEY in inbox_api dashboard_api ai_settings ai_journal autopilot_draft signature_db orders_count channels_count; do
    LABEL=""
    case $KEY in
      inbox_api)       LABEL="Inbox API endpoint" ;;
      dashboard_api)   LABEL="Dashboard API endpoint" ;;
      ai_settings)     LABEL="AI Settings endpoint" ;;
      ai_journal)      LABEL="AI Journal endpoint" ;;
      autopilot_draft) LABEL="Autopilot draft endpoint" ;;
      signature_db)    LABEL="Signature config in DB" ;;
      orders_count)    LABEL="Orders count > 0" ;;
      channels_count)  LABEL="Channels count > 0" ;;
    esac
    IS_OK=$(echo "$RESULTS" | python3 -c "import sys,json; d=json.load(sys.stdin); r=d.get('$KEY',{}); print('OK' if r.get('ok') else r.get('detail','FAIL'))" 2>/dev/null || echo "PARSE_ERROR")
    check "$LABEL" "$IS_OK"
  done
fi

echo ""
echo "============================================"
if [ "$FAIL" -gt 0 ]; then
  echo "  RESULT: $PASS/$TOTAL passed, $FAIL FAILED"
  echo "  >>> PROD PUSH BLOCKED <<<"
  echo "============================================"
  echo ""
  exit 1
else
  echo "  RESULT: $PASS/$TOTAL passed — ALL GREEN"
  echo "  >>> PROD PUSH AUTHORIZED <<<"
  echo "============================================"
  echo ""
  exit 0
fi
