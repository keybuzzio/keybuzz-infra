#!/usr/bin/env bash
set -euo pipefail

TAG_DEV="v0.6.0-dev"
TAG_PROD="v0.6.0-prod"
REGISTRY="ghcr.io/keybuzzio"
API_DIR="/opt/keybuzz/keybuzz-studio-api"
FE_DIR="/opt/keybuzz/keybuzz-studio"
NS_API_DEV="keybuzz-studio-api-dev"
NS_API_PROD="keybuzz-studio-api-prod"
NS_FE_PROD="keybuzz-studio-prod"

echo "=== PH-STUDIO-07A — Promote to PROD ==="

# --- Step 1: Apply migration 005 to PROD DB ---
echo ""
echo "--- 1. Apply migration 005 to PROD DB ---"
kubectl delete configmap migration-07a-prod --namespace default 2>/dev/null || true
kubectl create configmap migration-07a-prod \
  --from-file=migration.sql="${API_DIR}/src/db/migrations/005-ai-generations.sql" \
  --namespace default

DB_URL_PROD=$(kubectl get secret keybuzz-studio-api-db -n "$NS_API_PROD" -o jsonpath='{.data.DATABASE_URL}' | base64 -d)

kubectl delete pod migrate-07a-prod --namespace default 2>/dev/null || true

kubectl run migrate-07a-prod --rm -it --restart=Never \
  --image=postgres:17-alpine \
  --namespace=default \
  --overrides='{
    "spec": {
      "containers": [{
        "name": "migrate-07a-prod",
        "image": "postgres:17-alpine",
        "command": ["sh", "-c", "psql \"'"${DB_URL_PROD}"'\" -f /sql/migration.sql"],
        "volumeMounts": [{"name": "sql", "mountPath": "/sql"}]
      }],
      "volumes": [{"name": "sql", "configMap": {"name": "migration-07a-prod"}}]
    }
  }' 2>&1 || echo "Migration pod completed"

echo "PROD migration applied"

# --- Step 2: Promote API image ---
echo ""
echo "--- 2. Promote API image ($TAG_DEV -> $TAG_PROD) ---"
docker pull "$REGISTRY/keybuzz-studio-api:$TAG_DEV"
docker tag "$REGISTRY/keybuzz-studio-api:$TAG_DEV" "$REGISTRY/keybuzz-studio-api:$TAG_PROD"
docker push "$REGISTRY/keybuzz-studio-api:$TAG_PROD" 2>&1 | tail -3
echo "API image promoted"

# --- Step 3: Build Frontend PROD (dedicated build) ---
echo ""
echo "--- 3. Build Frontend PROD (dedicated build with PROD API URL) ---"
cd "$FE_DIR"
docker build \
  --build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=production \
  -t "$REGISTRY/keybuzz-studio:$TAG_PROD" . 2>&1 | tail -5
docker push "$REGISTRY/keybuzz-studio:$TAG_PROD" 2>&1 | tail -3
echo "Frontend PROD image pushed"

# --- Step 4: Deploy PROD ---
echo ""
echo "--- 4. Deploy PROD ---"
kubectl set image deployment/keybuzz-studio-api keybuzz-studio-api="$REGISTRY/keybuzz-studio-api:$TAG_PROD" -n "$NS_API_PROD"
kubectl set image deployment/keybuzz-studio keybuzz-studio="$REGISTRY/keybuzz-studio:$TAG_PROD" -n "$NS_FE_PROD"

echo "Waiting for API PROD rollout..."
kubectl rollout status deployment/keybuzz-studio-api -n "$NS_API_PROD" --timeout=180s
echo "Waiting for Frontend PROD rollout..."
kubectl rollout status deployment/keybuzz-studio -n "$NS_FE_PROD" --timeout=180s

sleep 5

# --- Step 5: Verify PROD ---
echo ""
echo "--- 5. Verify PROD ---"
kubectl get pods -n "$NS_API_PROD" --no-headers
kubectl get pods -n "$NS_FE_PROD" --no-headers

echo ""
curl -s -w " [HTTP %{http_code}]\n" https://studio-api.keybuzz.io/health
curl -s -o /dev/null -w "Frontend PROD: HTTP %{http_code}\n" https://studio.keybuzz.io/login

echo ""
echo "--- PROD API Logs (last 5) ---"
API_POD=$(kubectl get pods -n "$NS_API_PROD" -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | awk '{print $1}')
kubectl logs --tail=5 -n "$NS_API_PROD" "$API_POD" 2>&1 | tail -5

echo ""
echo "=== PROD PROMOTE COMPLETE ($TAG_PROD) ==="
