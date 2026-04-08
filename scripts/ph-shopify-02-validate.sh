#!/bin/bash
# PH-SHOPIFY-02: Validation E2E
set -e
PASS=0
FAIL=0

check() {
  local desc="$1"
  local result="$2"
  if [ "$result" = "ok" ]; then
    echo "  OK  $desc"
    PASS=$((PASS+1))
  else
    echo "  FAIL $desc ($result)"
    FAIL=$((FAIL+1))
  fi
}

echo "=== PH-SHOPIFY-02 VALIDATION ==="
echo ""

POD_API=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
POD_CLIENT=$(kubectl get pods -n keybuzz-client-dev -l app=keybuzz-client --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')

echo "API Pod: $POD_API"
echo "Client Pod: $POD_CLIENT"
echo ""

# ── 1. API Health ──
echo "--- 1. API Health ---"
HEALTH=$(kubectl exec -n keybuzz-api-dev "$POD_API" -- curl -s http://127.0.0.1:3001/health 2>/dev/null)
if echo "$HEALTH" | grep -q '"ok"'; then
  check "API health" "ok"
else
  check "API health" "$HEALTH"
fi

# ── 2. Shopify Status (no connection) ──
echo ""
echo "--- 2. Shopify Status (tenant ecomlg-001) ---"
STATUS=$(kubectl exec -n keybuzz-api-dev "$POD_API" -- curl -s 'http://127.0.0.1:3001/shopify/status?tenantId=ecomlg-001' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' 2>/dev/null)
echo "  Response: $STATUS"
if echo "$STATUS" | grep -q '"connected":false'; then
  check "Shopify status (not connected)" "ok"
else
  check "Shopify status (not connected)" "$STATUS"
fi

# ── 3. Shopify Connect (should return 503 - no SHOPIFY_CLIENT_ID) ──
echo ""
echo "--- 3. Shopify Connect (no credentials) ---"
CONNECT=$(kubectl exec -n keybuzz-api-dev "$POD_API" -- curl -s -X POST 'http://127.0.0.1:3001/shopify/connect' -H 'Content-Type: application/json' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' -d '{"tenantId":"ecomlg-001","shopDomain":"test.myshopify.com"}' 2>/dev/null)
echo "  Response: $CONNECT"
if echo "$CONNECT" | grep -q '"error":"Shopify OAuth not configured"'; then
  check "Connect returns 503 (no credentials)" "ok"
elif echo "$CONNECT" | grep -q 'not configured'; then
  check "Connect returns error (no credentials)" "ok"
else
  check "Connect response" "$CONNECT"
fi

# ── 4. Shopify Disconnect (no active connection) ──
echo ""
echo "--- 4. Shopify Disconnect ---"
DISCONNECT=$(kubectl exec -n keybuzz-api-dev "$POD_API" -- curl -s -X POST 'http://127.0.0.1:3001/shopify/disconnect' -H 'Content-Type: application/json' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' -d '{"tenantId":"ecomlg-001"}' 2>/dev/null)
echo "  Response: $DISCONNECT"
if echo "$DISCONNECT" | grep -q '"disconnected"'; then
  check "Disconnect endpoint works" "ok"
else
  check "Disconnect endpoint" "$DISCONNECT"
fi

# ── 5. Webhook endpoint ──
echo ""
echo "--- 5. Webhook endpoint ---"
WEBHOOK=$(kubectl exec -n keybuzz-api-dev "$POD_API" -- curl -s -X POST 'http://127.0.0.1:3001/webhooks/shopify' -H 'Content-Type: application/json' -d '{"test":true}' 2>/dev/null)
echo "  Response: $WEBHOOK"
if echo "$WEBHOOK" | grep -q 'Unauthorized\|401'; then
  check "Webhook rejects without HMAC" "ok"
else
  check "Webhook endpoint" "$WEBHOOK"
fi

# ── 6. DB Tables exist ──
echo ""
echo "--- 6. DB Tables ---"
TABLES=$(kubectl exec -n keybuzz-api-dev "$POD_API" -- node -e "
const {Pool}=require('pg');const p=new Pool();
(async()=>{
  const r=await p.query(\"SELECT tablename FROM pg_tables WHERE schemaname='public' AND tablename LIKE 'shopify_%' ORDER BY tablename\");
  console.log(JSON.stringify(r.rows.map(x=>x.tablename)));
  await p.end();
})();" 2>/dev/null)
echo "  Tables: $TABLES"
if echo "$TABLES" | grep -q 'shopify_connections' && echo "$TABLES" | grep -q 'shopify_webhook_events'; then
  check "DB tables exist" "ok"
else
  check "DB tables" "$TABLES"
fi

# ── 7. Multi-tenant isolation (tenant 2) ──
echo ""
echo "--- 7. Multi-tenant isolation ---"
STATUS2=$(kubectl exec -n keybuzz-api-dev "$POD_API" -- curl -s 'http://127.0.0.1:3001/shopify/status?tenantId=tenant-1772234265142' -H 'X-User-Email: ludovic@ecomlg.fr' -H 'X-Tenant-Id: tenant-1772234265142' 2>/dev/null)
echo "  Tenant 2 status: $STATUS2"
if echo "$STATUS2" | grep -q '"connected":false'; then
  check "Tenant 2 isolated (not connected)" "ok"
else
  check "Tenant 2 isolation" "$STATUS2"
fi

# ── 8. Channels catalog ──
echo ""
echo "--- 8. Channels catalog ---"
CATALOG=$(kubectl exec -n keybuzz-api-dev "$POD_API" -- curl -s 'http://127.0.0.1:3001/channels/catalog?tenantId=ecomlg-001' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' 2>/dev/null)
if echo "$CATALOG" | grep -q 'shopify'; then
  check "Shopify in channels catalog" "ok"
else
  check "Shopify in catalog" "not found"
fi

# ── 9. Non-regression (existing endpoints) ──
echo ""
echo "--- 9. Non-regression ---"
for endpoint in "/health" "/channels?tenantId=ecomlg-001" "/playbooks?tenantId=ecomlg-001" "/ai/wallet/status?tenantId=ecomlg-001"; do
  CODE=$(kubectl exec -n keybuzz-api-dev "$POD_API" -- curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:3001${endpoint}" -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' 2>/dev/null)
  if [ "$CODE" = "200" ]; then
    check "$endpoint -> 200" "ok"
  else
    check "$endpoint" "HTTP $CODE"
  fi
done

# ── 10. Channels registry (BFF) ──
echo ""
echo "--- 10. Channels Registry BFF ---"
REGISTRY=$(kubectl exec -n keybuzz-client-dev "$POD_CLIENT" -- curl -s 'http://127.0.0.1:3000/api/channels/registry' 2>/dev/null)
if echo "$REGISTRY" | grep -q 'shopify'; then
  check "Shopify in client registry" "ok"
else
  check "Shopify in client registry" "not found"
fi

# ── 11. Env vars present ──
echo ""
echo "--- 11. Env vars ---"
ENV_CHECK=$(kubectl exec -n keybuzz-api-dev "$POD_API" -- env | grep SHOPIFY | wc -l)
if [ "$ENV_CHECK" -ge 4 ]; then
  check "Shopify env vars present ($ENV_CHECK vars)" "ok"
else
  check "Shopify env vars" "only $ENV_CHECK found"
fi

echo ""
echo "========================================="
echo "  PASS: $PASS | FAIL: $FAIL"
echo "========================================="

if [ "$FAIL" -gt 0 ]; then
  echo "  VALIDATION: SOME TESTS FAILED"
  exit 1
else
  echo "  VALIDATION: ALL TESTS PASSED"
fi
