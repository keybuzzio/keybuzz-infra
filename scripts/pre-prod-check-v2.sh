#!/bin/bash
# PH142-M — Pre-PROD Safety Check V2
# Obligatoire avant chaque push PROD
# Ajoute: checks Git + checks feature-level backend
# Usage: bash pre-prod-check-v2.sh [dev|prod]

set -euo pipefail

ENV="${1:-dev}"
PASS=0
FAIL=0
TOTAL=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$ENV" = "prod" ]; then
  API_NS="keybuzz-api-prod"
  CLIENT_NS="keybuzz-client-prod"
  CLIENT_URL="https://client.keybuzz.io"
  API_URL="https://api.keybuzz.io"
else
  API_NS="keybuzz-api-dev"
  CLIENT_NS="keybuzz-client-dev"
  CLIENT_URL="https://client-dev.keybuzz.io"
  API_URL="https://api-dev.keybuzz.io"
fi

POD=$(kubectl get pods -n "$API_NS" -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
CLIENT_POD=$(kubectl get pods -n "$CLIENT_NS" -l app=keybuzz-client -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

check() {
  local name="$1"
  local result="$2"
  TOTAL=$((TOTAL + 1))
  if [ "$result" = "OK" ]; then
    PASS=$((PASS + 1))
    printf "  %-4s %-50s\n" "[OK]" "$name"
  else
    FAIL=$((FAIL + 1))
    printf "  %-6s %-48s %s\n" "[FAIL]" "$name" "$result"
  fi
}

echo ""
echo "============================================"
echo "  PRE-PROD SAFETY CHECK V2 — $ENV"
echo "  PH142-M"
echo "============================================"

# ===== SECTION A: GIT CHECKS =====
echo ""
echo "--- A. Git Source of Truth ---"

for REPO in /opt/keybuzz/keybuzz-client /opt/keybuzz/keybuzz-api; do
  REPO_NAME=$(basename "$REPO")
  cd "$REPO"
  DIRTY=$(git status --porcelain -- ':!*.bak*' ':!dist/' ':!node_modules/' ':!.next/' 2>/dev/null | { grep -v '^\s*$' || true; } | wc -l)
  if [ "$DIRTY" -eq 0 ]; then
    check "Git clean: $REPO_NAME" "OK"
  else
    check "Git clean: $REPO_NAME" "$DIRTY fichiers non commites"
  fi
done

# ===== SECTION B: EXTERNAL HEALTH =====
echo ""
echo "--- B. External Health ---"

API_HEALTH=$(curl -s --max-time 5 "$API_URL/health" 2>/dev/null || echo "TIMEOUT")
if echo "$API_HEALTH" | grep -q '"ok"'; then
  check "API health ($API_URL)" "OK"
else
  check "API health ($API_URL)" "$API_HEALTH"
fi

CLIENT_HTTP=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$CLIENT_URL" 2>/dev/null || echo "000")
if [ "$CLIENT_HTTP" = "200" ] || [ "$CLIENT_HTTP" = "307" ]; then
  check "Client health ($CLIENT_URL)" "OK"
else
  check "Client health ($CLIENT_URL)" "HTTP $CLIENT_HTTP"
fi

# ===== SECTION C: API INTERNAL CHECKS =====
echo ""
echo "--- C. API Internal (kubectl exec) ---"

if [ -z "$POD" ]; then
  check "API pod found in $API_NS" "NO POD"
else
  kubectl cp "$SCRIPT_DIR/pre-prod-checks-v2.js" "$API_NS/$POD:/app/pre-prod-checks-v2.js" 2>/dev/null
  RESULTS=$(kubectl exec -n "$API_NS" "$POD" -- node /app/pre-prod-checks-v2.js 2>/dev/null || echo '{"error":"exec failed"}')
  kubectl exec -n "$API_NS" "$POD" -- rm -f /app/pre-prod-checks-v2.js 2>/dev/null || true

  if echo "$RESULTS" | grep -q '"error"\|"timeout"'; then
    check "Internal checks (kubectl exec)" "EXEC FAILED"
  else
    for KEY in inbox_api dashboard_api ai_settings ai_journal autopilot_draft signature_db orders_count channels_count billing_current agent_keybuzz_status db_addon_column addon_api_structure billing_addon_field agents_api signature_api; do
      LABEL=""
      case $KEY in
        inbox_api)            LABEL="Inbox API endpoint" ;;
        dashboard_api)        LABEL="Dashboard API endpoint" ;;
        ai_settings)          LABEL="AI Settings endpoint" ;;
        ai_journal)           LABEL="AI Journal endpoint" ;;
        autopilot_draft)      LABEL="Autopilot draft endpoint" ;;
        signature_db)         LABEL="Signature config in DB" ;;
        orders_count)         LABEL="Orders count > 0" ;;
        channels_count)       LABEL="Channels count > 0" ;;
        billing_current)      LABEL="Billing current endpoint" ;;
        agent_keybuzz_status) LABEL="Agent KeyBuzz status API" ;;
        db_addon_column)      LABEL="DB has_agent_keybuzz_addon col" ;;
        addon_api_structure)  LABEL="Addon API structure valid" ;;
        billing_addon_field)  LABEL="billing/current hasAddon field" ;;
        agents_api)           LABEL="Agents API endpoint" ;;
        signature_api)        LABEL="Signature API endpoint" ;;
        agents_table)         LABEL="Agents table accessible" ;;
      esac
      [ -z "$LABEL" ] && continue
      IS_OK=$(echo "$RESULTS" | python3 -c "import sys,json; d=json.load(sys.stdin); r=d.get('$KEY',{}); print('OK' if r.get('ok') else r.get('detail','FAIL'))" 2>/dev/null || echo "PARSE_ERROR")
      check "$LABEL" "$IS_OK"
    done
  fi
fi

# ===== SECTION D: CLIENT COMPILED ROUTES =====
echo ""
echo "--- D. Client Compiled Routes ---"

if [ -z "$CLIENT_POD" ]; then
  check "Client pod found in $CLIENT_NS" "NO POD"
else
  for PAIR in \
    "billing_plan_page:/app/.next/server/app/billing/plan/page.js" \
    "billing_ai_page:/app/.next/server/app/billing/ai" \
    "settings_page:/app/.next/server/app/settings" \
    "dashboard_page:/app/.next/server/app/dashboard/page.js" \
    "inbox_page:/app/.next/server/app/inbox/page.js" \
    "orders_page:/app/.next/server/app/orders/page.js"; do
    
    NAME=$(echo "$PAIR" | cut -d: -f1)
    FPATH=$(echo "$PAIR" | cut -d: -f2-)
    
    EXISTS=$(kubectl exec -n "$CLIENT_NS" "$CLIENT_POD" -- sh -c "[ -e $FPATH ] && echo yes || echo no" 2>/dev/null || echo "no")
    if [ "$EXISTS" = "yes" ]; then
      check "Route: $NAME compiled" "OK"
    else
      check "Route: $NAME compiled" "MISSING $FPATH"
    fi
  done
fi

# ===== SUMMARY =====
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
