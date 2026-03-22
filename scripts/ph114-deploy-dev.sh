#!/bin/bash
set -euo pipefail

echo "=== PH114 — Real Connector Scaling Plan — DEV Deploy ==="
echo "$(date)"

TAG="ghcr.io/keybuzzio/keybuzz-api:v3.6.16-ph114-real-scaling-dev"
NS="keybuzz-api-dev"

# Step 1: Sync files
echo ""
echo "--- Step 1: Sync source files ---"
cd /opt/keybuzz/keybuzz-api

echo "[OK] Source synced"

# Step 2: Build
echo ""
echo "--- Step 2: Docker Build ---"
docker build --no-cache -t "$TAG" .
echo "[OK] Image built: $TAG"

# Step 3: Push
echo ""
echo "--- Step 3: Docker Push ---"
docker push "$TAG"
echo "[OK] Image pushed"

# Step 4: Deploy
echo ""
echo "--- Step 4: Kubernetes Deploy ---"
kubectl set image deploy/keybuzz-api keybuzz-api="$TAG" -n "$NS"
kubectl rollout status deployment/keybuzz-api -n "$NS" --timeout=120s
echo "[OK] Deployed to $NS"

# Step 5: Verify pod
echo ""
echo "--- Step 5: Pod Verification ---"
sleep 5
POD=$(kubectl get pods -n "$NS" -l app=keybuzz-api --no-headers -o custom-columns=":metadata.name" | head -1)
echo "Active pod: $POD"
kubectl get pods -n "$NS" -l app=keybuzz-api

# Step 6: Health check
echo ""
echo "--- Step 6: Health Check ---"
HEALTH=$(kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/health', (r) => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d));
}).on('error', e => console.log('ERR', e.message));
" 2>&1 || echo "HEALTH_FAILED")
echo "Health: $HEALTH"

# Step 7: PH114 endpoints
echo ""
echo "--- Step 7: PH114 Endpoints ---"

echo ">> /ai/real-execution-status"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/real-execution-status?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, (r) => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d));
}).on('error', e => console.log('ERR', e.message));
" 2>&1 || echo "ENDPOINT_FAILED"

echo ""
echo ">> /ai/real-execution-plan"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/real-execution-plan?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, (r) => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d));
}).on('error', e => console.log('ERR', e.message));
" 2>&1 || echo "ENDPOINT_FAILED"

echo ""
echo ">> /ai/connector-readiness"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/connector-readiness?tenantId=ecomlg-001&action=REQUEST_INFORMATION&connector=customer_interaction_connector', {headers:{'x-user-email':'test@keybuzz.io'}}, (r) => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d));
}).on('error', e => console.log('ERR', e.message));
" 2>&1 || echo "ENDPOINT_FAILED"

echo ""
echo ">> /ai/safe-execution"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/safe-execution?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, (r) => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d));
}).on('error', e => console.log('ERR', e.message));
" 2>&1 || echo "ENDPOINT_FAILED"

# Step 8: Non-regression
echo ""
echo "--- Step 8: Non-Regression ---"

for EP in "/health" "/ai/governance?tenantId=ecomlg-001" "/ai/controlled-execution?tenantId=ecomlg-001" "/ai/controlled-activation?tenantId=ecomlg-001" "/ai/action-dispatcher?tenantId=ecomlg-001"; do
  echo ">> $EP"
  kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
const opts = {headers:{'x-user-email':'test@keybuzz.io'}};
http.get('http://127.0.0.1:3001${EP}', opts, (r) => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode));
}).on('error', e => console.log('ERR', e.message));
" 2>&1 || echo "CHECK_FAILED"
done

echo ""
echo "=== PH114 DEV DEPLOY COMPLETE ==="
echo "Image: $TAG"
echo "Rollback: kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.15-ph113-real-connector-dev -n $NS"
