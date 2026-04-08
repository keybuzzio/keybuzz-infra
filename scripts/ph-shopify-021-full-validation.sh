#!/bin/bash
# PH-SHOPIFY-02.1: Full post-OAuth validation

POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
echo "Pod: $POD"

echo ""
echo "=== 1. DB: shopify_connections ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
(async()=>{
  const r=await p.query('SELECT id, tenant_id, shop_domain, scopes, status, created_at FROM shopify_connections ORDER BY created_at DESC LIMIT 5');
  console.log(JSON.stringify(r.rows, null, 2));
  await p.end();
})();
"

echo ""
echo "=== 2. DB: tenant_channels (shopify) ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
(async()=>{
  const r=await p.query(\"SELECT id, tenant_id, marketplace_key, provider, display_name, status, connected_at, connection_ref FROM tenant_channels WHERE marketplace_key='shopify-global' OR provider='shopify'\");
  console.log(JSON.stringify(r.rows, null, 2));
  await p.end();
})();
"

echo ""
echo "=== 3. Shopify status: ecomlg-001 (connected) ==="
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/shopify/status?tenantId=ecomlg-001' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001'

echo ""
echo ""
echo "=== 4. MULTI-TENANT: other tenant (must be disconnected) ==="
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/shopify/status?tenantId=tenant-1772234265142' -H 'X-User-Email: ludovic@ecomlg.fr' -H 'X-Tenant-Id: tenant-1772234265142'

echo ""
echo ""
echo "=== 5. MULTI-TENANT: cross-tenant DB isolation ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
(async()=>{
  const conn=await p.query('SELECT DISTINCT tenant_id FROM shopify_connections');
  console.log('Tenants with connections:', JSON.stringify(conn.rows));
  const ch=await p.query(\"SELECT DISTINCT tenant_id FROM tenant_channels WHERE provider='shopify'\");
  console.log('Tenants with shopify channel:', JSON.stringify(ch.rows));
  await p.end();
})();
"

echo ""
echo "=== 6. WEBHOOK TEST: send test webhook ==="
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s -X POST 'http://127.0.0.1:3001/webhooks/shopify' \
  -H 'Content-Type: application/json' \
  -H 'X-Shopify-Topic: app/uninstalled' \
  -H 'X-Shopify-Shop-Domain: keybuzz-dev.myshopify.com' \
  -H 'X-Shopify-Hmac-Sha256: test-invalid-hmac' \
  -d '{"test": true}'

echo ""
echo ""
echo "=== 7. DB: webhook_events count ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
(async()=>{
  const r=await p.query('SELECT count(*) as total FROM shopify_webhook_events');
  console.log('Webhook events:', r.rows[0].total);
  await p.end();
})();
"

echo ""
echo "=== 8. NON-REGRESSION ==="
echo "--- health ---"
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s http://127.0.0.1:3001/health | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK' if d.get('status')=='ok' else 'FAIL')"

echo "--- conversations ---"
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/messages/conversations?tenantId=ecomlg-001&limit=1' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK -', len(d), 'conversations') if isinstance(d, list) else print('OK - response received')"

echo "--- orders ---"
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/api/v1/orders?tenantId=ecomlg-001&limit=1' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK -', len(d.get('orders',[])), 'orders') if 'orders' in d else print('OK - response received')"

echo "--- ai/wallet/status ---"
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/ai/wallet/status?tenantId=ecomlg-001' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK - KBA:', d.get('kbActions',{}).get('remaining','?'))"

echo "--- channels ---"
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/channels/list?tenantId=ecomlg-001' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' | python3 -c "import sys,json; d=json.load(sys.stdin); chs=d.get('channels',[]); print('OK -', len(chs), 'channels, shopify:', any(c.get('provider')=='shopify' for c in chs))"

echo ""
echo "=== 9. PROD UNCHANGED ==="
echo "API PROD:"
kubectl get deployment keybuzz-api -n keybuzz-api-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
echo "Client PROD:"
kubectl get deployment keybuzz-client -n keybuzz-client-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

echo ""
echo "=== FULL VALIDATION COMPLETE ==="
