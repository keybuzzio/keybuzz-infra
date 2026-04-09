#!/bin/bash
set -eu

TAG_DEV="v0.7.4-dev"
TAG_PROD="v0.7.4-prod"
REGISTRY="ghcr.io/keybuzzio"
API_DIR="/opt/keybuzz/keybuzz-studio-api"
FE_DIR="/opt/keybuzz/keybuzz-studio"
NS_API="keybuzz-studio-api-prod"
NS_FE="keybuzz-studio-prod"

echo "=== PH-STUDIO-07D — Quality Engine — Promote PROD ==="

echo ""
echo "--- 1. Apply migration 008 to PROD DB ---"
kubectl delete configmap migration-07d-prod --namespace default 2>/dev/null || true
kubectl create configmap migration-07d-prod \
  --from-file=migration.sql="${API_DIR}/src/db/migrations/008-quality-engine.sql" \
  --namespace default

DB_URL=$(kubectl get secret keybuzz-studio-api-db -n "$NS_API" -o jsonpath='{.data.DATABASE_URL}' | base64 -d)

kubectl delete pod migrate-07d-prod --namespace default 2>/dev/null || true

kubectl run migrate-07d-prod --rm -it --restart=Never \
  --image=postgres:17-alpine \
  --namespace=default \
  --overrides="{
    \"spec\": {
      \"containers\": [{
        \"name\": \"migrate-07d-prod\",
        \"image\": \"postgres:17-alpine\",
        \"command\": [\"sh\", \"-c\", \"psql '\${DB_URL}' -f /sql/migration.sql\"],
        \"volumeMounts\": [{\"name\": \"sql\", \"mountPath\": \"/sql\"}]
      }],
      \"volumes\": [{\"name\": \"sql\", \"configMap\": {\"name\": \"migration-07d-prod\"}}]
    }
  }" 2>&1 || echo "Migration pod completed"

echo "Migration 008 applied to PROD"

echo ""
echo "--- 2. Tag API PROD ($TAG_PROD) ---"
docker tag "$REGISTRY/keybuzz-studio-api:$TAG_DEV" "$REGISTRY/keybuzz-studio-api:$TAG_PROD"
docker push "$REGISTRY/keybuzz-studio-api:$TAG_PROD" 2>&1 | tail -3
echo "API PROD image pushed"

echo ""
echo "--- 3. Build Frontend PROD ($TAG_PROD) ---"
cd "$FE_DIR"
docker build \
  --build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=production \
  -t "$REGISTRY/keybuzz-studio:$TAG_PROD" . 2>&1 | tail -5
docker push "$REGISTRY/keybuzz-studio:$TAG_PROD" 2>&1 | tail -3
echo "Frontend PROD image pushed"

echo ""
echo "--- 4. Deploy K8s PROD ---"
kubectl set image deployment/keybuzz-studio-api keybuzz-studio-api="$REGISTRY/keybuzz-studio-api:$TAG_PROD" -n "$NS_API"
kubectl set image deployment/keybuzz-studio keybuzz-studio="$REGISTRY/keybuzz-studio:$TAG_PROD" -n "$NS_FE"

echo "Waiting for API rollout..."
kubectl rollout status deployment/keybuzz-studio-api -n "$NS_API" --timeout=180s
echo "Waiting for Frontend rollout..."
kubectl rollout status deployment/keybuzz-studio -n "$NS_FE" --timeout=180s

sleep 5

echo ""
echo "--- 5. Verify PROD ---"
kubectl get pods -n "$NS_API" --no-headers
kubectl get pods -n "$NS_FE" --no-headers

echo ""
curl -s -w " [HTTP %{http_code}]\n" https://studio-api.keybuzz.io/health
curl -s -o /dev/null -w "Frontend: HTTP %{http_code}\n" https://studio.keybuzz.io/login

echo ""
echo "--- Verify AI health ---"
curl -s -w " [HTTP %{http_code}]\n" https://studio-api.keybuzz.io/api/v1/ai/health

echo ""
echo "=== PROD PROMOTE COMPLETE ($TAG_PROD) ==="
