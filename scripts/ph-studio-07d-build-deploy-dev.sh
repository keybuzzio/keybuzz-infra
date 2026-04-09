#!/bin/bash
set -eu

TAG="v0.7.4-dev"
REGISTRY="ghcr.io/keybuzzio"
API_DIR="/opt/keybuzz/keybuzz-studio-api"
FE_DIR="/opt/keybuzz/keybuzz-studio"
NS_API="keybuzz-studio-api-dev"
NS_FE="keybuzz-studio-dev"

echo "=== PH-STUDIO-07D — Quality Engine — Build & Deploy DEV ==="

echo ""
echo "--- 1. Apply migration 008 (quality engine) ---"
kubectl delete configmap migration-07d --namespace default 2>/dev/null || true
kubectl create configmap migration-07d \
  --from-file=migration.sql="${API_DIR}/src/db/migrations/008-quality-engine.sql" \
  --namespace default

DB_URL=$(kubectl get secret keybuzz-studio-api-db -n "$NS_API" -o jsonpath='{.data.DATABASE_URL}' | base64 -d)

kubectl delete pod migrate-07d --namespace default 2>/dev/null || true

kubectl run migrate-07d --rm -it --restart=Never \
  --image=postgres:17-alpine \
  --namespace=default \
  --overrides="{
    \"spec\": {
      \"containers\": [{
        \"name\": \"migrate-07d\",
        \"image\": \"postgres:17-alpine\",
        \"command\": [\"sh\", \"-c\", \"psql '\${DB_URL}' -f /sql/migration.sql\"],
        \"volumeMounts\": [{\"name\": \"sql\", \"mountPath\": \"/sql\"}]
      }],
      \"volumes\": [{\"name\": \"sql\", \"configMap\": {\"name\": \"migration-07d\"}}]
    }
  }" 2>&1 || echo "Migration pod completed"

echo "Migration 008 applied"

echo ""
echo "--- 2. Build API ($TAG) ---"
cd "$API_DIR"
git pull --rebase 2>/dev/null || true
docker build -t "$REGISTRY/keybuzz-studio-api:$TAG" . 2>&1 | tail -5
docker push "$REGISTRY/keybuzz-studio-api:$TAG" 2>&1 | tail -3
echo "API image pushed"

echo ""
echo "--- 3. Build Frontend DEV ($TAG) ---"
cd "$FE_DIR"
git pull --rebase 2>/dev/null || true
docker build \
  --build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=development \
  -t "$REGISTRY/keybuzz-studio:$TAG" . 2>&1 | tail -5
docker push "$REGISTRY/keybuzz-studio:$TAG" 2>&1 | tail -3
echo "Frontend image pushed"

echo ""
echo "--- 4. Deploy K8s ---"
kubectl set image deployment/keybuzz-studio-api keybuzz-studio-api="$REGISTRY/keybuzz-studio-api:$TAG" -n "$NS_API"
kubectl set image deployment/keybuzz-studio keybuzz-studio="$REGISTRY/keybuzz-studio:$TAG" -n "$NS_FE"

echo "Waiting for API rollout..."
kubectl rollout status deployment/keybuzz-studio-api -n "$NS_API" --timeout=180s
echo "Waiting for Frontend rollout..."
kubectl rollout status deployment/keybuzz-studio -n "$NS_FE" --timeout=180s

sleep 5

echo ""
echo "--- 5. Verify ---"
kubectl get pods -n "$NS_API" --no-headers
kubectl get pods -n "$NS_FE" --no-headers

echo ""
curl -s -w " [HTTP %{http_code}]\n" https://studio-api-dev.keybuzz.io/health
curl -s -o /dev/null -w "Frontend: HTTP %{http_code}\n" https://studio-dev.keybuzz.io/login

echo ""
echo "--- Verify AI health ---"
curl -s -w " [HTTP %{http_code}]\n" https://studio-api-dev.keybuzz.io/api/v1/ai/health

echo ""
echo "--- API Logs (last 10) ---"
API_POD=$(kubectl get pods -n "$NS_API" -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | awk '{print $1}')
kubectl logs --tail=10 -n "$NS_API" "$API_POD" 2>&1 | tail -5

echo ""
echo "=== DEV DEPLOY COMPLETE ($TAG) ==="
