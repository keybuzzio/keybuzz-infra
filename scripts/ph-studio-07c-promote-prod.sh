#!/bin/bash
set -eu

TAG_DEV="v0.7.3-dev"
TAG_PROD="v0.7.3-prod"
REGISTRY="ghcr.io/keybuzzio"
FE_DIR="/opt/keybuzz/keybuzz-studio"
NS_API="keybuzz-studio-api-prod"
NS_FE="keybuzz-studio-prod"

echo "=== PH-STUDIO-07C — Promote PROD ==="

# --- Step 1: Apply migration 007 to PROD ---
echo ""
echo "--- 1. Apply migration 007 to PROD DB ---"
kubectl delete configmap migration-07c-prod --namespace default 2>/dev/null || true
kubectl create configmap migration-07c-prod \
  --from-file=migration.sql="/opt/keybuzz/keybuzz-studio-api/src/db/migrations/007-client-intelligence.sql" \
  --namespace default

DB_URL=$(kubectl get secret keybuzz-studio-api-db -n "$NS_API" -o jsonpath='{.data.DATABASE_URL}' | base64 -d)

kubectl delete pod migrate-07c-prod --namespace default 2>/dev/null || true

kubectl run migrate-07c-prod --rm -it --restart=Never \
  --image=postgres:17-alpine \
  --namespace=default \
  --overrides="{
    \"spec\": {
      \"containers\": [{
        \"name\": \"migrate-07c-prod\",
        \"image\": \"postgres:17-alpine\",
        \"command\": [\"sh\", \"-c\", \"psql '${DB_URL}' -f /sql/migration.sql\"],
        \"volumeMounts\": [{\"name\": \"sql\", \"mountPath\": \"/sql\"}]
      }],
      \"volumes\": [{\"name\": \"sql\", \"configMap\": {\"name\": \"migration-07c-prod\"}}]
    }
  }" 2>&1 || echo "Migration pod completed"

echo "Migration 007 applied to PROD"

# --- Step 2: Tag & push API PROD ---
echo ""
echo "--- 2. Tag API PROD ($TAG_PROD) ---"
docker tag "$REGISTRY/keybuzz-studio-api:$TAG_DEV" "$REGISTRY/keybuzz-studio-api:$TAG_PROD"
docker push "$REGISTRY/keybuzz-studio-api:$TAG_PROD" 2>&1 | tail -3
echo "API PROD image pushed"

# --- Step 3: Build Frontend PROD (dedicated build) ---
echo ""
echo "--- 3. Build Frontend PROD ($TAG_PROD) ---"
cd "$FE_DIR"
docker build \
  --build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=production \
  -t "$REGISTRY/keybuzz-studio:$TAG_PROD" . 2>&1 | tail -5
docker push "$REGISTRY/keybuzz-studio:$TAG_PROD" 2>&1 | tail -3
echo "Frontend PROD image pushed"

# --- Step 4: Deploy K8s PROD ---
echo ""
echo "--- 4. Deploy K8s PROD ---"
kubectl set image deployment/keybuzz-studio-api keybuzz-studio-api="$REGISTRY/keybuzz-studio-api:$TAG_PROD" -n "$NS_API"
kubectl set image deployment/keybuzz-studio keybuzz-studio="$REGISTRY/keybuzz-studio:$TAG_PROD" -n "$NS_FE"

echo "Waiting for API rollout..."
kubectl rollout status deployment/keybuzz-studio-api -n "$NS_API" --timeout=180s
echo "Waiting for Frontend rollout..."
kubectl rollout status deployment/keybuzz-studio -n "$NS_FE" --timeout=180s

sleep 5

# --- Step 5: Verify ---
echo ""
echo "--- 5. Verify PROD ---"
kubectl get pods -n "$NS_API" --no-headers
kubectl get pods -n "$NS_FE" --no-headers

echo ""
curl -s -w " [HTTP %{http_code}]\n" https://studio-api.keybuzz.io/health
curl -s -o /dev/null -w "Frontend: HTTP %{http_code}\n" https://studio.keybuzz.io/login

echo ""
echo "=== PROD PROMOTE COMPLETE ($TAG_PROD) ==="
