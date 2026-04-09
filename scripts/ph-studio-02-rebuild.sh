#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=VAULT_TOKEN_REDACTED

TAG="v0.1.0-dev"
FRONTEND_IMAGE="ghcr.io/keybuzzio/keybuzz-studio:${TAG}"
API_IMAGE="ghcr.io/keybuzzio/keybuzz-studio-api:${TAG}"

echo "=== Git pull ==="
cd /opt/keybuzz/keybuzz-client
git pull origin main 2>&1 | tail -3

GIT_SHA=$(git rev-parse --short HEAD)
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "Git SHA: $GIT_SHA"

echo ""
echo "=== Build Frontend ==="
cd /opt/keybuzz/keybuzz-client/keybuzz-studio
docker build --no-cache \
  --build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=development \
  --build-arg GIT_COMMIT_SHA="$GIT_SHA" \
  --build-arg BUILD_TIME="$BUILD_TIME" \
  -t "$FRONTEND_IMAGE" . 2>&1 | tail -20
echo ""

echo "=== Build API ==="
cd /opt/keybuzz/keybuzz-client/keybuzz-studio-api
docker build --no-cache -t "$API_IMAGE" . 2>&1 | tail -20
echo ""

echo "=== Push ==="
docker push "$FRONTEND_IMAGE" 2>&1 | tail -5
docker push "$API_IMAGE" 2>&1 | tail -5
echo ""

echo "=== K8s Setup ==="
kubectl create namespace keybuzz-studio-dev --dry-run=client -o yaml | kubectl apply -f - 2>&1
kubectl create namespace keybuzz-studio-api-dev --dry-run=client -o yaml | kubectl apply -f - 2>&1

GHCR_JSON=$(kubectl get secret ghcr-cred -n keybuzz-client-dev -o json 2>/dev/null || echo "")
if [ -n "$GHCR_JSON" ]; then
  echo "$GHCR_JSON" | jq '.metadata.namespace="keybuzz-studio-dev" | del(.metadata.resourceVersion,.metadata.uid,.metadata.creationTimestamp,.metadata.annotations)' | kubectl apply -f - 2>&1
  echo "$GHCR_JSON" | jq '.metadata.namespace="keybuzz-studio-api-dev" | del(.metadata.resourceVersion,.metadata.uid,.metadata.creationTimestamp,.metadata.annotations)' | kubectl apply -f - 2>&1
fi

DB_URL=$(vault kv get -field=DATABASE_URL secret/keybuzz/dev/studio-postgres 2>/dev/null || echo "postgresql://kb_backend:7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8@10.0.0.10:5432/keybuzz_backend")
kubectl create secret generic keybuzz-studio-api-db \
  --namespace=keybuzz-studio-api-dev \
  --from-literal=DATABASE_URL="$DB_URL" \
  --dry-run=client -o yaml | kubectl apply -f - 2>&1

echo ""
echo "=== Deploy ==="
cd /opt/keybuzz/keybuzz-client/keybuzz-infra
kubectl apply -f k8s/keybuzz-studio-dev/ 2>&1
kubectl apply -f k8s/keybuzz-studio-api-dev/ 2>&1

echo ""
echo "Waiting 40s..."
sleep 40

echo ""
echo "=== Pods ==="
kubectl get pods -n keybuzz-studio-dev
kubectl get pods -n keybuzz-studio-api-dev
echo ""

echo "=== Health ==="
API_POD=$(kubectl get pods -n keybuzz-studio-api-dev -l app=keybuzz-studio-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$API_POD" ]; then
  kubectl exec -n keybuzz-studio-api-dev "$API_POD" -- wget -qO- http://localhost:4010/health 2>/dev/null || echo "Health check pending"
fi

echo ""
echo "=== Logs Frontend ==="
kubectl logs -n keybuzz-studio-dev deployment/keybuzz-studio --tail=10 2>&1 || true
echo ""
echo "=== Logs API ==="
kubectl logs -n keybuzz-studio-api-dev deployment/keybuzz-studio-api --tail=10 2>&1 || true

echo ""
echo "=== DONE ==="
echo "Frontend: $FRONTEND_IMAGE ($GIT_SHA)"
echo "API: $API_IMAGE ($GIT_SHA)"
docker images | grep keybuzz-studio
