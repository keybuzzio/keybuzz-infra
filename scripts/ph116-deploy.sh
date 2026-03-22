#!/bin/bash
set -euo pipefail

echo "=== PH116 — Real Execution Monitoring — Build + Deploy ==="
echo "$(date)"

DEV_TAG="ghcr.io/keybuzzio/keybuzz-api:v3.6.18-ph116-real-execution-monitoring-dev"
PROD_TAG="ghcr.io/keybuzzio/keybuzz-api:v3.6.18-ph116-real-execution-monitoring-prod"
NS_DEV="keybuzz-api-dev"
NS_PROD="keybuzz-api-prod"

echo ""
echo "--- Step 1: Docker Build ---"
cd /opt/keybuzz/keybuzz-api
docker build --no-cache -t "$DEV_TAG" .
echo "[OK] Image built"

echo ""
echo "--- Step 2: Push DEV ---"
docker push "$DEV_TAG"
echo "[OK] DEV pushed"

echo ""
echo "--- Step 3: Deploy DEV ---"
kubectl set image deploy/keybuzz-api keybuzz-api="$DEV_TAG" -n "$NS_DEV"
kubectl rollout status deployment/keybuzz-api -n "$NS_DEV" --timeout=120s
echo "[OK] DEV deployed"

echo ""
echo "--- Step 4: Tag + Push PROD ---"
docker tag "$DEV_TAG" "$PROD_TAG"
docker push "$PROD_TAG"
echo "[OK] PROD pushed"

echo ""
echo "--- Step 5: Deploy PROD ---"
kubectl set image deploy/keybuzz-api keybuzz-api="$PROD_TAG" -n "$NS_PROD"
kubectl rollout status deployment/keybuzz-api -n "$NS_PROD" --timeout=120s
echo "[OK] PROD deployed"

echo ""
echo "--- Step 6: Wait + Verify DEV ---"
sleep 10
POD_DEV=$(kubectl get pods -n "$NS_DEV" -l app=keybuzz-api --no-headers | grep Running | head -1 | awk '{print $1}')
echo "DEV pod: $POD_DEV"

echo ">> Health"
kubectl exec -n "$NS_DEV" "$POD_DEV" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/health', r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d)); });
"

echo ">> /ai/real-execution-monitoring"
kubectl exec -n "$NS_DEV" "$POD_DEV" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/real-execution-monitoring?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, r => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => { const j=JSON.parse(d); console.log(r.statusCode, 'total=' + j.volume.total + ' real=' + j.volume.real + ' risk=' + j.tenantRisk.riskScore); }); });
"

echo ">> /ai/real-execution-incidents"
kubectl exec -n "$NS_DEV" "$POD_DEV" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/real-execution-incidents?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, r => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => { const j=JSON.parse(d); console.log(r.statusCode, 'detected=' + j.detectedNow.length + ' active=' + j.activeIncidents.length); }); });
"

echo ">> /ai/real-execution-connectors"
kubectl exec -n "$NS_DEV" "$POD_DEV" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/real-execution-connectors?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, r => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => { const j=JSON.parse(d); console.log(r.statusCode, 'connectors=' + Object.keys(j).length); }); });
"

echo ">> /ai/real-execution-fallback"
kubectl exec -n "$NS_DEV" "$POD_DEV" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/real-execution-fallback?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, r => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => { const j=JSON.parse(d); console.log(r.statusCode, 'risk=' + j.executionRisk + ' rec=' + j.globalRecommendation); }); });
"

echo ""
echo "--- Step 7: Non-regression DEV ---"
for EP in "/ai/real-execution-live?tenantId=ecomlg-001" "/ai/safe-execution?tenantId=ecomlg-001&conversationId=test" "/ai/governance?tenantId=ecomlg-001" "/ai/controlled-execution?tenantId=ecomlg-001"; do
  echo -n ">> $EP -> "
  kubectl exec -n "$NS_DEV" "$POD_DEV" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001${EP}', {headers:{'x-user-email':'test@keybuzz.io'}}, r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode)); });
" 2>&1
done

echo ""
echo "--- Step 8: Verify PROD ---"
sleep 5
POD_PROD=$(kubectl get pods -n "$NS_PROD" -l app=keybuzz-api --no-headers | grep Running | head -1 | awk '{print $1}')
echo "PROD pod: $POD_PROD"

echo ">> PROD Health"
kubectl exec -n "$NS_PROD" "$POD_PROD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/health', r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d)); });
"

echo ">> PROD /ai/real-execution-monitoring"
kubectl exec -n "$NS_PROD" "$POD_PROD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3001/ai/real-execution-monitoring?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, r => {
  let d=''; r.on('data', c => d+=c); r.on('end', () => { const j=JSON.parse(d); console.log(r.statusCode, 'total=' + j.volume.total + ' killSwitch=' + j.killSwitch.currentlyEnabled); }); });
"

echo ">> PROD env check"
kubectl exec -n "$NS_PROD" "$POD_PROD" -- printenv | grep -E "PH113|PH114|AI_REAL" || echo "[OK] No activation env vars in PROD"

echo ""
echo "=== PH116 DEPLOY COMPLETE ==="
echo "DEV: $DEV_TAG"
echo "PROD: $PROD_TAG"
echo "Rollback: kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.17-ph115-real-execution-dev -n keybuzz-api-dev"
echo "Rollback PROD: kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.17-ph115-real-execution-prod -n keybuzz-api-prod"
