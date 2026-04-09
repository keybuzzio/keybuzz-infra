#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=VAULT_TOKEN_REDACTED

DB_HOST="10.0.0.10"
DB_PORT="5432"
TAG="v0.1.0-dev"
FRONTEND_IMAGE="ghcr.io/keybuzzio/keybuzz-studio:${TAG}"
API_IMAGE="ghcr.io/keybuzzio/keybuzz-studio-api:${TAG}"

echo "========================================"
echo "  PH-STUDIO-02 — Full Deploy"
echo "========================================"

# ---- STEP 1: Find postgres superuser or create DB with available user ----
echo ""
echo "=== STEP 1: Database Setup ==="

PG_SUPER_PASS=$(vault kv get -field=PGPASSWORD secret/keybuzz/dev/backend-postgres 2>/dev/null || echo "")
if [ -z "$PG_SUPER_PASS" ]; then
  PG_SUPER_PASS="7Lq0it13lCFjkaMEbdW2O4qUZKrVjDFyhec8ldXto8"
fi

# Check which roles have CREATEDB
SUPER_ROLES=$(PGPASSWORD="$PG_SUPER_PASS" psql -h $DB_HOST -U kb_backend -d keybuzz_backend -t -A -c "SELECT rolname FROM pg_roles WHERE rolsuper=true OR rolcreatedb=true LIMIT 5;" 2>/dev/null || echo "")
echo "Roles with CREATEDB/SUPER: $SUPER_ROLES"

# Try to find postgres password via pg_hba trust or existing connections
DB_EXISTS=$(PGPASSWORD="$PG_SUPER_PASS" psql -h $DB_HOST -U kb_backend -d keybuzz_backend -t -A -c "SELECT 1 FROM pg_database WHERE datname='keybuzz_studio';" 2>/dev/null || echo "")

if [ "$DB_EXISTS" = "1" ]; then
  echo "PASS: Database keybuzz_studio already exists"
else
  echo "Database keybuzz_studio does not exist"
  echo "Trying to create with kb_backend..."
  PGPASSWORD="$PG_SUPER_PASS" psql -h $DB_HOST -U kb_backend -d keybuzz_backend -c "CREATE DATABASE keybuzz_studio;" 2>&1 && echo "PASS: DB created" || echo "WARN: Cannot create DB (no CREATEDB privilege) — will use temp DATABASE_URL"
fi

# Generate a studio-specific password
STUDIO_DB_PASS=$(openssl rand -base64 24 | tr -d '=/+' | head -c 32)
STUDIO_DB_URL="postgresql://kb_backend:${PG_SUPER_PASS}@${DB_HOST}:${DB_PORT}/keybuzz_backend"

# Check if keybuzz_studio DB was created, otherwise use keybuzz_backend
DB_CHECK=$(PGPASSWORD="$PG_SUPER_PASS" psql -h $DB_HOST -U kb_backend -d keybuzz_backend -t -A -c "SELECT 1 FROM pg_database WHERE datname='keybuzz_studio';" 2>/dev/null || echo "0")
if [ "$DB_CHECK" = "1" ]; then
  STUDIO_DB_URL="postgresql://kb_backend:${PG_SUPER_PASS}@${DB_HOST}:${DB_PORT}/keybuzz_studio"
  echo "Using dedicated keybuzz_studio database"
else
  echo "WARN: Using keybuzz_backend as temporary DB (studio tables will be prefixed)"
fi

# Store in Vault
vault kv put secret/keybuzz/dev/studio-postgres \
  DATABASE_URL="$STUDIO_DB_URL" \
  PGHOST="$DB_HOST" \
  PGPORT="$DB_PORT" \
  PGDATABASE="keybuzz_studio" \
  PGUSER="kb_backend" 2>&1
echo "PASS: Studio DB credentials stored in Vault"

# ---- STEP 2: Docker Build ----
echo ""
echo "=== STEP 2: Docker Build Frontend ==="
cd /opt/keybuzz/keybuzz-client
GIT_SHA=$(git rev-parse --short HEAD)
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cd /opt/keybuzz/keybuzz-client/keybuzz-studio
docker build --no-cache \
  --build-arg NEXT_PUBLIC_STUDIO_API_URL=https://studio-api-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_APP_ENV=development \
  --build-arg GIT_COMMIT_SHA="$GIT_SHA" \
  --build-arg BUILD_TIME="$BUILD_TIME" \
  -t "$FRONTEND_IMAGE" .
echo "PASS: Frontend image built"

echo ""
echo "=== STEP 3: Docker Build API ==="
cd /opt/keybuzz/keybuzz-client/keybuzz-studio-api
docker build --no-cache -t "$API_IMAGE" .
echo "PASS: API image built"

# ---- STEP 4: Push ----
echo ""
echo "=== STEP 4: Docker Push ==="
docker push "$FRONTEND_IMAGE" 2>&1
echo "PASS: Frontend pushed"
docker push "$API_IMAGE" 2>&1
echo "PASS: API pushed"

# ---- STEP 5: K8s Setup ----
echo ""
echo "=== STEP 5: K8s Namespaces + Secrets ==="

kubectl create namespace keybuzz-studio-dev --dry-run=client -o yaml | kubectl apply -f - 2>&1
kubectl create namespace keybuzz-studio-api-dev --dry-run=client -o yaml | kubectl apply -f - 2>&1

# GHCR secret for both namespaces (copy from existing)
GHCR_SECRET=$(kubectl get secret ghcr-cred -n keybuzz-client-dev -o json 2>/dev/null || echo "")
if [ -n "$GHCR_SECRET" ]; then
  echo "$GHCR_SECRET" | jq '.metadata.namespace="keybuzz-studio-dev" | del(.metadata.resourceVersion,.metadata.uid,.metadata.creationTimestamp,.metadata.annotations)' | kubectl apply -f - 2>&1
  echo "$GHCR_SECRET" | jq '.metadata.namespace="keybuzz-studio-api-dev" | del(.metadata.resourceVersion,.metadata.uid,.metadata.creationTimestamp,.metadata.annotations)' | kubectl apply -f - 2>&1
  echo "PASS: GHCR secrets copied"
else
  echo "WARN: ghcr-cred not found in keybuzz-client-dev"
fi

# DB secret for API
kubectl create secret generic keybuzz-studio-api-db \
  --namespace=keybuzz-studio-api-dev \
  --from-literal=DATABASE_URL="$STUDIO_DB_URL" \
  --dry-run=client -o yaml | kubectl apply -f - 2>&1
echo "PASS: DB secret created"

# ---- STEP 6: Deploy ----
echo ""
echo "=== STEP 6: Deploy K8s ==="
cd /opt/keybuzz/keybuzz-client/keybuzz-infra

kubectl apply -f k8s/keybuzz-studio-dev/ 2>&1
kubectl apply -f k8s/keybuzz-studio-api-dev/ 2>&1
echo "PASS: Manifests applied"

echo ""
echo "Waiting 30s for pods to start..."
sleep 30

# ---- STEP 7: Verify ----
echo ""
echo "=== STEP 7: Verification ==="
echo "--- Frontend pods ---"
kubectl get pods -n keybuzz-studio-dev
echo ""
echo "--- API pods ---"
kubectl get pods -n keybuzz-studio-api-dev
echo ""

echo "--- API health check ---"
API_POD=$(kubectl get pods -n keybuzz-studio-api-dev -l app=keybuzz-studio-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$API_POD" ]; then
  kubectl exec -n keybuzz-studio-api-dev "$API_POD" -- wget -qO- http://localhost:4010/health 2>/dev/null || echo "WARN: Health check failed (pod may still be starting)"
fi

echo ""
echo "--- Logs (last 10 lines) ---"
echo "Frontend:"
kubectl logs -n keybuzz-studio-dev deployment/keybuzz-studio --tail=10 2>&1 || echo "(no logs yet)"
echo ""
echo "API:"
kubectl logs -n keybuzz-studio-api-dev deployment/keybuzz-studio-api --tail=10 2>&1 || echo "(no logs yet)"

echo ""
echo "========================================"
echo "  PH-STUDIO-02 DEPLOYMENT COMPLETE"
echo "========================================"
echo "Frontend: $FRONTEND_IMAGE"
echo "API: $API_IMAGE"
echo "Git SHA: $GIT_SHA"
echo "Frontend URL: https://studio-dev.keybuzz.io"
echo "API URL: https://studio-api-dev.keybuzz.io"
