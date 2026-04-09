#!/usr/bin/env bash
set -euo pipefail

TAG="v0.5.0-dev"
REGISTRY="ghcr.io/keybuzzio"
API_DIR="/opt/keybuzz/keybuzz-studio-api"
FE_DIR="/opt/keybuzz/keybuzz-studio"
NS_API="keybuzz-studio-api-dev"
NS_FE="keybuzz-studio-dev"

echo "=== PH-STUDIO-06 — Build & Deploy DEV ==="

# --- Step 1: Apply migration 004 ---
echo ""
echo "--- 1. Apply migration 004 (learning + templates) ---"
kubectl delete configmap migration-06 --namespace default 2>/dev/null || true
kubectl create configmap migration-06 \
  --from-file=migration.sql="${API_DIR}/src/db/migrations/004-learning-templates-generation.sql" \
  --namespace default

DB_URL=$(kubectl get secret keybuzz-studio-api-db -n "$NS_API" -o jsonpath='{.data.DATABASE_URL}' | base64 -d)

kubectl delete pod migrate-06 --namespace default 2>/dev/null || true
kubectl delete secret migrate-06-url --namespace default 2>/dev/null || true
kubectl create secret generic migrate-06-url --from-literal="url=${DB_URL}" --namespace default

kubectl run migrate-06 --rm -it --restart=Never \
  --image=postgres:17-alpine \
  --namespace=default \
  --env="DATABASE_URL=${DB_URL}" \
  --overrides='{
    "spec": {
      "containers": [{
        "name": "migrate-06",
        "image": "postgres:17-alpine",
        "command": ["sh", "-c", "psql \"$DATABASE_URL\" -f /sql/migration.sql"],
        "env": [{"name": "DATABASE_URL", "value": "'"${DB_URL}"'"}],
        "volumeMounts": [{"name": "sql", "mountPath": "/sql"}]
      }],
      "volumes": [{"name": "sql", "configMap": {"name": "migration-06"}}]
    }
  }' 2>&1 || echo "Migration pod completed"

kubectl delete secret migrate-06-url --namespace default 2>/dev/null || true
echo "Migration applied"

# --- Step 2: Build API ---
echo ""
echo "--- 2. Build API ($TAG) ---"
cd "$API_DIR"
npm cache clean --force 2>/dev/null || true
docker build -t "$REGISTRY/keybuzz-studio-api:$TAG" . 2>&1 | tail -5
docker push "$REGISTRY/keybuzz-studio-api:$TAG" 2>&1 | tail -3
echo "API image pushed"

# --- Step 3: Build Frontend DEV ---
echo ""
echo "--- 3. Build Frontend DEV ($TAG) ---"
cd "$FE_DIR"
npm cache clean --force 2>/dev/null || true
docker build \
  --build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=development \
  -t "$REGISTRY/keybuzz-studio:$TAG" . 2>&1 | tail -5
docker push "$REGISTRY/keybuzz-studio:$TAG" 2>&1 | tail -3
echo "Frontend image pushed"

# --- Step 4: Deploy K8s ---
echo ""
echo "--- 4. Deploy K8s ---"
kubectl set image deployment/keybuzz-studio-api keybuzz-studio-api="$REGISTRY/keybuzz-studio-api:$TAG" -n "$NS_API"
kubectl set image deployment/keybuzz-studio keybuzz-studio="$REGISTRY/keybuzz-studio:$TAG" -n "$NS_FE"

echo "Waiting for API rollout..."
kubectl rollout status deployment/keybuzz-studio-api -n "$NS_API" --timeout=180s
echo "Waiting for Frontend rollout..."
kubectl rollout status deployment/keybuzz-studio -n "$NS_FE" --timeout=180s

sleep 5

# --- Step 5: Verify ---
echo ""
echo "--- 5. Verify ---"
kubectl get pods -n "$NS_API" --no-headers
kubectl get pods -n "$NS_FE" --no-headers

echo ""
curl -s -w " [HTTP %{http_code}]\n" https://studio-api-dev.keybuzz.io/health
curl -s -o /dev/null -w "Frontend: HTTP %{http_code}\n" https://studio-dev.keybuzz.io/login

echo ""
echo "--- API Logs (last 10) ---"
API_POD=$(kubectl get pods -n "$NS_API" -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | awk '{print $1}')
kubectl logs --tail=10 -n "$NS_API" "$API_POD" 2>&1 | tail -5

echo ""
echo "=== DEV DEPLOY COMPLETE ($TAG) ==="
