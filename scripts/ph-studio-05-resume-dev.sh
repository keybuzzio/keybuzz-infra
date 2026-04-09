#!/usr/bin/env bash
set -euo pipefail

TAG="v0.4.0-dev"
REGISTRY="ghcr.io/keybuzzio"
FE_DIR="/opt/keybuzz/keybuzz-studio"
NS_API="keybuzz-studio-api-dev"
NS_FE="keybuzz-studio-dev"

echo "=== PH-STUDIO-05 — Resume: Build Frontend DEV ==="

# Clean npm cache first
npm cache clean --force 2>/dev/null || true

cd "$FE_DIR"
docker build \
  --build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=development \
  -t "$REGISTRY/keybuzz-studio:$TAG" . 2>&1 | tail -10

echo ""
echo "--- Push ---"
docker push "$REGISTRY/keybuzz-studio:$TAG" 2>&1 | tail -3

echo ""
echo "--- Deploy K8s ---"
kubectl set image deployment/keybuzz-studio-api keybuzz-studio-api="$REGISTRY/keybuzz-studio-api:$TAG" -n "$NS_API"
kubectl set image deployment/keybuzz-studio keybuzz-studio="$REGISTRY/keybuzz-studio:$TAG" -n "$NS_FE"

echo "Waiting for API rollout..."
kubectl rollout status deployment/keybuzz-studio-api -n "$NS_API" --timeout=120s
echo "Waiting for Frontend rollout..."
kubectl rollout status deployment/keybuzz-studio -n "$NS_FE" --timeout=120s

sleep 5

echo ""
echo "--- Verify ---"
kubectl get pods -n "$NS_API" --no-headers
kubectl get pods -n "$NS_FE" --no-headers

echo ""
curl -s -w " [HTTP %{http_code}]\n" https://studio-api-dev.keybuzz.io/health
curl -s -o /dev/null -w "Frontend: HTTP %{http_code}\n" https://studio-dev.keybuzz.io/login

echo ""
echo "--- API Logs (last 5 lines) ---"
API_POD=$(kubectl get pods -n "$NS_API" -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | awk '{print $1}')
kubectl logs --tail=5 -n "$NS_API" "$API_POD" 2>&1

echo ""
echo "=== DEV DEPLOY COMPLETE ($TAG) ==="
