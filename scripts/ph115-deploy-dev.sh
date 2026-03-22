#!/bin/bash
set -euo pipefail

echo "=== PH115 — First Controlled Real Execution — DEV Deploy ==="
echo "$(date)"

TAG="ghcr.io/keybuzzio/keybuzz-api:v3.6.17-ph115-real-execution-dev"
NS="keybuzz-api-dev"

echo ""
echo "--- Step 1: Docker Build ---"
cd /opt/keybuzz/keybuzz-api
docker build --no-cache -t "$TAG" .
echo "[OK] Image built: $TAG"

echo ""
echo "--- Step 2: Docker Push ---"
docker push "$TAG"
echo "[OK] Image pushed"

echo ""
echo "--- Step 3: Deploy with env vars ---"
kubectl set image deploy/keybuzz-api keybuzz-api="$TAG" -n "$NS"

kubectl set env deploy/keybuzz-api -n "$NS" \
  PH113_SAFE_MODE=true \
  AI_REAL_EXECUTION_ENABLED=true \
  PH114_EXPANDED_MODE=true \
  AI_REAL_EXECUTION_TENANTS=ecomlg-001

kubectl rollout status deployment/keybuzz-api -n "$NS" --timeout=120s
echo "[OK] Deployed with activation env vars"

echo ""
echo "--- Step 4: Pod verification ---"
sleep 8
POD=$(kubectl get pods -n "$NS" -l app=keybuzz-api --no-headers -o custom-columns=":metadata.name" | grep -v Terminating | head -1)
echo "Active pod: $POD"
kubectl get pods -n "$NS" -l app=keybuzz-api

echo ""
echo "--- Step 5: Health check ---"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/health', (r) => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d));
}).on('error', e => console.log('ERR', e.message));
" 2>&1

echo ""
echo "--- Step 6: PH115 Live Execution Status ---"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/real-execution-live?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, (r) => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d));
}).on('error', e => console.log('ERR', e.message));
" 2>&1

echo ""
echo "--- Step 7: Safe execution test ---"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/safe-execution?tenantId=ecomlg-001&conversationId=test-conv', {headers:{'x-user-email':'test@keybuzz.io'}}, (r) => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d));
}).on('error', e => console.log('ERR', e.message));
" 2>&1

echo ""
echo "--- Step 8: Execution plan ---"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/real-execution-plan?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, (r) => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d));
}).on('error', e => console.log('ERR', e.message));
" 2>&1

echo ""
echo "--- Step 9: Non-regression ---"
for EP in "/health" "/ai/governance?tenantId=ecomlg-001" "/ai/controlled-execution?tenantId=ecomlg-001" "/ai/controlled-activation?tenantId=ecomlg-001"; do
  echo ">> $EP"
  kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001${EP}', {headers:{'x-user-email':'test@keybuzz.io'}}, (r) => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode));
}).on('error', e => console.log('ERR', e.message));
" 2>&1
done

echo ""
echo "=== PH115 DEV DEPLOY COMPLETE ==="
echo "Image: $TAG"
echo "ENV: PH113_SAFE_MODE=true AI_REAL_EXECUTION_ENABLED=true PH114_EXPANDED_MODE=true"
echo "Rollback: kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.16-ph114-real-scaling-dev -n $NS && kubectl set env deploy/keybuzz-api -n $NS PH113_SAFE_MODE- AI_REAL_EXECUTION_ENABLED- PH114_EXPANDED_MODE- AI_REAL_EXECUTION_TENANTS-"
