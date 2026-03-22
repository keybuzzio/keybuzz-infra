#!/bin/bash
set -euo pipefail
NS="keybuzz-api-dev"
POD=$(kubectl get pods -n "$NS" -l app=keybuzz-api --no-headers | grep Running | head -1 | awk '{print $1}')
echo "POD=$POD"

echo "--- Env vars ---"
kubectl exec -n "$NS" "$POD" -- printenv | grep -E "PH113|PH114|AI_REAL" || echo "(none found)"

echo ""
echo "--- Health ---"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/health', r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d)); });
"

echo ""
echo "--- /ai/safe-execution ---"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/safe-execution?tenantId=ecomlg-001&conversationId=test-conv', {headers:{'x-user-email':'test@keybuzz.io'}}, r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d)); });
"

echo ""
echo "--- /ai/real-execution-live ---"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/real-execution-live?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d)); });
"

echo ""
echo "--- /ai/real-execution-plan ---"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/real-execution-plan?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d)); });
"

echo ""
echo "--- /ai/real-execution-status ---"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/real-execution-status?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d)); });
"
