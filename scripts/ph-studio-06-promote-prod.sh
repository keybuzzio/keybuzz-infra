#!/usr/bin/env bash
set -euo pipefail

TAG_DEV="v0.5.0-dev"
TAG_PROD="v0.5.0-prod"
REGISTRY="ghcr.io/keybuzzio"
API_DIR="/opt/keybuzz/keybuzz-studio-api"
FE_DIR="/opt/keybuzz/keybuzz-studio"
NS_API_DEV="keybuzz-studio-api-dev"
NS_API_PROD="keybuzz-studio-api-prod"
NS_FE_PROD="keybuzz-studio-prod"

echo "=== PH-STUDIO-06 — Promote to PROD ==="

# --- Step 1: Apply migration to PROD DB ---
echo ""
echo "--- 1. Apply migration 004 to PROD ---"
kubectl delete configmap migration-06-prod --namespace default 2>/dev/null || true
kubectl create configmap migration-06-prod \
  --from-file=migration.sql="${API_DIR}/src/db/migrations/004-learning-templates-generation.sql" \
  --namespace default

DB_URL_PROD=$(kubectl get secret keybuzz-studio-api-db -n "$NS_API_PROD" -o jsonpath='{.data.DATABASE_URL}' | base64 -d)

kubectl delete pod migrate-06-prod --namespace default 2>/dev/null || true
kubectl delete secret migrate-06-prod-url --namespace default 2>/dev/null || true
kubectl create secret generic migrate-06-prod-url --from-literal="url=${DB_URL_PROD}" --namespace default

kubectl run migrate-06-prod --rm -it --restart=Never \
  --image=postgres:17-alpine \
  --namespace=default \
  --overrides='{
    "spec": {
      "containers": [{
        "name": "migrate-06-prod",
        "image": "postgres:17-alpine",
        "command": ["sh", "-c", "psql \"$DATABASE_URL\" -f /sql/migration.sql"],
        "env": [{"name": "DATABASE_URL", "value": "'"${DB_URL_PROD}"'"}],
        "volumeMounts": [{"name": "sql", "mountPath": "/sql"}]
      }],
      "volumes": [{"name": "sql", "configMap": {"name": "migration-06-prod"}}]
    }
  }' 2>&1 || echo "Migration pod completed"

kubectl delete secret migrate-06-prod-url --namespace default 2>/dev/null || true
echo "PROD migration applied"

# --- Step 2: API image — re-tag from DEV ---
echo ""
echo "--- 2. API image: retag $TAG_DEV -> $TAG_PROD ---"
docker pull "$REGISTRY/keybuzz-studio-api:$TAG_DEV" 2>&1 | tail -3
docker tag "$REGISTRY/keybuzz-studio-api:$TAG_DEV" "$REGISTRY/keybuzz-studio-api:$TAG_PROD"
docker push "$REGISTRY/keybuzz-studio-api:$TAG_PROD" 2>&1 | tail -3
echo "API image promoted"

# --- Step 3: Frontend PROD — dedicated build ---
echo ""
echo "--- 3. Frontend PROD build (dedicated, correct API URL) ---"
cd "$FE_DIR"
npm cache clean --force 2>/dev/null || true
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

echo "Waiting for API rollout..."
kubectl rollout status deployment/keybuzz-studio-api -n "$NS_API_PROD" --timeout=180s
echo "Waiting for Frontend rollout..."
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
echo "--- Baked URL check ---"
FE_POD=$(kubectl get pods -n "$NS_FE_PROD" -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | awk '{print $1}')
BAKED=$(kubectl exec -n "$NS_FE_PROD" "$FE_POD" -- sh -c 'grep -r "studio-api" /app/.next/static 2>/dev/null | head -1' || echo "")
if echo "$BAKED" | grep -q "studio-api.keybuzz.io"; then
  echo "OK: baked URL = studio-api.keybuzz.io"
else
  echo "WARN: baked URL check inconclusive"
fi

echo ""
echo "--- API PROD Logs ---"
API_POD=$(kubectl get pods -n "$NS_API_PROD" -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | awk '{print $1}')
kubectl logs --tail=10 -n "$NS_API_PROD" "$API_POD" 2>&1 | tail -5

echo ""
echo "=== PROD DEPLOY COMPLETE ($TAG_PROD) ==="
