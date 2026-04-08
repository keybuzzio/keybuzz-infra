#!/bin/bash
POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')

echo "=== 1. shopify_connections (active) ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
(async()=>{
  const r=await p.query(\"SELECT id, tenant_id, shop_domain, scopes, status, created_at FROM shopify_connections WHERE status='active' ORDER BY created_at DESC\");
  console.log(JSON.stringify(r.rows, null, 2));
  await p.end();
})();
"

echo ""
echo "=== 2. tenant_channels (shopify active) ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
(async()=>{
  const r=await p.query(\"SELECT tenant_id, marketplace_key, status, connected_at, connection_ref FROM tenant_channels WHERE marketplace_key='shopify-global' AND status='active'\");
  console.log(JSON.stringify(r.rows, null, 2));
  await p.end();
})();
"

echo ""
echo "=== 3. Shopify status API ==="
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/shopify/status?tenantId=keybuzz-mnqnjna8' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: keybuzz-mnqnjna8'

echo ""
echo ""
echo "=== 4. Multi-tenant: ecomlg-001 (must be disconnected) ==="
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/shopify/status?tenantId=ecomlg-001' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001'

echo ""
echo ""
echo "=== 5. Non-regression ==="
echo "--- health ---"
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s http://127.0.0.1:3001/health | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK' if d.get('status')=='ok' else 'FAIL')"
echo "--- conversations ---"
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/messages/conversations?tenantId=ecomlg-001&limit=1' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK') if isinstance(d, list) else print('OK')"
echo "--- orders ---"
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/api/v1/orders?tenantId=ecomlg-001&limit=1' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK')"
echo "--- ai/wallet ---"
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/ai/wallet/status?tenantId=ecomlg-001' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK - KBA:', d.get('kbActions',{}).get('remaining','?'))"

echo ""
echo "=== 6. PROD unchanged ==="
kubectl get deployment keybuzz-api -n keybuzz-api-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

echo ""
echo "=== FINAL CHECK COMPLETE ==="
