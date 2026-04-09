#!/bin/bash
set -euo pipefail

TAG="v0.2.0-dev"
REGISTRY="ghcr.io/keybuzzio"

echo "=== Rebuilding Frontend ==="
cd /opt/keybuzz/keybuzz-studio
docker build \
  --build-arg NEXT_PUBLIC_APP_ENV=development \
  --build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api-dev.keybuzz.io \
  -t "${REGISTRY}/keybuzz-studio:${TAG}" .
echo "Frontend image built."

docker push "${REGISTRY}/keybuzz-studio:${TAG}"
echo "Frontend image pushed."

echo "--- Rolling out frontend ---"
kubectl rollout restart deployment/keybuzz-studio -n keybuzz-studio-dev
kubectl rollout status deployment/keybuzz-studio -n keybuzz-studio-dev --timeout=120s

echo "--- Rolling out API (already built) ---"
kubectl rollout restart deployment/keybuzz-studio-api -n keybuzz-studio-api-dev
kubectl rollout status deployment/keybuzz-studio-api -n keybuzz-studio-api-dev --timeout=120s

echo "--- Verification ---"
kubectl get pods -n keybuzz-studio-dev
kubectl get pods -n keybuzz-studio-api-dev

sleep 8

echo "--- Health check ---"
kubectl exec -n keybuzz-studio-api-dev deploy/keybuzz-studio-api -- wget -qO- http://localhost:4010/health 2>/dev/null || echo "(wget fallback)"
kubectl exec -n keybuzz-studio-api-dev deploy/keybuzz-studio-api -- wget -qO- http://localhost:4010/api/v1/auth/setup/status 2>/dev/null || echo "(wget fallback)"

echo "--- API logs ---"
kubectl logs deployment/keybuzz-studio-api -n keybuzz-studio-api-dev --tail=15

echo "=== DONE ==="
