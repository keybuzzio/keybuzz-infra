#!/bin/bash
set -uo pipefail

###############################################################################
# Frontend Runtime Gate — KeyBuzz v3
# Usage: bash frontend-runtime-gate.sh <env>
#   env: dev | prod
#
# Validates that the currently deployed client is healthy at runtime.
# Exit 0 = RUNTIME OK
# Exit 1 = RUNTIME ISSUES DETECTED
###############################################################################

ENV="${1:-}"
PASS_COUNT=0
FAIL_COUNT=0
RESULTS=()

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

check_pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  RESULTS+=("PASS|$1")
  echo -e "  ${GREEN}✓ PASS${NC} $1"
}

check_fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  RESULTS+=("FAIL|$1")
  echo -e "  ${RED}✗ FAIL${NC} $1"
}

if [ -z "$ENV" ]; then
  echo "Usage: $0 <dev|prod>"
  exit 1
fi

case "$ENV" in
  dev)  NS_CLIENT="keybuzz-client-dev"; NS_API="keybuzz-api-dev" ;;
  prod) NS_CLIENT="keybuzz-client-prod"; NS_API="keybuzz-api-prod" ;;
  *)    echo "ERROR: env must be 'dev' or 'prod'"; exit 1 ;;
esac

echo "============================================================"
echo " FRONTEND RUNTIME GATE — KeyBuzz v3"
echo " Environment: $ENV"
echo " Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "============================================================"
echo ""

###############################################################################
# SECTION A — Pod health
###############################################################################
echo "--- A. POD HEALTH ---"

CLIENT_POD=$(kubectl get pods -n "$NS_CLIENT" -l app=keybuzz-client --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "$CLIENT_POD" ]; then
  check_pass "Client pod running: $CLIENT_POD"
else
  check_fail "No running client pod found in $NS_CLIENT"
fi

CLIENT_IMAGE=$(kubectl get deploy keybuzz-client -n "$NS_CLIENT" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
echo "  Image: $CLIENT_IMAGE"

RESTART_COUNT=$(kubectl get pods -n "$NS_CLIENT" -l app=keybuzz-client -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}' 2>/dev/null || echo "0")
if [ "$RESTART_COUNT" -le 2 ]; then
  check_pass "Restart count acceptable: $RESTART_COUNT"
else
  check_fail "Restart count too high: $RESTART_COUNT"
fi

###############################################################################
# SECTION B — Route accessibility (single kubectl exec, batch check)
###############################################################################
echo ""
echo "--- B. ROUTE ACCESSIBILITY ---"

if [ -n "$CLIENT_POD" ]; then
  ROUTE_RESULTS=$(kubectl exec "$CLIENT_POD" -n "$NS_CLIENT" -- node -e "
const http = require('http');
const routes = ['/login','/signup','/pricing','/onboarding','/locked','/dashboard','/inbox','/channels','/billing'];
let done = 0;
routes.forEach(r => {
  const req = http.request({hostname:'127.0.0.1',port:3000,path:r,method:'GET',timeout:5000}, res => {
    res.resume();
    console.log(r + ':' + res.statusCode);
    if (++done === routes.length) process.exit(0);
  });
  req.on('error', () => { console.log(r + ':ERR'); if (++done === routes.length) process.exit(0); });
  req.on('timeout', () => { req.destroy(); console.log(r + ':TIMEOUT'); if (++done === routes.length) process.exit(0); });
  req.end();
});
setTimeout(() => { console.log('GLOBAL_TIMEOUT'); process.exit(1); }, 30000);
" 2>/dev/null || echo "EXEC_FAIL")

  for ROUTE in /login /signup /pricing /onboarding /locked /dashboard /inbox /channels /billing; do
    STATUS=$(echo "$ROUTE_RESULTS" | grep "^${ROUTE}:" | cut -d: -f2 || true)
    if [ "$STATUS" = "200" ] || [ "$STATUS" = "307" ] || [ "$STATUS" = "302" ] || [ "$STATUS" = "308" ]; then
      check_pass "Route $ROUTE accessible (HTTP $STATUS)"
    elif [ -z "$STATUS" ] || [ "$STATUS" = "ERR" ] || [ "$STATUS" = "TIMEOUT" ]; then
      check_fail "Route $ROUTE unreachable ($STATUS)"
    else
      check_fail "Route $ROUTE returned HTTP $STATUS"
    fi
  done
else
  for ROUTE in /login /signup /pricing /onboarding /locked /dashboard /inbox /channels /billing; do
    check_fail "Route $ROUTE not testable (no pod)"
  done
fi

###############################################################################
# SECTION C — API health
###############################################################################
echo ""
echo "--- C. API HEALTH ---"

API_POD=$(kubectl get pods -n "$NS_API" -l app=keybuzz-api --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "$API_POD" ]; then
  API_HEALTH=$(kubectl exec "$API_POD" -n "$NS_API" -- node -e "
const http=require('http');
[3001,80,3000].forEach(p=>{
  const r=http.get('http://localhost:'+p+'/health',res=>{
    let d='';res.on('data',c=>d+=c);res.on('end',()=>console.log(p+':'+res.statusCode));
  });
  r.on('error',()=>{});
  r.setTimeout(3000,()=>{r.destroy()});
});
setTimeout(()=>process.exit(0),5000);
" 2>/dev/null || echo "none")

  if echo "$API_HEALTH" | grep -q ":200"; then
    check_pass "API /health reachable"
  else
    check_fail "API /health not reachable"
  fi
else
  check_fail "No running API pod in $NS_API"
fi

###############################################################################
# VERDICT
###############################################################################
echo ""
echo "============================================================"
echo " RUNTIME GATE VERDICT"
echo "============================================================"
echo ""
echo "  Environment:  $ENV"
echo "  Client pod:   ${CLIENT_POD:-none}"
echo "  Client image: ${CLIENT_IMAGE:-unknown}"
echo "  Total checks: $((PASS_COUNT + FAIL_COUNT))"
echo -e "  Passed:       ${GREEN}$PASS_COUNT${NC}"
if [ "$FAIL_COUNT" -gt 0 ]; then
  echo -e "  Failed:       ${RED}$FAIL_COUNT${NC}"
  echo ""
  echo "  Failed checks:"
  for R in "${RESULTS[@]}"; do
    if echo "$R" | grep -q "^FAIL"; then
      echo -e "    ${RED}✗${NC} $(echo "$R" | cut -d'|' -f2)"
    fi
  done
else
  echo -e "  Failed:       ${GREEN}0${NC}"
fi

echo ""
if [ "$FAIL_COUNT" -eq 0 ]; then
  echo -e "${GREEN}  RUNTIME: HEALTHY${NC}"
  exit 0
else
  echo -e "${RED}  RUNTIME: ISSUES DETECTED ($FAIL_COUNT failures)${NC}"
  exit 1
fi
