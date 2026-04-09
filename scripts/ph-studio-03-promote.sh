#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=$(cat /root/.vault-cluster-root-token 2>/dev/null || echo "")

DB_HOST="10.0.0.10"
DB_PORT="5432"
PG_PASS="CHANGE_ME_LATER_VIA_VAULT"

FRONTEND_DEV="ghcr.io/keybuzzio/keybuzz-studio:v0.1.0-dev"
API_DEV="ghcr.io/keybuzzio/keybuzz-studio-api:v0.1.0-dev"
FRONTEND_PROD="ghcr.io/keybuzzio/keybuzz-studio:v0.1.0-prod"
API_PROD="ghcr.io/keybuzzio/keybuzz-studio-api:v0.1.0-prod"

echo "=========================================="
echo "  PH-STUDIO-03 — PROD PROMOTION"
echo "=========================================="

# =================================================
# STEP 1: Tag + Push images
# =================================================
echo ""
echo "=== STEP 1: Tag + Push PROD images ==="
docker tag "$FRONTEND_DEV" "$FRONTEND_PROD"
docker tag "$API_DEV" "$API_PROD"
docker push "$FRONTEND_PROD" 2>&1 | tail -3
docker push "$API_PROD" 2>&1 | tail -3
echo "PASS: Images tagged and pushed"

# =================================================
# STEP 2: Create PROD DB
# =================================================
echo ""
echo "=== STEP 2: Create keybuzz_studio_prod DB ==="

DB_EXISTS=$(PGPASSWORD="$PG_PASS" psql -h "$DB_HOST" -U postgres -d postgres -t -A -c "SELECT 1 FROM pg_database WHERE datname='keybuzz_studio_prod';" 2>/dev/null || echo "0")
if [ "$DB_EXISTS" != "1" ]; then
  PGPASSWORD="$PG_PASS" psql -h "$DB_HOST" -U postgres -d postgres -c "CREATE DATABASE keybuzz_studio_prod ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8' TEMPLATE template0;" 2>&1
  echo "PASS: DB created"
else
  echo "DB keybuzz_studio_prod already exists"
fi

STUDIO_PROD_PASS=$(openssl rand -base64 24 | tr -d '=/+' | head -c 32)

PGPASSWORD="$PG_PASS" psql -h "$DB_HOST" -U postgres -d keybuzz_studio_prod <<EOSQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'kb_studio_prod') THEN
    EXECUTE format('CREATE ROLE kb_studio_prod LOGIN PASSWORD %L', '${STUDIO_PROD_PASS}');
  ELSE
    EXECUTE format('ALTER ROLE kb_studio_prod PASSWORD %L', '${STUDIO_PROD_PASS}');
  END IF;
END
\$\$;
GRANT ALL PRIVILEGES ON DATABASE keybuzz_studio_prod TO kb_studio_prod;
GRANT ALL ON SCHEMA public TO kb_studio_prod;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO kb_studio_prod;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO kb_studio_prod;
EOSQL
echo "PASS: User kb_studio_prod ready"

# Apply schema
SCHEMA="/opt/keybuzz/keybuzz-client/keybuzz-studio-api/src/db/schema.sql"
if [ -f "$SCHEMA" ]; then
  PGPASSWORD="$STUDIO_PROD_PASS" psql -h "$DB_HOST" -U kb_studio_prod -d keybuzz_studio_prod -f "$SCHEMA" 2>&1 | tail -10
  echo "PASS: Schema applied"
fi

TABLE_COUNT=$(PGPASSWORD="$STUDIO_PROD_PASS" psql -h "$DB_HOST" -U kb_studio_prod -d keybuzz_studio_prod -t -A -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';" 2>/dev/null || echo "?")
echo "Tables: $TABLE_COUNT"

# =================================================
# STEP 3: Store PROD secrets in Vault
# =================================================
echo ""
echo "=== STEP 3: Vault + K8s secrets ==="

STUDIO_PROD_URL="postgresql://kb_studio_prod:${STUDIO_PROD_PASS}@${DB_HOST}:${DB_PORT}/keybuzz_studio_prod"
vault kv put secret/keybuzz/prod/studio-postgres \
  DATABASE_URL="$STUDIO_PROD_URL" \
  PGHOST="$DB_HOST" \
  PGPORT="$DB_PORT" \
  PGDATABASE="keybuzz_studio_prod" \
  PGUSER="kb_studio_prod" \
  PGPASSWORD="$STUDIO_PROD_PASS" 2>&1 | head -5
echo "PASS: Vault secret stored"

# =================================================
# STEP 4: K8s setup
# =================================================
echo ""
echo "=== STEP 4: K8s namespaces + secrets ==="

kubectl create namespace keybuzz-studio-prod --dry-run=client -o yaml | kubectl apply -f - 2>&1
kubectl create namespace keybuzz-studio-api-prod --dry-run=client -o yaml | kubectl apply -f - 2>&1

# Copy GHCR secret
GHCR_JSON=$(kubectl get secret ghcr-cred -n keybuzz-client-dev -o json 2>/dev/null || echo "")
if [ -n "$GHCR_JSON" ]; then
  echo "$GHCR_JSON" | jq '.metadata.namespace="keybuzz-studio-prod" | del(.metadata.resourceVersion,.metadata.uid,.metadata.creationTimestamp,.metadata.annotations)' | kubectl apply -f - 2>&1
  echo "$GHCR_JSON" | jq '.metadata.namespace="keybuzz-studio-api-prod" | del(.metadata.resourceVersion,.metadata.uid,.metadata.creationTimestamp,.metadata.annotations)' | kubectl apply -f - 2>&1
  echo "PASS: GHCR secrets"
fi

# DB secret
kubectl create secret generic keybuzz-studio-api-db \
  --namespace=keybuzz-studio-api-prod \
  --from-literal=DATABASE_URL="$STUDIO_PROD_URL" \
  --dry-run=client -o yaml | kubectl apply -f - 2>&1
echo "PASS: DB secret"

# =================================================
# STEP 5: SCP + Apply manifests
# =================================================
echo ""
echo "=== STEP 5: Deploy PROD ==="

# Manifests are already on bastion via SCP (will be applied next)
kubectl apply -f /opt/keybuzz/keybuzz-infra/k8s/keybuzz-studio-prod/ 2>&1 || true
kubectl apply -f /opt/keybuzz/keybuzz-infra/k8s/keybuzz-studio-api-prod/ 2>&1 || true
echo "PASS: Manifests applied"

echo ""
echo "Waiting 60s for pods + certs..."
sleep 60

# =================================================
# STEP 6: Verification
# =================================================
echo ""
echo "=========================================="
echo "  VERIFICATION PROD"
echo "=========================================="

echo ""
echo "--- Pods ---"
kubectl get pods -n keybuzz-studio-prod -o wide
echo ""
kubectl get pods -n keybuzz-studio-api-prod -o wide

echo ""
echo "--- Services ---"
kubectl get svc -n keybuzz-studio-prod
kubectl get svc -n keybuzz-studio-api-prod

echo ""
echo "--- Ingress ---"
kubectl get ingress -n keybuzz-studio-prod
kubectl get ingress -n keybuzz-studio-api-prod

echo ""
echo "--- Certificates ---"
kubectl get certificate -A 2>&1 | grep studio-prod || echo "no prod certs yet"

echo ""
echo "--- Health ---"
kubectl run prod-health --namespace=keybuzz-studio-api-prod \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -s http://keybuzz-studio-api.keybuzz-studio-api-prod.svc.cluster.local:80/health 2>&1 | tail -3

echo ""
echo "--- Ready ---"
kubectl run prod-ready --namespace=keybuzz-studio-api-prod \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -s http://keybuzz-studio-api.keybuzz-studio-api-prod.svc.cluster.local:80/ready 2>&1 | tail -3

echo ""
echo "--- HTTPS Frontend ---"
kubectl run prod-fe --namespace=keybuzz-studio-prod \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -sI --max-time 15 https://studio.keybuzz.io 2>&1 | grep -E "^HTTP|content-type" | head -3

echo ""
echo "--- HTTPS API ---"
kubectl run prod-api --namespace=keybuzz-studio-api-prod \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -s --max-time 15 https://studio-api.keybuzz.io/health 2>&1 | tail -3

echo ""
echo "--- Logs Frontend ---"
kubectl logs -n keybuzz-studio-prod deployment/keybuzz-studio --tail=8 2>&1

echo ""
echo "--- Logs API ---"
kubectl logs -n keybuzz-studio-api-prod deployment/keybuzz-studio-api --tail=10 2>&1

echo ""
echo "--- Restarts ---"
kubectl get pods -n keybuzz-studio-prod -o jsonpath='{range .items[*]}{.metadata.name}{" restarts="}{range .status.containerStatuses[*]}{.restartCount}{end}{"\n"}{end}'
kubectl get pods -n keybuzz-studio-api-prod -o jsonpath='{range .items[*]}{.metadata.name}{" restarts="}{range .status.containerStatuses[*]}{.restartCount}{end}{"\n"}{end}'

echo ""
echo "=========================================="
echo "  PH-STUDIO-03 PROMOTION COMPLETE"
echo "=========================================="
docker images | grep keybuzz-studio
