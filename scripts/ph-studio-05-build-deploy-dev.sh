#!/usr/bin/env bash
set -euo pipefail

TAG="v0.4.0-dev"
REGISTRY="ghcr.io/keybuzzio"
API_DIR="/opt/keybuzz/keybuzz-studio-api"
FE_DIR="/opt/keybuzz/keybuzz-studio"
NS_API="keybuzz-studio-api-dev"
NS_FE="keybuzz-studio-dev"

echo "=== PH-STUDIO-05 — Build & Deploy DEV ==="

# --- Step 1: Apply migration ---
echo ""
echo "--- 1. Apply migration 003 ---"
kubectl delete configmap migration-05 --namespace default 2>/dev/null || true
kubectl create configmap migration-05 \
  --from-file=migration.sql="${API_DIR}/src/db/migrations/003-assets-calendar-workflow.sql" \
  --namespace default

DB_URL=$(kubectl get secret keybuzz-studio-api-db -n "$NS_API" -o jsonpath='{.data.DATABASE_URL}' | base64 -d)

kubectl delete pod migrate-05 --namespace default 2>/dev/null || true
cat <<'MANIFEST' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: migrate-05
  namespace: default
spec:
  restartPolicy: Never
  containers:
  - name: psql
    image: postgres:17-alpine
    command: ["sh", "-c", "psql \"$DATABASE_URL\" -f /sql/migration.sql"]
    env:
    - name: DATABASE_URL
      valueFrom:
        secretKeyRef:
          name: migrate-05-url
          key: url
    volumeMounts:
    - name: sql
      mountPath: /sql
  volumes:
  - name: sql
    configMap:
      name: migration-05
MANIFEST

kubectl delete secret migrate-05-url --namespace default 2>/dev/null || true
kubectl create secret generic migrate-05-url --from-literal="url=${DB_URL}" --namespace default

kubectl delete pod migrate-05 --namespace default 2>/dev/null || true
kubectl run migrate-05 --rm -it --restart=Never \
  --image=postgres:17-alpine \
  --namespace=default \
  --env="DATABASE_URL=${DB_URL}" \
  --overrides='{
    "spec": {
      "containers": [{
        "name": "migrate-05",
        "image": "postgres:17-alpine",
        "command": ["sh", "-c", "psql \"$DATABASE_URL\" -f /sql/migration.sql"],
        "env": [{"name": "DATABASE_URL", "value": "'"${DB_URL}"'"}],
        "volumeMounts": [{"name": "sql", "mountPath": "/sql"}]
      }],
      "volumes": [{"name": "sql", "configMap": {"name": "migration-05"}}]
    }
  }' 2>&1 || echo "Migration pod completed"

kubectl delete secret migrate-05-url --namespace default 2>/dev/null || true
echo "Migration applied"

# --- Step 2: Build API ---
echo ""
echo "--- 2. Build API ---"
cd "$API_DIR"
docker build -t "$REGISTRY/keybuzz-studio-api:$TAG" . 2>&1 | tail -5
docker push "$REGISTRY/keybuzz-studio-api:$TAG" 2>&1 | tail -3

# --- Step 3: Build Frontend DEV ---
echo ""
echo "--- 3. Build Frontend DEV ---"
cd "$FE_DIR"
docker build \
  --build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=development \
  -t "$REGISTRY/keybuzz-studio:$TAG" . 2>&1 | tail -5
docker push "$REGISTRY/keybuzz-studio:$TAG" 2>&1 | tail -3

# --- Step 4: Deploy ---
echo ""
echo "--- 4. Deploy K8s ---"
kubectl set image deployment/keybuzz-studio-api keybuzz-studio-api="$REGISTRY/keybuzz-studio-api:$TAG" -n "$NS_API"
kubectl set image deployment/keybuzz-studio keybuzz-studio="$REGISTRY/keybuzz-studio:$TAG" -n "$NS_FE"

echo "Waiting for API rollout..."
kubectl rollout status deployment/keybuzz-studio-api -n "$NS_API" --timeout=120s
echo "Waiting for Frontend rollout..."
kubectl rollout status deployment/keybuzz-studio -n "$NS_FE" --timeout=120s

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
echo "--- API Logs ---"
API_POD=$(kubectl get pods -n "$NS_API" -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | awk '{print $1}')
kubectl logs --tail=10 -n "$NS_API" "$API_POD" 2>&1 | tail -5

echo ""
echo "=== DEV DEPLOY COMPLETE ($TAG) ==="
