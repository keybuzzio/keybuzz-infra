#!/bin/bash
POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')

echo "=== marketplace_sync_states schema ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
(async()=>{
  const r=await p.query(\"SELECT column_name, data_type FROM information_schema.columns WHERE table_name='marketplace_sync_states' ORDER BY ordinal_position\");
  console.log(JSON.stringify(r.rows,null,2));
  await p.end();
})();
"

echo ""
echo "=== check for duplicate orders (tenant_id, external_order_id, channel) ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
(async()=>{
  const r=await p.query(\"SELECT tenant_id, external_order_id, channel, COUNT(*) as cnt FROM orders GROUP BY tenant_id, external_order_id, channel HAVING COUNT(*) > 1 LIMIT 10\");
  console.log('duplicates:', JSON.stringify(r.rows));
  await p.end();
})();
"

echo ""
echo "=== channels service file ==="
ls -la /opt/keybuzz/keybuzz-api/src/modules/channels/ 2>/dev/null || echo "No channels module"

echo ""
echo "=== current API image ==="
kubectl get deployment keybuzz-api -n keybuzz-api-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
