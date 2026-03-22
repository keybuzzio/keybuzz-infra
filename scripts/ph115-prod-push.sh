#!/bin/bash
set -euo pipefail

echo "=== PH115 — PROD Push ==="
echo "$(date)"

DEV_TAG="ghcr.io/keybuzzio/keybuzz-api:v3.6.17-ph115-real-execution-dev"
PROD_TAG="ghcr.io/keybuzzio/keybuzz-api:v3.6.17-ph115-real-execution-prod"
NS="keybuzz-api-prod"

echo "--- Step 1: Tag DEV image for PROD ---"
docker tag "$DEV_TAG" "$PROD_TAG"
echo "[OK] Tagged"

echo "--- Step 2: Push PROD image ---"
docker push "$PROD_TAG"
echo "[OK] Pushed"

echo "--- Step 3: Deploy to PROD ---"
kubectl set image deploy/keybuzz-api keybuzz-api="$PROD_TAG" -n "$NS"
kubectl rollout status deployment/keybuzz-api -n "$NS" --timeout=120s
echo "[OK] Deployed"

echo "--- Step 4: Wait for pod ---"
sleep 10
POD=$(kubectl get pods -n "$NS" -l app=keybuzz-api --no-headers | grep Running | head -1 | awk '{print $1}')
echo "PROD pod: $POD"

echo "--- Step 5: Verify NO activation env vars ---"
echo "Checking env vars (should be empty):"
kubectl exec -n "$NS" "$POD" -- printenv | grep -E "PH113|PH114|AI_REAL" || echo "[OK] No activation env vars in PROD"

echo ""
echo "--- Step 6: Health check ---"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:80/health', r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d)); });
"

echo ""
echo "--- Step 7: PH115 endpoints (should be DRY_RUN) ---"
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:80/ai/real-execution-live?tenantId=ecomlg-001', {headers:{'x-user-email':'test@keybuzz.io'}}, r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d)); });
"

echo ""
kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:80/ai/safe-execution?tenantId=ecomlg-001&conversationId=test', {headers:{'x-user-email':'test@keybuzz.io'}}, r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode, d)); });
"

echo ""
echo "--- Step 8: Non-regression ---"
for EP in "/health" "/ai/governance?tenantId=ecomlg-001" "/ai/controlled-execution?tenantId=ecomlg-001" "/ai/controlled-activation?tenantId=ecomlg-001"; do
  echo ">> $EP"
  kubectl exec -n "$NS" "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:80${EP}', {headers:{'x-user-email':'test@keybuzz.io'}}, r => { let d=''; r.on('data', c => d+=c); r.on('end', () => console.log(r.statusCode)); });
" 2>&1
done

echo ""
echo "=== PH115 PROD PUSH COMPLETE ==="
echo "PROD image: $PROD_TAG"
echo "PROD env vars: AUCUNE activation (DRY_RUN total)"
echo "Rollback: kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.6.16-ph114-real-scaling-prod -n $NS"
