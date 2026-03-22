#!/bin/bash
set -euo pipefail
NS="keybuzz-api-prod"
POD=$(kubectl get pods -n "$NS" -l app=keybuzz-api --no-headers | grep Running | head -1 | awk '{print $1}')
echo "POD=$POD"

echo "--- Env vars (should be empty) ---"
kubectl exec -n "$NS" "$POD" -- printenv | grep -E "PH113|PH114|AI_REAL" || echo "[OK] No activation env vars"

echo ""
echo "--- Health ---"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/health', r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d)); });
"

echo ""
echo "--- /ai/real-execution-live (should show enabled=false) ---"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/real-execution-live?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d)); });
"

echo ""
echo "--- /ai/safe-execution (should show DRY_RUN) ---"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/safe-execution?tenantId=ecomlg-001&conversationId=test', {headers:{'x-user-email':'test@keybuzz.io'}}, r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d)); });
"

echo ""
echo "--- Non-regression ---"
for EP in "/health" "/ai/governance?tenantId=ecomlg-001" "/ai/controlled-execution?tenantId=ecomlg-001" "/ai/controlled-activation?tenantId=ecomlg-001"; do
  echo ">> $EP"
  kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001${EP}', {headers:{'x-user-email':'test@keybuzz.io'}}, r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode)); });
" 2>&1
done

echo ""
echo "=== PROD VERIFICATION COMPLETE ==="
