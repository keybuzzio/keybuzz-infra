#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=VAULT_TOKEN_REDACTED

TAG="v0.1.0-dev"
API_IMAGE="ghcr.io/keybuzzio/keybuzz-studio-api:${TAG}"
FRONTEND_IMAGE="ghcr.io/keybuzzio/keybuzz-studio:${TAG}"

echo "=== Git pull ==="
cd /opt/keybuzz/keybuzz-client
git pull origin main 2>&1 | tail -5
GIT_SHA=$(git rev-parse --short HEAD)
echo "Git SHA: $GIT_SHA"

echo ""
echo "=== Rebuild API only ==="
cd /opt/keybuzz/keybuzz-client/keybuzz-studio-api
docker build --no-cache -t "$API_IMAGE" . 2>&1 | tail -10
echo ""

echo "=== Push both ==="
docker push "$FRONTEND_IMAGE" 2>&1 | tail -3
docker push "$API_IMAGE" 2>&1 | tail -3
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
echo "Waiting 45s for pods..."
sleep 45

echo ""
echo "=== Pods ==="
kubectl get pods -n keybuzz-studio-dev -o wide
echo ""
kubectl get pods -n keybuzz-studio-api-dev -o wide
echo ""

echo "=== Services ==="
kubectl get svc -n keybuzz-studio-dev
kubectl get svc -n keybuzz-studio-api-dev
echo ""

echo "=== Ingress ==="
kubectl get ingress -n keybuzz-studio-dev
kubectl get ingress -n keybuzz-studio-api-dev
echo ""

echo "=== Health Check ==="
API_POD=$(kubectl get pods -n keybuzz-studio-api-dev -l app=keybuzz-studio-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$API_POD" ]; then
  kubectl exec -n keybuzz-studio-api-dev "$API_POD" -- wget -qO- http://localhost:4010/health 2>/dev/null && echo "" || echo "Health check failed"
fi

echo ""
echo "=== Logs Frontend (last 15) ==="
kubectl logs -n keybuzz-studio-dev deployment/keybuzz-studio --tail=15 2>&1 || true
echo ""
echo "=== Logs API (last 15) ==="
kubectl logs -n keybuzz-studio-api-dev deployment/keybuzz-studio-api --tail=15 2>&1 || true

echo ""
echo "========================================"
echo "  DEPLOY COMPLETE — $GIT_SHA"
echo "========================================"
docker images | grep keybuzz-studio
