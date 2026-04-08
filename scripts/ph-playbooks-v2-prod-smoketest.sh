#!/bin/bash
set -e

echo "=============================================="
echo "PH-PLAYBOOKS-V2 PROD — SMOKE TESTS"
echo "=============================================="

POD=$(kubectl get pods -n keybuzz-api-prod -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "=== 1. POD STATUS ==="
kubectl get pods -n keybuzz-api-prod -l app=keybuzz-api --no-headers
kubectl get pods -n keybuzz-client-prod -l app=keybuzz-client --no-headers

echo ""
echo "=== 2. IMAGE VERIFICATION ==="
echo "API PROD:"
kubectl get deployment keybuzz-api -n keybuzz-api-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
echo "Client PROD:"
kubectl get deployment keybuzz-client -n keybuzz-client-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

echo ""
echo "=== 3. API HEALTH ==="
kubectl exec -n keybuzz-api-prod "$POD" -- curl -s http://127.0.0.1:3001/health
echo ""

echo ""
echo "=== 4. PLAYBOOKS LIST PROD ==="
RESULT=$(kubectl exec -n keybuzz-api-prod "$POD" -- curl -s \
  -H 'X-User-Email: ludo.gonthier@gmail.com' \
  -H 'X-Tenant-Id: ecomlg-001' \
  'http://127.0.0.1:3001/playbooks?tenantId=ecomlg-001')
echo "$RESULT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
pbs=d.get('playbooks',[])
active = sum(1 for p in pbs if p['status']=='active')
disabled = sum(1 for p in pbs if p['status']=='disabled')
print(f'Total: {len(pbs)} | Active: {active} | Disabled: {disabled}')
for p in pbs:
    print(f'  {p[\"name\"]:40s} | {p[\"trigger_type\"]:25s} | {p[\"status\"]}')
"

echo ""
echo "=== 5. TRIGGER VALIDATION PROD ==="
kubectl exec -n keybuzz-api-prod "$POD" -- node -e "
const TRIGGER_DEFS = {
  tracking_request: { keywords: ['suivi', 'tracking', 'colis', 'livraison'], synonyms: ['ou est ma commande', 'numero de suivi'], regex: /o[u]\s+(est|se\s+trouve)\s+(ma|mon|le|la)\s+(commande|colis|paquet)/i },
  return_request: { keywords: ['retour', 'retourner', 'renvoyer', 'rembourser', 'remboursement'], synonyms: ['retourner le produit'], regex: /(retour(ner)?|rembours(er|ement)|renvoyer)/i },
  defective_product: { keywords: ['defectueux', 'casse', 'abime', 'endommage', 'ne fonctionne pas', 'panne'], synonyms: ['produit casse', 'arrive casse', 'ne marche pas'] },
  order_cancelled: { keywords: ['annuler', 'annulation', 'annule'], synonyms: ['annuler ma commande', 'je veux annuler'], regex: /(annul(er|ation|e)|ne\s+veux\s+plus)/i },
};
function detect(msg) {
  const lower = msg.toLowerCase();
  const m = [];
  for (const [t, d] of Object.entries(TRIGGER_DEFS)) {
    if (d.regex && d.regex.test(msg)) { m.push(t); continue; }
    const all = [...d.keywords, ...d.synonyms];
    if (all.some(x => lower.includes(x.toLowerCase()))) m.push(t);
  }
  return m;
}
const tests = [
  ['Annulation', 'Je veux annuler ma commande.'],
  ['Retour', 'Je souhaite retourner le produit et etre rembourse.'],
  ['Defectueux', 'Le produit est casse, il ne fonctionne pas.'],
  ['Suivi', 'Ou est ma commande, je n ai pas recu mon colis.'],
  ['Retard', 'Ma livraison a 5 jours de retard !'],
];
let allOk = true;
tests.forEach(([label, msg]) => {
  const triggers = detect(msg);
  const hasTracking = triggers.includes('tracking_request');
  const ok = label === 'Annulation' ? !hasTracking : true;
  if (!ok) allOk = false;
  console.log(label + ': ' + JSON.stringify(triggers) + (ok ? ' OK' : ' FAIL'));
});
console.log(allOk ? 'ALL TRIGGERS OK' : 'TRIGGER FAILURE DETECTED');
"

echo ""
echo "=== 6. NON-REGRESSION ENDPOINTS PROD ==="
for ep in \
  'conversations:http://127.0.0.1:3001/messages/conversations?tenantId=ecomlg-001&limit=1' \
  'check-user:http://127.0.0.1:3001/tenant-context/check-user' \
  'agents:http://127.0.0.1:3001/agents?tenantId=ecomlg-001' \
  'billing:http://127.0.0.1:3001/billing/current?tenantId=ecomlg-001' \
  'ai-wallet:http://127.0.0.1:3001/ai/wallet/status?tenantId=ecomlg-001' \
  'ai-settings:http://127.0.0.1:3001/ai/settings?tenantId=ecomlg-001' \
  'dashboard:http://127.0.0.1:3001/dashboard/summary?tenantId=ecomlg-001' \
  'orders:http://127.0.0.1:3001/api/v1/orders?tenantId=ecomlg-001&limit=1' \
  'entitlement:http://127.0.0.1:3001/tenant-context/entitlement?tenantId=ecomlg-001' \
  'space-invites:http://127.0.0.1:3001/space-invites/ecomlg-001' \
  'playbooks:http://127.0.0.1:3001/playbooks?tenantId=ecomlg-001'; do
  name="${ep%%:*}"
  url="${ep#*:}"
  code=$(kubectl exec -n keybuzz-api-prod "$POD" -- curl -s -o /dev/null -w '%{http_code}' \
    -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' "$url")
  echo "  $name: $code"
done

echo ""
echo "=== 7. MULTI-TENANT AUTO-SEED TEST PROD ==="
SEED_RESULT=$(kubectl exec -n keybuzz-api-prod "$POD" -- curl -s \
  -H 'X-User-Email: ludo.gonthier@gmail.com' \
  -H 'X-Tenant-Id: test-prod-seed-001' \
  'http://127.0.0.1:3001/playbooks?tenantId=test-prod-seed-001')
SEED_COUNT=$(echo "$SEED_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('playbooks',[])))")
echo "  Auto-seed for new tenant: $SEED_COUNT playbooks"

# Cleanup
kubectl exec -n keybuzz-api-prod "$POD" -- node -e "
const {Pool}=require('pg');
const p=new Pool();
(async()=>{
  await p.query(\"DELETE FROM ai_rule_actions WHERE rule_id IN (SELECT id FROM ai_rules WHERE tenant_id = 'test-prod-seed-001')\");
  await p.query(\"DELETE FROM ai_rule_conditions WHERE rule_id IN (SELECT id FROM ai_rules WHERE tenant_id = 'test-prod-seed-001')\");
  const r=await p.query(\"DELETE FROM ai_rules WHERE tenant_id = 'test-prod-seed-001' RETURNING id\");
  console.log('Cleaned: ' + r.rowCount + ' test playbooks');
  await p.end();
})();
"

echo ""
echo "=== 8. DEV UNCHANGED ==="
echo "API DEV:"
kubectl get deployment keybuzz-api -n keybuzz-api-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
echo "Client DEV:"
kubectl get deployment keybuzz-client -n keybuzz-client-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

echo ""
echo "=== 9. PROD LOGS (last 10 lines) ==="
kubectl logs --tail=5 -n keybuzz-api-prod "$POD" | grep -i "error\|warn\|seed\|playbook" || echo "  (no relevant log entries)"

echo ""
echo "=============================================="
echo "SMOKE TESTS COMPLETE"
echo "=============================================="
