#!/bin/bash
# Disconnect existing Shopify connection, then verify new scopes in connect URL

POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
echo "Pod: $POD"

# Get tenant_id of existing connection
TENANT=$(kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
(async()=>{
  const r=await p.query(\"SELECT tenant_id FROM shopify_connections WHERE status='active' LIMIT 1\");
  if(r.rows.length) console.log(r.rows[0].tenant_id);
  else console.log('NONE');
  await p.end();
})();
")
echo "Active tenant: $TENANT"

if [ "$TENANT" = "NONE" ]; then
  echo "No active connection to disconnect."
else
  echo ""
  echo "=== 1. Disconnect existing connection ==="
  kubectl exec -n keybuzz-api-dev "$POD" -- curl -s -X POST 'http://127.0.0.1:3001/shopify/disconnect' \
    -H 'Content-Type: application/json' \
    -H "X-User-Email: ludo.gonthier@gmail.com" \
    -H "X-Tenant-Id: $TENANT" \
    -d "{\"tenantId\":\"$TENANT\"}"
  echo ""
fi

echo ""
echo "=== 2. Verify scopes in new connect URL ==="
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s -X POST 'http://127.0.0.1:3001/shopify/connect' \
  -H 'Content-Type: application/json' \
  -H 'X-User-Email: ludo.gonthier@gmail.com' \
  -H 'X-Tenant-Id: keybuzz-mnqnjna8' \
  -d '{"shopDomain":"keybuzz-dev.myshopify.com"}'

echo ""
echo ""
echo "=== 3. DB status after disconnect ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
(async()=>{
  const c=await p.query('SELECT id, tenant_id, status FROM shopify_connections ORDER BY created_at DESC LIMIT 3');
  console.log('Connections:', JSON.stringify(c.rows));
  const ch=await p.query(\"SELECT tenant_id, status FROM tenant_channels WHERE marketplace_key='shopify-global'\");
  console.log('Channels:', JSON.stringify(ch.rows));
  await p.end();
})();
"

echo ""
echo "=== DONE ==="
