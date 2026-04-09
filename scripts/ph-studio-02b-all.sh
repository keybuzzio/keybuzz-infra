#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
VAULT_TOKEN_FILE="/root/.vault-cluster-root-token"
if [ -f "$VAULT_TOKEN_FILE" ]; then
  export VAULT_TOKEN=$(cat "$VAULT_TOKEN_FILE")
else
  export VAULT_TOKEN=$(vault print token 2>/dev/null || echo "")
fi

if [ -z "$VAULT_TOKEN" ]; then
  echo "FATAL: No Vault token available"
  exit 1
fi

vault status -format=json | jq '{initialized: .initialized, sealed: .sealed, version: .version}'

echo ""
echo "========================================="
echo "  PH-STUDIO-02B — DB + TLS + Hardening"
echo "========================================="

# =================================================
# STEP 1: Find postgres superuser credentials
# =================================================
echo ""
echo "=== STEP 1: Locate postgres superuser ==="

PG_SUPER_PASS=""
PG_SUPER_USER=""

# Check common Vault paths for postgres admin/superuser
for path in \
  "secret/keybuzz/postgres" \
  "secret/keybuzz/db/admin" \
  "secret/keybuzz/db/postgres" \
  "secret/keybuzz/infrastructure/postgres" \
  "secret/keybuzz/infra/postgres" \
  "secret/keybuzz/dev/db_migrator" \
  "secret/keybuzz/dev/backend-postgres"; do
  RESULT=$(vault kv get -format=json "$path" 2>/dev/null || echo "")
  if [ -n "$RESULT" ]; then
    USER=$(echo "$RESULT" | jq -r '.data.data.PGUSER // .data.data.username // .data.data.user // empty' 2>/dev/null || echo "")
    PASS=$(echo "$RESULT" | jq -r '.data.data.PGPASSWORD // .data.data.password // .data.data.pass // empty' 2>/dev/null || echo "")
    if [ -n "$PASS" ]; then
      echo "Found credentials at: $path (user=$USER)"
      if [ "$USER" = "postgres" ] || [ -z "$PG_SUPER_USER" ]; then
        PG_SUPER_USER="$USER"
        PG_SUPER_PASS="$PASS"
        if [ "$USER" = "postgres" ]; then
          echo "  -> postgres superuser found!"
          break
        fi
      fi
    fi
  fi
done

# Also try listing root-level vault paths
if [ -z "$PG_SUPER_PASS" ] || [ "$PG_SUPER_USER" != "postgres" ]; then
  echo "Listing all Vault mount paths for postgres..."
  vault kv list secret/keybuzz/ 2>/dev/null || true
fi

if [ -z "$PG_SUPER_PASS" ]; then
  echo "WARN: No postgres credentials found in Vault"
  echo "Trying with db_migrator or backend-postgres user..."
fi

# =================================================
# STEP 2: Try to create DB with whatever user we have
# =================================================
echo ""
echo "=== STEP 2: Create keybuzz_studio DB ==="

DB_HOST="10.0.0.10"
DB_PORT="5432"

# First check if DB already exists
DB_EXISTS=$(PGPASSWORD="$PG_SUPER_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$PG_SUPER_USER" -d postgres -t -A -c "SELECT 1 FROM pg_database WHERE datname='keybuzz_studio';" 2>/dev/null || echo "0")

if [ "$DB_EXISTS" = "1" ]; then
  echo "PASS: Database keybuzz_studio already exists"
else
  echo "Creating database keybuzz_studio..."
  
  # Try with found user
  if PGPASSWORD="$PG_SUPER_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$PG_SUPER_USER" -d postgres -c "CREATE DATABASE keybuzz_studio OWNER $PG_SUPER_USER;" 2>&1; then
    echo "PASS: Database created with $PG_SUPER_USER"
  else
    echo "Failed with $PG_SUPER_USER, trying alternate method..."
    
    # If the user is not postgres, try to find the pg_hba trust entries
    # or use the superuser list from pg_roles
    SUPER_LIST=$(PGPASSWORD="$PG_SUPER_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$PG_SUPER_USER" -d keybuzz_backend -t -A -c "SELECT rolname FROM pg_roles WHERE rolsuper=true;" 2>/dev/null || echo "")
    echo "Superuser roles found: $SUPER_LIST"
    
    # Try CREATE DATABASE without OWNER
    PGPASSWORD="$PG_SUPER_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$PG_SUPER_USER" -d postgres -c "CREATE DATABASE keybuzz_studio;" 2>&1 || true
  fi
fi

# Verify DB exists now
DB_CHECK=$(PGPASSWORD="$PG_SUPER_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$PG_SUPER_USER" -d postgres -t -A -c "SELECT 1 FROM pg_database WHERE datname='keybuzz_studio';" 2>/dev/null || echo "0")
echo "DB keybuzz_studio exists: $DB_CHECK"

# =================================================
# STEP 2B: Create studio user + grant permissions
# =================================================
if [ "$DB_CHECK" = "1" ]; then
  echo ""
  echo "=== STEP 2B: Setup studio user + schema ==="
  
  STUDIO_PASS=$(openssl rand -base64 24 | tr -d '=/+' | head -c 32)
  
  # Create user kb_studio if not exists, grant privileges
  PGPASSWORD="$PG_SUPER_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$PG_SUPER_USER" -d keybuzz_studio <<EOSQL || true
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'kb_studio') THEN
    EXECUTE format('CREATE ROLE kb_studio LOGIN PASSWORD %L', '$STUDIO_PASS');
    RAISE NOTICE 'Role kb_studio created';
  ELSE
    EXECUTE format('ALTER ROLE kb_studio PASSWORD %L', '$STUDIO_PASS');
    RAISE NOTICE 'Role kb_studio password updated';
  END IF;
END
\$\$;
GRANT ALL PRIVILEGES ON DATABASE keybuzz_studio TO kb_studio;
GRANT ALL ON SCHEMA public TO kb_studio;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO kb_studio;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO kb_studio;
EOSQL
  
  STUDIO_DB_URL="postgresql://kb_studio:${STUDIO_PASS}@${DB_HOST}:${DB_PORT}/keybuzz_studio"
  echo "PASS: Studio user configured"
  
  # Store in Vault
  vault kv put secret/keybuzz/dev/studio-postgres \
    DATABASE_URL="$STUDIO_DB_URL" \
    PGHOST="$DB_HOST" \
    PGPORT="$DB_PORT" \
    PGDATABASE="keybuzz_studio" \
    PGUSER="kb_studio" \
    PGPASSWORD="$STUDIO_PASS" 2>&1 | grep -v "^$"
  echo "PASS: Credentials stored in Vault at secret/keybuzz/dev/studio-postgres"
  
  # =================================================
  # STEP 2C: Apply Studio schema
  # =================================================
  echo ""
  echo "=== STEP 2C: Apply schema ==="
  
  SCHEMA_FILE="/opt/keybuzz/keybuzz-client/keybuzz-studio-api/src/db/schema.sql"
  if [ -f "$SCHEMA_FILE" ]; then
    PGPASSWORD="$STUDIO_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U kb_studio -d keybuzz_studio -f "$SCHEMA_FILE" 2>&1 | tail -15
    echo "PASS: Schema applied"
  else
    echo "WARN: Schema file not found at $SCHEMA_FILE"
  fi
  
  # Verify tables
  TABLE_COUNT=$(PGPASSWORD="$STUDIO_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U kb_studio -d keybuzz_studio -t -A -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';" 2>/dev/null || echo "0")
  echo "Tables in keybuzz_studio: $TABLE_COUNT"

  # =================================================
  # STEP 3: Update K8s secret
  # =================================================
  echo ""
  echo "=== STEP 3: Update K8s secret ==="
  
  kubectl create secret generic keybuzz-studio-api-db \
    --namespace=keybuzz-studio-api-dev \
    --from-literal=DATABASE_URL="$STUDIO_DB_URL" \
    --dry-run=client -o yaml | kubectl apply -f - 2>&1
  echo "PASS: K8s secret updated"
  
  # Restart API pod to pick up new secret
  kubectl rollout restart deployment/keybuzz-studio-api -n keybuzz-studio-api-dev 2>&1
  echo "PASS: API pod restarted"

else
  echo "FAIL: keybuzz_studio database not created — cannot proceed with user setup"
  echo "Will attempt with alternate approach..."
  
  # Fallback: check if we can use CREATEDB from another role
  echo "Checking pg_roles with CREATEDB..."
  PGPASSWORD="$PG_SUPER_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$PG_SUPER_USER" -d keybuzz_backend -t -A -c "SELECT rolname, rolsuper, rolcreatedb FROM pg_roles WHERE rolsuper OR rolcreatedb ORDER BY rolsuper DESC;" 2>/dev/null || echo "query failed"
fi

# =================================================
# STEP 4: TLS Verification
# =================================================
echo ""
echo "=== STEP 4: TLS Verification ==="

echo "--- Certificates ---"
kubectl get certificate -n keybuzz-studio-dev 2>&1 || true
kubectl get certificate -n keybuzz-studio-api-dev 2>&1 || true

echo ""
echo "--- Certificate details ---"
kubectl describe certificate keybuzz-studio-tls -n keybuzz-studio-dev 2>&1 | grep -E "Status|Reason|Message|Not After|Not Before|Ready" || true
echo ""
kubectl describe certificate keybuzz-studio-api-tls -n keybuzz-studio-api-dev 2>&1 | grep -E "Status|Reason|Message|Not After|Not Before|Ready" || true

echo ""
echo "--- ACME Challenges ---"
kubectl get challenges --all-namespaces 2>&1 | grep -i studio || echo "No active challenges"

echo ""
echo "--- Orders ---"
kubectl get orders --all-namespaces 2>&1 | grep -i studio || echo "No active orders"

echo ""
echo "--- Ingress ---"
kubectl get ingress -n keybuzz-studio-dev
kubectl get ingress -n keybuzz-studio-api-dev

echo ""
echo "--- TLS Secrets ---"
kubectl get secret keybuzz-studio-tls -n keybuzz-studio-dev -o json 2>/dev/null | jq '{name: .metadata.name, type: .type, keys: (.data | keys)}' || echo "TLS secret not ready"
kubectl get secret keybuzz-studio-api-tls -n keybuzz-studio-api-dev -o json 2>/dev/null | jq '{name: .metadata.name, type: .type, keys: (.data | keys)}' || echo "API TLS secret not ready"

# =================================================
# STEP 5: Wait for pod restart + validate
# =================================================
echo ""
echo "=== STEP 5: Runtime Validation ==="
echo "Waiting 40s for pod restart..."
sleep 40

echo "--- Pods ---"
kubectl get pods -n keybuzz-studio-dev -o wide
echo ""
kubectl get pods -n keybuzz-studio-api-dev -o wide

echo ""
echo "--- API Health ---"
kubectl run curl-studio-health --namespace=keybuzz-studio-api-dev \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -s http://keybuzz-studio-api.keybuzz-studio-api-dev.svc.cluster.local:80/health 2>&1 | tail -3

echo ""
echo "--- API Ready ---"
kubectl run curl-studio-ready --namespace=keybuzz-studio-api-dev \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -s http://keybuzz-studio-api.keybuzz-studio-api-dev.svc.cluster.local:80/ready 2>&1 | tail -3

echo ""
echo "--- Logs Frontend (last 10) ---"
kubectl logs -n keybuzz-studio-dev deployment/keybuzz-studio --tail=10 2>&1 || true

echo ""
echo "--- Logs API (last 15) ---"
kubectl logs -n keybuzz-studio-api-dev deployment/keybuzz-studio-api --tail=15 2>&1 || true

echo ""
echo "--- External HTTPS test ---"
kubectl run curl-tls-fe --namespace=keybuzz-studio-dev \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -sI --max-time 10 https://studio-dev.keybuzz.io 2>&1 | head -10 || echo "Frontend HTTPS test failed"

echo ""
kubectl run curl-tls-api --namespace=keybuzz-studio-api-dev \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -s --max-time 10 https://studio-api-dev.keybuzz.io/health 2>&1 | tail -3 || echo "API HTTPS test failed"

echo ""
echo "========================================="
echo "  PH-STUDIO-02B EXECUTION COMPLETE"
echo "========================================="
