#!/bin/bash
set -euo pipefail

# ============================================================
# PH-TD-08 — Verify Image Before Push
# Non-regression gate: checks that critical features EXIST
# and that no URL contamination is present
# ============================================================

IMAGE="${1:-}"
EXPECTED_ENV="${2:-}"

if [ -z "$IMAGE" ] || [ -z "$EXPECTED_ENV" ]; then
  echo "Usage: $0 <image> <dev|prod>"
  exit 1
fi

echo "=== PH-TD-08 Image Verification ==="
echo "Image: $IMAGE"
echo "Expected env: $EXPECTED_ENV"
echo ""

PASS=0
FAIL=0
WARN=0

check() {
  local name="$1"
  local result="$2"
  local expected="$3"

  if [ "$result" = "$expected" ]; then
    echo "  PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $name (got=$result, expected=$expected)"
    FAIL=$((FAIL + 1))
  fi
}

warn_check() {
  local name="$1"
  local result="$2"
  local expected="$3"

  if [ "$result" = "$expected" ]; then
    echo "  PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "  WARN: $name (got=$result, expected=$expected)"
    WARN=$((WARN + 1))
  fi
}

node_check() {
  local script="$1"
  docker run --rm --entrypoint node "$IMAGE" -e "$script" 2>/dev/null || echo "CHECK_FAILED"
}

# ============================================================
# SECTION 1: Critical pages (non-regression)
# ============================================================
echo "--- Critical pages ---"

CRITICAL_PAGES=(
  "inbox"
  "dashboard"
  "channels"
  "settings"
  "billing"
  "login"
  "register"
  "locked"
  "onboarding"
  "orders"
)

for PAGE in "${CRITICAL_PAGES[@]}"; do
  RES=$(node_check "
const fs=require('fs');
const p1 = fs.existsSync('/app/.next/server/app/$PAGE');
const p2 = fs.existsSync('/app/.next/server/app/$PAGE/page.js');
console.log((p1||p2) ? 'OK' : 'MISSING');
")
  check "/$PAGE page" "$RES" "OK"
done

# ============================================================
# SECTION 2: Signup redirect verification
# ============================================================
echo ""
echo "--- Signup page non-regression ---"

RES=$(node_check "
const fs=require('fs');
const p = '/app/.next/server/app/signup/page.js';
if (!fs.existsSync(p)) { console.log('MISSING'); process.exit(); }
const c = fs.readFileSync(p,'utf8');
const hasFullForm = c.includes('create-signup') || c.includes('Inscription');
const hasRedirect = c.includes('register') || c.length < 3000;
if (hasFullForm) console.log('BYPASS_RISK');
else if (hasRedirect) console.log('OK');
else console.log('UNKNOWN');
")
check "/signup is redirect (not full form)" "$RES" "OK"

# ============================================================
# SECTION 3: Page size sanity check
# ============================================================
echo ""
echo "--- Page size sanity ---"

for PAGE in "inbox" "dashboard" "settings"; do
  RES=$(node_check "
const fs=require('fs');
const p = '/app/.next/server/app/$PAGE/page.js';
if (!fs.existsSync(p)) { console.log('MISSING'); process.exit(); }
const s = fs.statSync(p).size;
console.log(s > 500 ? 'OK' : 'SUSPICIOUSLY_SMALL');
")
  check "/$PAGE page size > 500 bytes" "$RES" "OK"
done

# ============================================================
# SECTION 4: URL contamination
# ============================================================
echo ""
echo "--- URL contamination ---"

if [ "$EXPECTED_ENV" = "dev" ]; then
  FORBIDDEN="api.keybuzz.io"
  EXPECTED_URL="api-dev.keybuzz.io"
else
  FORBIDDEN="api-dev.keybuzz.io"
  EXPECTED_URL="api.keybuzz.io"
fi

RES=$(node_check "
const fs=require('fs'), path=require('path');
try {
  const dir = '/app/.next/static/chunks';
  const files = fs.readdirSync(dir).filter(f => f.endsWith('.js'));
  let bad = 0;
  for (const f of files) {
    const c = fs.readFileSync(path.join(dir, f), 'utf8');
    if (c.includes('$FORBIDDEN') && !'$FORBIDDEN'.startsWith('api-') && !c.includes('api-dev')) bad++;
    if ('$EXPECTED_ENV' === 'prod' && c.includes('api-dev.keybuzz.io')) bad++;
  }
  console.log(bad === 0 ? 'CLEAN' : 'CONTAMINATED');
} catch(e) { console.log('CHECK_FAILED'); }
")
check "No wrong API URL ($FORBIDDEN absent)" "$RES" "CLEAN"

RES=$(node_check "
const fs=require('fs'), path=require('path');
try {
  const dir = '/app/.next/static/chunks';
  const files = fs.readdirSync(dir).filter(f => f.endsWith('.js'));
  let found = false;
  for (const f of files) {
    const c = fs.readFileSync(path.join(dir, f), 'utf8');
    if (c.includes('$EXPECTED_URL')) { found = true; break; }
  }
  console.log(found ? 'FOUND' : 'NOT_FOUND');
} catch(e) { console.log('CHECK_FAILED'); }
")
check "Correct API URL present ($EXPECTED_URL)" "$RES" "FOUND"

# ============================================================
# SECTION 5: Routes manifest completeness
# ============================================================
echo ""
echo "--- Routes manifest ---"

RES=$(node_check "
const fs=require('fs');
const p = '/app/.next/app-path-routes-manifest.json';
if (!fs.existsSync(p)) { console.log('MISSING'); process.exit(); }
const m = JSON.parse(fs.readFileSync(p,'utf8'));
const routes = Object.values(m);
const required = ['/inbox','/dashboard','/channels','/settings','/billing','/login','/register','/locked'];
const missing = required.filter(r => !routes.includes(r));
console.log(missing.length === 0 ? 'COMPLETE' : 'MISSING:'+missing.join(','));
")
check "Routes manifest complete" "${RES%%:*}" "COMPLETE"

# ============================================================
# RESULTS
# ============================================================
echo ""
echo "=== RESULTATS: $PASS PASS / $FAIL FAIL / $WARN WARN ==="
if [ $FAIL -gt 0 ]; then
  echo "VERDICT: FAIL — NE PAS PUSHER NI DEPLOYER"
  exit 1
else
  echo "VERDICT: PASS — Image valide"
  echo ""
  echo "Prochaine etape :"
  echo "  docker push $IMAGE"
fi
