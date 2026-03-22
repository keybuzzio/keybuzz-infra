#!/bin/bash
set -euo pipefail

NS="keybuzz-api-prod"
POD=$(kubectl get pods -n "$NS" -l app=keybuzz-api --no-headers -o custom-columns=":metadata.name" | head -1)
echo "Pod: $POD"

echo ""
echo "--- Checking compiled JS for PH114 routes ---"
kubectl exec -n "$NS" "$POD" -- node -e "
const fs = require('fs');
const path = '/app/dist/modules/ai/ai-policy-debug-routes.js';
const content = fs.readFileSync(path, 'utf-8');
console.log('real-execution-plan found:', content.includes('real-execution-plan'));
console.log('connector-readiness found:', content.includes('connector-readiness'));
console.log('expandedMode found:', content.includes('expandedMode'));
console.log('File size:', content.length);
"

echo ""
echo "--- Testing endpoints ---"

for EP in "real-execution-plan?tenantId=ecomlg-001" "connector-readiness?tenantId=ecomlg-001&action=REQUEST_INFORMATION&connector=customer_interaction_connector" "real-execution-status?tenantId=ecomlg-001" "safe-execution?tenantId=ecomlg-001"; do
  echo ">> /ai/$EP"
  kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
const opts = { headers: { 'x-user-email': 'test@keybuzz.io' } };
http.get('http://127.0.0.1:3001/ai/$EP', opts, (r) => {
  let d = '';
  r.on('data', c => d += c);
  r.on('end', () => console.log(r.statusCode));
}).on('error', e => console.log('ERR', e.message));
"
  echo ""
done
