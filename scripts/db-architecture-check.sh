#!/bin/bash
# db-architecture-check.sh — Guardrail d'architecture DB KeyBuzz V3
# Verifie les invariants d'architecture apres PH-TD-05
# Usage: scp sur bastion, puis bash db-architecture-check.sh

set -euo pipefail

PASS=0
FAIL=0
WARN=0

check() {
  local label="$1" result="$2" expected="$3"
  if [ "$result" = "$expected" ]; then
    echo "  [PASS] $label"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $label (got='$result', expected='$expected')"
    FAIL=$((FAIL + 1))
  fi
}

warn() {
  local label="$1" msg="$2"
  echo "  [WARN] $label — $msg"
  WARN=$((WARN + 1))
}

echo "=== KeyBuzz DB Architecture Check ==="
echo "Date: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo ""

# --- PROD checks via keybuzz-api-prod pod ---
echo "--- PROD: keybuzz_prod (API DB) ---"
API_POD=$(kubectl get pods -n keybuzz-api-prod -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$API_POD" ]; then
  echo "  [FAIL] Cannot find keybuzz-api-prod pod"
  FAIL=$((FAIL + 1))
else
  EM_EXISTS_PROD=$(kubectl exec -n keybuzz-api-prod "$API_POD" -- node -e "
    const {Pool} = require('pg');
    const p = new Pool();
    (async () => {
      const r = await p.query(\"SELECT count(*) as c FROM information_schema.tables WHERE table_name='ExternalMessage' AND table_schema='public'\");
      console.log(r.rows[0].c > 0 ? 'EXISTS' : 'MISSING');
      await p.end();
    })();
  " 2>/dev/null | tail -1)
  check "ExternalMessage EXISTS in keybuzz_prod" "$EM_EXISTS_PROD" "EXISTS"
fi

# --- PROD checks via keybuzz-backend-prod pod ---
echo ""
echo "--- PROD: keybuzz_backend_prod (Backend DB) ---"
BK_POD=$(kubectl get pods -n keybuzz-backend-prod -l app=keybuzz-backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$BK_POD" ]; then
  echo "  [FAIL] Cannot find keybuzz-backend-prod pod"
  FAIL=$((FAIL + 1))
else
  EM_EXISTS_BK_PROD=$(kubectl exec -n keybuzz-backend-prod "$BK_POD" -- node -e "
    const {Pool} = require('pg');
    const p = new Pool({connectionString: process.env.DATABASE_URL});
    (async () => {
      const r = await p.query(\"SELECT count(*) as c FROM information_schema.tables WHERE table_name='ExternalMessage' AND table_schema='public'\");
      console.log(r.rows[0].c > 0 ? 'EXISTS' : 'ABSENT');
      await p.end();
    })();
  " 2>/dev/null | tail -1)
  check "ExternalMessage ABSENT from keybuzz_backend_prod" "$EM_EXISTS_BK_PROD" "ABSENT"
fi

# --- DEV checks via keybuzz-api-dev pod ---
echo ""
echo "--- DEV: keybuzz (API DB) ---"
API_DEV_POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$API_DEV_POD" ]; then
  echo "  [FAIL] Cannot find keybuzz-api-dev pod"
  FAIL=$((FAIL + 1))
else
  EM_EXISTS_DEV=$(kubectl exec -n keybuzz-api-dev "$API_DEV_POD" -- node -e "
    const {Pool} = require('pg');
    const p = new Pool();
    (async () => {
      const r = await p.query(\"SELECT count(*) as c FROM information_schema.tables WHERE table_name='ExternalMessage' AND table_schema='public'\");
      console.log(r.rows[0].c > 0 ? 'EXISTS' : 'MISSING');
      await p.end();
    })();
  " 2>/dev/null | tail -1)
  check "ExternalMessage EXISTS in keybuzz (DEV)" "$EM_EXISTS_DEV" "EXISTS"
fi

# --- DEV checks via keybuzz-backend-dev pod ---
echo ""
echo "--- DEV: keybuzz_backend (Backend DB) ---"
BK_DEV_POD=$(kubectl get pods -n keybuzz-backend-dev -l app=keybuzz-backend -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -z "$BK_DEV_POD" ]; then
  echo "  [FAIL] Cannot find keybuzz-backend-dev pod"
  FAIL=$((FAIL + 1))
else
  EM_EXISTS_BK_DEV=$(kubectl exec -n keybuzz-backend-dev "$BK_DEV_POD" -- node -e "
    const {Pool} = require('pg');
    const p = new Pool({connectionString: process.env.DATABASE_URL});
    (async () => {
      const r = await p.query(\"SELECT count(*) as c FROM information_schema.tables WHERE table_name='ExternalMessage' AND table_schema='public'\");
      console.log(r.rows[0].c > 0 ? 'EXISTS' : 'ABSENT');
      await p.end();
    })();
  " 2>/dev/null | tail -1)
  check "ExternalMessage ABSENT from keybuzz_backend (DEV)" "$EM_EXISTS_BK_DEV" "ABSENT"
fi

# --- Health checks ---
echo ""
echo "--- Health Checks ---"

API_HEALTH=$(kubectl exec -n keybuzz-api-prod "$API_POD" -- node -e "
  const http = require('http');
  http.get('http://localhost:3001/health', r => {
    let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode));
  }).on('error', () => console.log('ERR'));
" 2>/dev/null | tail -1)
check "API PROD /health" "$API_HEALTH" "200"

BK_HEALTH=$(kubectl exec -n keybuzz-backend-prod "$BK_POD" -- node -e "
  const http = require('http');
  http.get('http://localhost:4000/health', r => {
    let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode));
  }).on('error', () => console.log('ERR'));
" 2>/dev/null | tail -1)
check "Backend PROD /health" "$BK_HEALTH" "200"

# --- PascalCase tables guardrail (keybuzz_backend_prod should have 0 active PascalCase tables) ---
echo ""
echo "--- PascalCase Guardrail (keybuzz_backend_prod) ---"
if [ -n "$BK_POD" ]; then
  PASCAL_TABLES=$(kubectl exec -n keybuzz-backend-prod "$BK_POD" -- node -e "
    const {Pool} = require('pg');
    const p = new Pool({connectionString: process.env.DATABASE_URL});
    (async () => {
      const r = await p.query(\"SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name ~ '^[A-Z]' AND table_name != '_prisma_migrations' ORDER BY table_name\");
      const active = [];
      for (const row of r.rows) {
        const cr = await p.query('SELECT count(*) as c FROM \"' + row.table_name + '\"');
        if (parseInt(cr.rows[0].c) > 0) active.push(row.table_name + '=' + cr.rows[0].c);
      }
      console.log(active.length === 0 ? 'CLEAN' : active.join(','));
      await p.end();
    })();
  " 2>/dev/null | tail -1)
  if [ "$PASCAL_TABLES" = "CLEAN" ]; then
    echo "  [PASS] No active PascalCase tables with data in keybuzz_backend_prod"
    PASS=$((PASS + 1))
  else
    echo "  [WARN] Active PascalCase tables in keybuzz_backend_prod: $PASCAL_TABLES"
    WARN=$((WARN + 1))
  fi
fi

# --- Summary ---
echo ""
echo "=== SUMMARY ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo "WARN: $WARN"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "RESULT: FAIL — Architecture invariants violated"
  exit 1
else
  echo "RESULT: PASS — All architecture invariants satisfied"
  exit 0
fi
