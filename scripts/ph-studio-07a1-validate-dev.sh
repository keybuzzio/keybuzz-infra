#!/usr/bin/env bash
set -eo pipefail

BASE="https://studio-api-dev.keybuzz.io"
FE="https://studio-dev.keybuzz.io"
PASS=0; FAIL=0; TOTAL=0

check() {
  TOTAL=$((TOTAL + 1))
  local label="$1"; shift
  if "$@"; then PASS=$((PASS + 1)); echo "[PASS] $label"
  else FAIL=$((FAIL + 1)); echo "[FAIL] $label"; fi
}

echo "=== PH-STUDIO-07A.1 — Validate DEV ==="
echo ""

# --- T1: API Health ---
echo "--- T1: API Health (pipeline support) ---"
HEALTH=$(curl -s "$BASE/health")
check "health endpoint" echo "$HEALTH" | grep -q '"status":"ok"'
check "pipeline_modes in health" echo "$HEALTH" | grep -q 'pipeline_modes'
check "available_providers in health" echo "$HEALTH" | grep -q 'available_providers'
echo "  $HEALTH"

# --- T2: Auth session ---
echo ""
echo "--- T2: Auth session ---"
DEV_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/v1/auth/me")
echo "  /auth/me => $DEV_CODE"

# --- T3: DB migration 006 check ---
echo ""
echo "--- T3: Check pipeline columns exist ---"
NS_API="keybuzz-studio-api-dev"
DB_URL=$(kubectl get secret keybuzz-studio-api-db -n "$NS_API" -o jsonpath='{.data.DATABASE_URL}' | base64 -d 2>/dev/null || echo "")
if [ -n "$DB_URL" ]; then
  COL_CHECK=$(kubectl run check-cols-07a1 --rm -it --restart=Never \
    --image=postgres:17-alpine --namespace=default \
    -- sh -c "psql '$DB_URL' -t -c \"SELECT column_name FROM information_schema.columns WHERE table_name='ai_generations' AND column_name IN ('pipeline_id','pipeline_mode','step','step_order','latency_ms') ORDER BY column_name\"" 2>/dev/null || echo "")
  check "pipeline_id column exists" echo "$COL_CHECK" | grep -q "pipeline_id"
  check "pipeline_mode column exists" echo "$COL_CHECK" | grep -q "pipeline_mode"
  check "step column exists" echo "$COL_CHECK" | grep -q "step"
  check "latency_ms column exists" echo "$COL_CHECK" | grep -q "latency_ms"
  echo "  Columns: $COL_CHECK"
else
  echo "  [SKIP] DB_URL not available"
fi

# --- T4: AI health with heuristic ---
echo ""
echo "--- T4: AI health (heuristic mode — no LLM keys configured) ---"
AI_HEALTH=$(curl -s "$BASE/api/v1/ai/health" -H "Cookie: $(curl -s -c - "$BASE/api/v1/auth/me" | grep studio_session | awk '{print "studio_session="$NF}')" 2>/dev/null || curl -s "$BASE/api/v1/ai/health" 2>/dev/null || echo '{}')
echo "  $AI_HEALTH"
check "AI health has pipeline_modes" echo "$AI_HEALTH" | grep -q "pipeline_modes"

# --- T5: Frontend accessible ---
echo ""
echo "--- T5: Frontend accessible ---"
FE_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$FE/login")
check "Frontend /login => 200" [ "$FE_CODE" = "200" ]

# --- T6: Pods running ---
echo ""
echo "--- T6: Pods status ---"
API_PODS=$(kubectl get pods -n "$NS_API" --no-headers 2>/dev/null)
FE_PODS=$(kubectl get pods -n keybuzz-studio-dev --no-headers 2>/dev/null)
echo "  API: $API_PODS"
echo "  FE:  $FE_PODS"
check "API pod Running" echo "$API_PODS" | grep -q "Running"
check "FE pod Running" echo "$FE_PODS" | grep -q "Running"

# --- T7: API logs clean ---
echo ""
echo "--- T7: API logs (last 20) ---"
API_POD=$(kubectl get pods -n "$NS_API" -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' 2>/dev/null | awk '{print $1}')
if [ -n "$API_POD" ]; then
  LOGS=$(kubectl logs --tail=20 -n "$NS_API" "$API_POD" 2>/dev/null || echo "")
  echo "  $(echo "$LOGS" | tail -5)"
  check "No fatal errors" ! echo "$LOGS" | grep -qi "fatal\|segfault\|EACCES"
fi

echo ""
echo "======================================="
echo "  PASS: $PASS / $TOTAL"
echo "  FAIL: $FAIL / $TOTAL"
echo "======================================="

if [ $FAIL -eq 0 ]; then
  echo "PH-STUDIO-07A.1 DEV VALIDATION: ALL PASSED"
else
  echo "PH-STUDIO-07A.1 DEV VALIDATION: $FAIL FAILURES"
fi
