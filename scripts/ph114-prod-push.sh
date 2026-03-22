#!/bin/bash
set -euo pipefail

echo "=== PH114 — PROD Push (tag from DEV) ==="

DEV_TAG="ghcr.io/keybuzzio/keybuzz-api:v3.6.16-ph114-real-scaling-dev"
PROD_TAG="ghcr.io/keybuzzio/keybuzz-api:v3.6.16-ph114-real-scaling-prod"
NS="keybuzz-api-prod"

echo "--- Step 1: Tag PROD from DEV ---"
docker tag "$DEV_TAG" "$PROD_TAG"
echo "[OK] Tagged: $PROD_TAG"

echo ""
echo "--- Step 2: Push PROD ---"
docker push "$PROD_TAG"
echo "[OK] Pushed: $PROD_TAG"

echo ""
echo "--- Step 3: Deploy PROD ---"
kubectl set image deploy/keybuzz-api keybuzz-api="$PROD_TAG" -n "$NS"
kubectl rollout status deployment/keybuzz-api -n "$NS" --timeout=120s
echo "[OK] Deployed to $NS"

echo ""
echo "--- Step 4: Verify PROD ---"
sleep 5
POD=$(kubectl get pods -n "$NS" -l app=keybuzz-api --no-headers -o custom-columns=":metadata.name" | head -1)
echo "Active pod: $POD"

echo ""
echo ">> /health"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/health', (r) => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d));
}).on('error', e => console.log('ERR', e.message));
" 2>&1

echo ""
echo ">> /ai/real-execution-status"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/real-execution-status?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, (r) => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d));
}).on('error', e => console.log('ERR', e.message));
" 2>&1

echo ""
echo ">> /ai/real-execution-plan"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/real-execution-plan?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, (r) => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d));
}).on('error', e => console.log('ERR', e.message));
" 2>&1

echo ""
echo ">> /ai/connector-readiness"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/connector-readiness?tenantId=ecomlg-001&action=REQUEST_INFORMATION&connector=customer_interaction_connector', {headers:{'x-user-email':'test@keybuzz.io'}}, (r) => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d));
}).on('error', e => console.log('ERR', e.message));
" 2>&1

echo ""
echo ">> /ai/governance"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/governance?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, (r) => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d));
}).on('error', e => console.log('ERR', e.message));
" 2>&1

echo ""
echo ">> /ai/controlled-execution"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/controlled-execution?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, (r) => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d));
}).on('error', e => console.log('ERR', e.message));
" 2>&1

echo ""
echo "=== PH114 PROD COMPLETE ==="
echo "Image: $PROD_TAG"
echo "Rollback: kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.15-ph113-real-connector-prod -n $NS"
