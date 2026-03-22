#!/bin/bash
set -euo pipefail

echo "=== PH117 — AI Dashboard — Build + Deploy API + Client ==="
echo "$(date)"

API_DEV_TAG="ghcr.io/keybuzzio/keybuzz-api:v3.6.19-ph117-ai-dashboard-dev"
API_PROD_TAG="ghcr.io/keybuzzio/keybuzz-api:v3.6.19-ph117-ai-dashboard-prod"
CLIENT_DEV_TAG="ghcr.io/keybuzzio/keybuzz-client:v3.5.49-ph117-ai-dashboard-dev"
CLIENT_PROD_TAG="ghcr.io/keybuzzio/keybuzz-client:v3.5.49-ph117-ai-dashboard-prod"
NS_API_DEV="keybuzz-api-dev"
NS_API_PROD="keybuzz-api-prod"
NS_CLIENT_DEV="keybuzz-client-dev"
NS_CLIENT_PROD="keybuzz-client-prod"

# ---- API BUILD ----
echo ""
echo "--- Step 1: Build API ---"
cd /opt/keybuzz/keybuzz-api
docker build --no-cache -t "$API_DEV_TAG" .
echo "[OK] API built"

echo ""
echo "--- Step 2: Push + Deploy API DEV ---"
docker push "$API_DEV_TAG"
kubectl set image deploy/keybuzz-api keybuzz-api="$API_DEV_TAG" -n "$NS_API_DEV"
kubectl rollout status deployment/keybuzz-api -n "$NS_API_DEV" --timeout=120s
echo "[OK] API DEV deployed"

echo ""
echo "--- Step 3: Tag + Push + Deploy API PROD ---"
docker tag "$API_DEV_TAG" "$API_PROD_TAG"
docker push "$API_PROD_TAG"
kubectl set image deploy/keybuzz-api keybuzz-api="$API_PROD_TAG" -n "$NS_API_PROD"
kubectl rollout status deployment/keybuzz-api -n "$NS_API_PROD" --timeout=120s
echo "[OK] API PROD deployed"

# ---- CLIENT BUILD ----
echo ""
echo "--- Step 4: Build Client DEV ---"
cd /opt/keybuzz/keybuzz-client
docker build --no-cache \
  --build-arg NEXT_PUBLIC_API_URL=https://api-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_API_BASE_URL=https://api-dev.keybuzz.io \
  -t "$CLIENT_DEV_TAG" .
echo "[OK] Client DEV built"

echo ""
echo "--- Step 5: Push + Deploy Client DEV ---"
docker push "$CLIENT_DEV_TAG"
kubectl set image deploy/keybuzz-client keybuzz-client="$CLIENT_DEV_TAG" -n "$NS_CLIENT_DEV"
kubectl rollout status deployment/keybuzz-client -n "$NS_CLIENT_DEV" --timeout=180s
echo "[OK] Client DEV deployed"

echo ""
echo "--- Step 6: Build Client PROD ---"
docker build --no-cache \
  --build-arg NEXT_PUBLIC_API_URL=https://api.keybuzz.io \
  --build-arg NEXT_PUBLIC_API_BASE_URL=https://api.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=production \
  -t "$CLIENT_PROD_TAG" .
echo "[OK] Client PROD built"

echo ""
echo "--- Step 7: Push + Deploy Client PROD ---"
docker push "$CLIENT_PROD_TAG"
kubectl set image deploy/keybuzz-client keybuzz-client="$CLIENT_PROD_TAG" -n "$NS_CLIENT_PROD"
kubectl rollout status deployment/keybuzz-client -n "$NS_CLIENT_PROD" --timeout=180s
echo "[OK] Client PROD deployed"

# ---- VERIFICATION ----
echo ""
echo "--- Step 8: Verify API DEV ---"
sleep 10
POD_API_DEV=$(kubectl get pods -n "$NS_API_DEV" -l app=keybuzz-api --no-headers | grep Running | head -1 | awk '{print $1}')
echo "API DEV pod: $POD_API_DEV"

echo ">> Health"
kubectl exec -n "$NS_API_DEV" "$POD_API_DEV" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/health', r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d)); });
"

echo ">> /ai/dashboard"
kubectl exec -n "$NS_API_DEV" "$POD_API_DEV" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/dashboard?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, r => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => { const j=JSON.parse(d); console.log(r.statusCode, 'autonomy=' + j.autonomy.level + ' executions=' + j.execution.totalExecutions + ' health=' + j.systemHealth.status); }); });
"

echo ">> /ai/dashboard/metrics"
kubectl exec -n "$NS_API_DEV" "$POD_API_DEV" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/dashboard/metrics?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, r => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => { const j=JSON.parse(d); console.log(r.statusCode, 'total=' + j.executionVolume.total); }); });
"

echo ">> /ai/dashboard/execution"
kubectl exec -n "$NS_API_DEV" "$POD_API_DEV" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/dashboard/execution?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, r => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => { const j=JSON.parse(d); console.log(r.statusCode, 'executions=' + j.executions.length + ' total=' + j.summary.total); }); });
"

echo ">> /ai/dashboard/financial-impact"
kubectl exec -n "$NS_API_DEV" "$POD_API_DEV" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/dashboard/financial-impact?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, r => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => { const j=JSON.parse(d); console.log(r.statusCode, 'savings=' + j.estimatedSavings + ' refundsAvoided=' + j.refundsAvoided); }); });
"

echo ">> /ai/dashboard/recommendations"
kubectl exec -n "$NS_API_DEV" "$POD_API_DEV" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/dashboard/recommendations?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, r => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => { const j=JSON.parse(d); console.log(r.statusCode, 'recommendations=' + j.recommendations.length); }); });
"

echo ""
echo "--- Step 9: Non-regression DEV ---"
for EP in "/ai/real-execution-monitoring?tenantId=ecomlg-001" "/ai/real-execution-live?tenantId=ecomlg-001" "/ai/governance?tenantId=ecomlg-001" "/ai/self-improvement?tenantId=ecomlg-001"; do
  echo -n ">> $EP -> "
  kubectl exec -n "$NS_API_DEV" "$POD_API_DEV" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001${EP}', {headers:{'x-user-email':'test@keybuzz.io'}}, r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode)); });
" 2>&1
done

echo ""
echo "--- Step 10: Verify API PROD ---"
sleep 5
POD_API_PROD=$(kubectl get pods -n "$NS_API_PROD" -l app=keybuzz-api --no-headers | grep Running | head -1 | awk '{print $1}')
echo "API PROD pod: $POD_API_PROD"
kubectl exec -n "$NS_API_PROD" "$POD_API_PROD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/health', r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d)); });
"
kubectl exec -n "$NS_API_PROD" "$POD_API_PROD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/dashboard?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, r => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => { const j=JSON.parse(d); console.log(r.statusCode, 'autonomy=' + j.autonomy.level + ' health=' + j.systemHealth.status); }); });
"

echo ""
echo "=== PH117 DEPLOY COMPLETE ==="
echo "API DEV: $API_DEV_TAG"
echo "API PROD: $API_PROD_TAG"
echo "Client DEV: $CLIENT_DEV_TAG"
echo "Client PROD: $CLIENT_PROD_TAG"
