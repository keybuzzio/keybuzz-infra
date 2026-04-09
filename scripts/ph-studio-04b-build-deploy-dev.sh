#!/usr/bin/env bash
set -euo pipefail

TAG="v0.3.0-dev"
REGISTRY="ghcr.io/keybuzzio"
API_DIR="/opt/keybuzz/keybuzz-studio-api"
FE_DIR="/opt/keybuzz/keybuzz-studio"
NS_API="keybuzz-studio-api-dev"
NS_FE="keybuzz-studio-dev"

echo "=== PH-STUDIO-04B — Build + Deploy DEV ($TAG) ==="

echo "--- Building API image ---"
cd "$API_DIR"
docker build -t "$REGISTRY/keybuzz-studio-api:$TAG" . 2>&1 | tail -5
echo "API image built"

echo ""
echo "--- Building Frontend image ---"
cd "$FE_DIR"
docker build \
  --build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=development \
  -t "$REGISTRY/keybuzz-studio:$TAG" . 2>&1 | tail -10
echo "Frontend image built"

echo ""
echo "--- Pushing images ---"
docker push "$REGISTRY/keybuzz-studio-api:$TAG" 2>&1 | tail -3
docker push "$REGISTRY/keybuzz-studio:$TAG" 2>&1 | tail -3
echo "Images pushed"

echo ""
echo "--- Updating deployments ---"
kubectl set image deployment/keybuzz-studio-api keybuzz-studio-api="$REGISTRY/keybuzz-studio-api:$TAG" -n "$NS_API"
kubectl set image deployment/keybuzz-studio keybuzz-studio="$REGISTRY/keybuzz-studio:$TAG" -n "$NS_FE"

echo ""
echo "--- Waiting for rollouts ---"
kubectl rollout status deployment/keybuzz-studio-api -n "$NS_API" --timeout=120s
kubectl rollout status deployment/keybuzz-studio -n "$NS_FE" --timeout=120s

echo ""
echo "--- Pods ---"
kubectl get pods -n "$NS_API" --no-headers
kubectl get pods -n "$NS_FE" --no-headers

sleep 5

echo ""
echo "--- Health + auth checks ---"
curl -s https://studio-api-dev.keybuzz.io/health
echo ""
curl -s https://studio-api-dev.keybuzz.io/api/v1/auth/setup/status
echo ""
curl -s -o /dev/null -w "Frontend login: HTTP %{http_code}\n" https://studio-dev.keybuzz.io/login

echo ""
echo "--- API logs ---"
kubectl logs deployment/keybuzz-studio-api -n "$NS_API" --tail=15

echo ""
echo "=== DEV BUILD + DEPLOY COMPLETE ==="
