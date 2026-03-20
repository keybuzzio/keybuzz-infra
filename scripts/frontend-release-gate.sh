#!/bin/bash
set -euo pipefail

# ============================================================
# PH-TD-08 — Frontend Release Gate
# Final gate before PROD promotion
# Must pass BEFORE any deploy to PROD
# ============================================================

IMAGE="${1:-}"

if [ -z "$IMAGE" ]; then
  echo "Usage: $0 <image>"
  echo "Example: $0 ghcr.io/keybuzzio/keybuzz-client:v3.5.61-feature-prod"
  exit 1
fi

if [[ "$IMAGE" != *"-prod" ]]; then
  echo "BLOQUE : le release gate est reserve aux images PROD (-prod)"
  exit 1
fi

echo "=== PH-TD-08 Frontend Release Gate ==="
echo "Image: $IMAGE"
echo ""

PASS=0
FAIL=0

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

node_check() {
  docker run --rm --entrypoint node "$IMAGE" -e "$1" 2>/dev/null || echo "CHECK_FAILED"
}

# ============================================================
# CHECK 1: No DEV URLs in PROD build
# ============================================================
echo "--- URL Safety ---"

RES=$(node_check "
const fs=require('fs'), path=require('path');
const dir = '/app/.next/static/chunks';
const files = fs.readdirSync(dir).filter(f => f.endsWith('.js'));
let bad = 0;
for (const f of files) {
  const c = fs.readFileSync(path.join(dir, f), 'utf8');
  if (c.includes('api-dev.keybuzz.io')) bad++;
  if (c.includes('client-dev.keybuzz.io')) bad++;
}
console.log(bad === 0 ? 'CLEAN' : 'CONTAMINATED');
")
check "No DEV URLs in PROD" "$RES" "CLEAN"

RES=$(node_check "
const fs=require('fs'), path=require('path');
const dir = '/app/.next/static/chunks';
const files = fs.readdirSync(dir).filter(f => f.endsWith('.js'));
let found = false;
for (const f of files) {
  const c = fs.readFileSync(path.join(dir, f), 'utf8');
  if (c.includes('api.keybuzz.io') && !c.includes('api-dev.keybuzz.io')) { found = true; break; }
}
console.log(found ? 'FOUND' : 'NOT_FOUND');
")
check "PROD API URL present" "$RES" "FOUND"

# ============================================================
# CHECK 2: Critical pages exist
# ============================================================
echo ""
echo "--- Critical Pages ---"

for PAGE in inbox dashboard channels settings billing login register locked onboarding orders; do
  RES=$(node_check "
const fs=require('fs');
const ok = fs.existsSync('/app/.next/server/app/$PAGE') ||
           fs.existsSync('/app/.next/server/app/$PAGE/page.js');
console.log(ok ? 'OK' : 'MISSING');
")
  check "/$PAGE" "$RES" "OK"
done

# ============================================================
# CHECK 3: Signup is redirect (not bypass form)
# ============================================================
echo ""
echo "--- Signup Safety ---"

RES=$(node_check "
const fs=require('fs');
const p = '/app/.next/server/app/signup/page.js';
if (!fs.existsSync(p)) { console.log('MISSING'); process.exit(); }
const c = fs.readFileSync(p,'utf8');
if (c.includes('create-signup') || c.includes('Inscription'))
  console.log('BYPASS_FORM');
else
  console.log('SAFE');
")
check "/signup is NOT a bypass form" "$RES" "SAFE"

# ============================================================
# CHECK 4: Image tag traceable
# ============================================================
echo ""
echo "--- Traceability ---"

RES=$(node_check "
const fs=require('fs');
const p = '/app/.next/BUILD_ID';
console.log(fs.existsSync(p) ? 'OK' : 'MISSING');
")
check "BUILD_ID present" "$RES" "OK"

# ============================================================
# VERDICT
# ============================================================
echo ""
echo "=== RESULTATS: $PASS PASS / $FAIL FAIL ==="

if [ $FAIL -gt 0 ]; then
  echo ""
  echo "VERDICT: PROMOTION REFUSEE"
  echo ""
  echo '{ "promotionReady": false, "pass": '$PASS', "fail": '$FAIL' }'
  exit 1
else
  echo ""
  echo "VERDICT: PROMOTION AUTORISEE"
  echo ""
  echo '{ "promotionReady": true, "pass": '$PASS', "fail": '$FAIL' }'
fi
