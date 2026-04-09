#!/usr/bin/env bash
set -euo pipefail

DEV_TAG="v0.4.0-dev"
PROD_TAG="v0.4.0-prod"
REGISTRY="ghcr.io/keybuzzio"
FE_DIR="/opt/keybuzz/keybuzz-studio"
NS_API_PROD="keybuzz-studio-api-prod"
NS_FE_PROD="keybuzz-studio-prod"
NS_API_DEV="keybuzz-studio-api-dev"

echo "=== PH-STUDIO-05 — Promote to PROD ==="

# --- 1. Apply migration to PROD DB ---
echo ""
echo "--- 1. Apply migration 003 to PROD ---"
kubectl delete configmap migration-05-prod --namespace default 2>/dev/null || true
kubectl create configmap migration-05-prod \
  --from-file=migration.sql="/opt/keybuzz/keybuzz-studio-api/src/db/migrations/003-assets-calendar-workflow.sql" \
  --namespace default

DB_URL=$(kubectl get secret keybuzz-studio-api-db -n "$NS_API_PROD" -o jsonpath='{.data.DATABASE_URL}' | base64 -d)

kubectl delete pod migrate-05-prod --namespace default 2>/dev/null || true
kubectl run migrate-05-prod --rm -it --restart=Never \
  --image=postgres:17-alpine \
  --namespace=default \
  --env="DATABASE_URL=${DB_URL}" \
  --overrides='{
    "spec": {
      "containers": [{
        "name": "migrate-05-prod",
        "image": "postgres:17-alpine",
        "command": ["sh", "-c", "psql \"$DATABASE_URL\" -f /sql/migration.sql"],
        "env": [{"name": "DATABASE_URL", "value": "'"${DB_URL}"'"}],
        "volumeMounts": [{"name": "sql", "mountPath": "/sql"}]
      }],
      "volumes": [{"name": "sql", "configMap": {"name": "migration-05-prod"}}]
    }
  }' 2>&1 || echo "Migration pod completed"

echo "PROD migration applied"

# --- 2. API: re-tag DEV → PROD (backend env vars are runtime) ---
echo ""
echo "--- 2. Tag API PROD ---"
docker tag "$REGISTRY/keybuzz-studio-api:$DEV_TAG" "$REGISTRY/keybuzz-studio-api:$PROD_TAG"
docker push "$REGISTRY/keybuzz-studio-api:$PROD_TAG" 2>&1 | tail -3

# --- 3. Frontend: dedicated PROD build (NEXT_PUBLIC_ baked at build time) ---
echo ""
echo "--- 3. Build Frontend PROD (dedicated) ---"
cd "$FE_DIR"
docker build \
  --build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=production \
  -t "$REGISTRY/keybuzz-studio:$PROD_TAG" . 2>&1 | tail -5
docker push "$REGISTRY/keybuzz-studio:$PROD_TAG" 2>&1 | tail -3

# --- 4. Deploy PROD ---
echo ""
echo "--- 4. Deploy PROD ---"
kubectl set image deployment/keybuzz-studio-api keybuzz-studio-api="$REGISTRY/keybuzz-studio-api:$PROD_TAG" -n "$NS_API_PROD"
kubectl set image deployment/keybuzz-studio keybuzz-studio="$REGISTRY/keybuzz-studio:$PROD_TAG" -n "$NS_FE_PROD"

echo "Waiting for API rollout..."
kubectl rollout status deployment/keybuzz-studio-api -n "$NS_API_PROD" --timeout=120s
echo "Waiting for Frontend rollout..."
kubectl rollout status deployment/keybuzz-studio -n "$NS_FE_PROD" --timeout=120s

sleep 5

# --- 5. Verify PROD ---
echo ""
echo "--- 5. Verify PROD ---"
kubectl get pods -n "$NS_API_PROD" --no-headers
kubectl get pods -n "$NS_FE_PROD" --no-headers

echo ""
curl -s -w " [HTTP %{http_code}]\n" https://studio-api.keybuzz.io/health
curl -s -o /dev/null -w "Frontend: HTTP %{http_code}\n" https://studio.keybuzz.io/login

# Verify baked URL
echo ""
echo "--- Baked URL check ---"
PROD_POD=$(kubectl get pods -n "$NS_FE_PROD" -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | awk '{print $1}')
kubectl exec -n "$NS_FE_PROD" "$PROD_POD" -- grep -r "studio-api" /app/.next/static/ 2>/dev/null | grep -oE 'https://studio-api[a-z\-]*\.keybuzz\.io' | sort -u

# CORS check
echo ""
echo "--- CORS check ---"
curl -s -o /dev/null -w "CORS preflight: HTTP %{http_code}\n" \
  -H "Origin: https://studio.keybuzz.io" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type" \
  -X OPTIONS https://studio-api.keybuzz.io/api/v1/auth/request-otp

# Quick API test
echo ""
echo "--- PROD API test ---"
curl -s -w " [HTTP %{http_code}]\n" -X POST https://studio-api.keybuzz.io/api/v1/auth/request-otp \
  -H "Content-Type: application/json" -d '{"email":"ludovic@keybuzz.pro"}'

# Clean docker space
docker system prune -f 2>/dev/null | tail -1 || true

echo ""
echo "=== PROD PROMOTION COMPLETE ($PROD_TAG) ==="
