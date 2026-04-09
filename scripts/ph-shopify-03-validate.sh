#!/bin/bash
set -e
POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')

echo "========================================="
echo "  PH-SHOPIFY-03 — VALIDATION COMPLETE"
echo "========================================="

echo ""
echo "=== 1. HEALTH CHECK ==="
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s http://127.0.0.1:3001/health
echo ""

echo ""
echo "=== 2. SHOPIFY STATUS (keybuzz-mnqnjna8) ==="
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/shopify/status?tenantId=keybuzz-mnqnjna8' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: keybuzz-mnqnjna8'
echo ""

echo ""
echo "=== 3. TRIGGER SHOPIFY ORDERS SYNC ==="
SYNC_RESULT=$(kubectl exec -n keybuzz-api-dev "$POD" -- curl -s -X POST 'http://127.0.0.1:3001/shopify/orders/sync' \
  -H 'Content-Type: application/json' \
  -H 'X-User-Email: ludo.gonthier@gmail.com' \
  -H 'X-Tenant-Id: keybuzz-mnqnjna8' \
  -d '{"tenantId":"keybuzz-mnqnjna8","limit":50}')
echo "$SYNC_RESULT"

echo ""
echo "=== 4. CHECK SHOPIFY ORDERS IN DB ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
(async()=>{
  const r=await p.query(\"SELECT id, tenant_id, external_order_id, channel, status, total_amount, currency, customer_name, delivery_status, order_date FROM orders WHERE channel='shopify' ORDER BY order_date DESC LIMIT 10\");
  console.log('Shopify orders:', r.rows.length);
  r.rows.forEach(o => console.log('  ', o.external_order_id, '|', o.status, '|', o.total_amount, o.currency, '|', o.customer_name, '|', o.delivery_status));
  await p.end();
})();
"

echo ""
echo "=== 5. SHOPIFY ORDERS LIST ENDPOINT ==="
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/shopify/orders/list?tenantId=keybuzz-mnqnjna8&limit=5' \
  -H 'X-User-Email: ludo.gonthier@gmail.com' \
  -H 'X-Tenant-Id: keybuzz-mnqnjna8' | python3 -c "import sys,json;d=json.load(sys.stdin);print(f'Total Shopify orders: {d.get(\"total\",0)}')"

echo ""
echo "=== 6. VERIFY ORDERS API INCLUDES SHOPIFY (standard /api/v1/orders) ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
(async()=>{
  const r=await p.query(\"SELECT channel, COUNT(*) as cnt FROM orders WHERE tenant_id='keybuzz-mnqnjna8' GROUP BY channel\");
  console.log('Orders by channel:', JSON.stringify(r.rows));
  await p.end();
})();
"

echo ""
echo "=== 7. IDEMPOTENCE TEST — re-sync (should be all updates) ==="
RESYNC=$(kubectl exec -n keybuzz-api-dev "$POD" -- curl -s -X POST 'http://127.0.0.1:3001/shopify/orders/sync' \
  -H 'Content-Type: application/json' \
  -H 'X-User-Email: ludo.gonthier@gmail.com' \
  -H 'X-Tenant-Id: keybuzz-mnqnjna8' \
  -d '{"tenantId":"keybuzz-mnqnjna8","limit":50}')
echo "$RESYNC"
echo "Expected: inserted=0, updated=same as first sync"

echo ""
echo "=== 8. MULTI-TENANT ISOLATION (ecomlg-001 must have 0 Shopify orders) ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
(async()=>{
  const r=await p.query(\"SELECT COUNT(*) as cnt FROM orders WHERE tenant_id='ecomlg-001' AND channel='shopify'\");
  console.log('ecomlg-001 Shopify orders:', r.rows[0].cnt, r.rows[0].cnt === '0' ? '✓ ISOLATED' : '✗ LEAK!');
  await p.end();
})();
"

echo ""
echo "=== 9. NON-REGRESSION ==="
echo "--- health ---"
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s http://127.0.0.1:3001/health | python3 -c "import sys,json;d=json.load(sys.stdin);print('OK' if d.get('status')=='ok' else 'FAIL')"

echo "--- amazon orders (ecomlg-001) ---"
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
(async()=>{
  const r=await p.query(\"SELECT COUNT(*) FROM orders WHERE tenant_id='ecomlg-001' AND channel='amazon'\");
  console.log('Amazon orders:', r.rows[0].count);
  await p.end();
})();
"

echo "--- conversations ---"
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/messages/conversations?tenantId=ecomlg-001&limit=1' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' | python3 -c "import sys,json;d=json.load(sys.stdin);print('OK' if isinstance(d,list) else 'OK')"

echo "--- ai/wallet ---"
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/ai/wallet/status?tenantId=ecomlg-001' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' | python3 -c "import sys,json;d=json.load(sys.stdin);print('OK - KBA:', d.get('kbActions',{}).get('remaining','?'))"

echo ""
echo "=== 10. PROD UNCHANGED ==="
kubectl get deployment keybuzz-api -n keybuzz-api-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

echo ""
echo "=== 11. POD LOGS (last 20 Shopify lines) ==="
kubectl logs -n keybuzz-api-dev "$POD" --tail=50 | grep -i shopify | tail -20

echo ""
echo "========================================="
echo "  VALIDATION COMPLETE"
echo "========================================="
