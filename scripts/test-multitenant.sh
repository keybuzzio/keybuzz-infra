#!/bin/bash
# Test multi-tenant auto-seed
POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}')

echo "=== 1. EXISTING TENANT (should NOT re-seed) ==="
RESULT=$(kubectl exec -n keybuzz-api-dev "$POD" -- curl -s -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' 'http://127.0.0.1:3001/playbooks?tenantId=ecomlg-001')
echo "$RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'ecomlg-001: {len(d.get(\"playbooks\",[]))} playbooks (should be 15)')"

echo ""
echo "=== 2. AUTO-SEED TEST: fake tenant ==="
# Call playbooks list for a fake tenant that has 0 playbooks
# The auto-seed should create 15 starters
RESULT2=$(kubectl exec -n keybuzz-api-dev "$POD" -- curl -s -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: test-autoseed-001' 'http://127.0.0.1:3001/playbooks?tenantId=test-autoseed-001')
echo "$RESULT2" | python3 -c "import sys,json; d=json.load(sys.stdin); pbs=d.get('playbooks',[]); print(f'test-autoseed-001: {len(pbs)} playbooks (should be 15)'); [print(f'  {p[\"name\"]:40s} | {p[\"status\"]}') for p in pbs[:5]]"

echo ""
echo "=== 3. VERIFY NO DUPLICATE ON SECOND CALL ==="
RESULT3=$(kubectl exec -n keybuzz-api-dev "$POD" -- curl -s -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: test-autoseed-001' 'http://127.0.0.1:3001/playbooks?tenantId=test-autoseed-001')
echo "$RESULT3" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'test-autoseed-001 (2nd call): {len(d.get(\"playbooks\",[]))} playbooks (should still be 15)')"

echo ""
echo "=== 4. CLEANUP TEST TENANT ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');
const p=new Pool();
(async()=>{
  await p.query(\"DELETE FROM ai_rule_actions WHERE rule_id IN (SELECT id FROM ai_rules WHERE tenant_id = 'test-autoseed-001')\");
  await p.query(\"DELETE FROM ai_rule_conditions WHERE rule_id IN (SELECT id FROM ai_rules WHERE tenant_id = 'test-autoseed-001')\");
  const r=await p.query(\"DELETE FROM ai_rules WHERE tenant_id = 'test-autoseed-001' RETURNING id\");
  console.log('Cleaned up ' + r.rowCount + ' test playbooks');
  await p.end();
})();
"

echo ""
echo "=== 5. API LOGS (auto-seed) ==="
kubectl logs --tail=20 -n keybuzz-api-dev "$POD" | grep -i "playbook\|seed" | tail -5

echo ""
echo "=== TEST DONE ==="
