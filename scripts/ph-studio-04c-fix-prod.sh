#!/usr/bin/env bash
set -euo pipefail

TAG="v0.3.1-prod"
REGISTRY="ghcr.io/keybuzzio"
FE_DIR="/opt/keybuzz/keybuzz-studio"
NS_FE="keybuzz-studio-prod"

echo "=== PH-STUDIO-04C — Rebuild PROD Frontend ==="

echo "--- Building PROD frontend with correct API URL ---"
cd "$FE_DIR"
docker build \
  --build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=production \
  -t "$REGISTRY/keybuzz-studio:$TAG" . 2>&1 | tail -10

echo ""
echo "--- Verifying baked URL ---"
CONTAINER_ID=$(docker create "$REGISTRY/keybuzz-studio:$TAG")
BAKED_URL=$(docker run --rm "$REGISTRY/keybuzz-studio:$TAG" grep -r "studio-api" /app/.next/static/ 2>/dev/null | grep -oE 'https://studio-api[a-z\-]*\.keybuzz\.io' | sort -u || echo "NOT FOUND")
echo "Baked URL: $BAKED_URL"

echo ""
echo "--- Pushing PROD image ---"
docker push "$REGISTRY/keybuzz-studio:$TAG" 2>&1 | tail -3

echo ""
echo "--- Updating PROD deployment ---"
kubectl set image deployment/keybuzz-studio keybuzz-studio="$REGISTRY/keybuzz-studio:$TAG" -n "$NS_FE"

echo ""
echo "--- Waiting for rollout ---"
kubectl rollout status deployment/keybuzz-studio -n "$NS_FE" --timeout=120s

echo ""
echo "--- Pods ---"
kubectl get pods -n "$NS_FE" --no-headers

sleep 5

echo ""
echo "--- Verify baked URL in running pod ---"
PROD_POD=$(kubectl get pods -n "$NS_FE" -l app=keybuzz-studio -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || kubectl get pods -n "$NS_FE" --no-headers -o custom-columns=':metadata.name' | head -1)
echo "Pod: $PROD_POD"
kubectl exec -n "$NS_FE" "$PROD_POD" -- grep -r "studio-api" /app/.next/static/ 2>/dev/null | grep -oE 'https://studio-api[a-z\-]*\.keybuzz\.io' | sort -u || echo "check failed"

echo ""
echo "--- Frontend check ---"
curl -s -o /dev/null -w "Login page: HTTP %{http_code}\n" https://studio.keybuzz.io/login

echo ""
echo "--- CORS preflight from browser perspective ---"
curl -s -o /dev/null -w "CORS preflight: HTTP %{http_code}\n" \
  -H "Origin: https://studio.keybuzz.io" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type" \
  -X OPTIONS https://studio-api.keybuzz.io/api/v1/auth/request-otp

echo ""
echo "=== PROD FRONTEND FIX COMPLETE ($TAG) ==="
