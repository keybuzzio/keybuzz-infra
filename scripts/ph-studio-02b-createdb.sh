#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=$(cat /root/.vault-cluster-root-token 2>/dev/null || echo "")

DB_HOST="10.0.0.10"
DB_PORT="5432"

echo "=== Get keybuzz-admin credentials ==="
ADMIN_DATA=$(vault kv get -format=json secret/database/creds/keybuzz-admin 2>/dev/null || echo "")
if [ -z "$ADMIN_DATA" ]; then
  echo "FAIL: No admin creds at secret/database/creds/keybuzz-admin"
  exit 1
fi

ADMIN_USER=$(echo "$ADMIN_DATA" | jq -r '.data.data.PGUSER // .data.data.username // empty')
ADMIN_PASS=$(echo "$ADMIN_DATA" | jq -r '.data.data.PGPASSWORD // .data.data.password // empty')
ADMIN_HOST=$(echo "$ADMIN_DATA" | jq -r '.data.data.PGHOST // empty')
ADMIN_DB=$(echo "$ADMIN_DATA" | jq -r '.data.data.PGDATABASE // "postgres"')

echo "Admin user: $ADMIN_USER"
echo "Admin host: ${ADMIN_HOST:-$DB_HOST}"
echo "Admin DB: $ADMIN_DB"

# Use admin host if available
CONNECT_HOST="${ADMIN_HOST:-$DB_HOST}"

echo ""
echo "=== Test admin connection ==="
PGPASSWORD="$ADMIN_PASS" psql -h "$CONNECT_HOST" -p "$DB_PORT" -U "$ADMIN_USER" -d "$ADMIN_DB" -c "SELECT current_user, current_database();" 2>&1

echo ""
echo "=== Check privileges ==="
PGPASSWORD="$ADMIN_PASS" psql -h "$CONNECT_HOST" -p "$DB_PORT" -U "$ADMIN_USER" -d "$ADMIN_DB" -t -A -c "SELECT rolsuper, rolcreatedb, rolcreaterole FROM pg_roles WHERE rolname=current_user;" 2>&1

echo ""
echo "=== Check if keybuzz_studio exists ==="
DB_EXISTS=$(PGPASSWORD="$ADMIN_PASS" psql -h "$CONNECT_HOST" -p "$DB_PORT" -U "$ADMIN_USER" -d "$ADMIN_DB" -t -A -c "SELECT 1 FROM pg_database WHERE datname='keybuzz_studio';" 2>/dev/null || echo "0")
echo "Exists: $DB_EXISTS"

if [ "$DB_EXISTS" != "1" ]; then
  echo ""
  echo "=== Create keybuzz_studio ==="
  PGPASSWORD="$ADMIN_PASS" psql -h "$CONNECT_HOST" -p "$DB_PORT" -U "$ADMIN_USER" -d "$ADMIN_DB" -c "CREATE DATABASE keybuzz_studio ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8' TEMPLATE template0;" 2>&1
fi

echo ""
echo "=== Verify DB created ==="
DB_CHECK=$(PGPASSWORD="$ADMIN_PASS" psql -h "$CONNECT_HOST" -p "$DB_PORT" -U "$ADMIN_USER" -d "$ADMIN_DB" -t -A -c "SELECT 1 FROM pg_database WHERE datname='keybuzz_studio';" 2>/dev/null || echo "0")
echo "keybuzz_studio exists: $DB_CHECK"

if [ "$DB_CHECK" = "1" ]; then
  echo ""
  echo "=== Create kb_studio user ==="
  STUDIO_PASS=$(openssl rand -base64 24 | tr -d '=/+' | head -c 32)
  
  PGPASSWORD="$ADMIN_PASS" psql -h "$CONNECT_HOST" -p "$DB_PORT" -U "$ADMIN_USER" -d keybuzz_studio <<EOSQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'kb_studio') THEN
    EXECUTE format('CREATE ROLE kb_studio LOGIN PASSWORD %L', '${STUDIO_PASS}');
    RAISE NOTICE 'Created kb_studio';
  ELSE
    EXECUTE format('ALTER ROLE kb_studio PASSWORD %L', '${STUDIO_PASS}');
    RAISE NOTICE 'Updated kb_studio password';
  END IF;
END
\$\$;
GRANT ALL PRIVILEGES ON DATABASE keybuzz_studio TO kb_studio;
GRANT ALL ON SCHEMA public TO kb_studio;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO kb_studio;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO kb_studio;
EOSQL
  echo "User setup OK"

  echo ""
  echo "=== Apply schema ==="
  SCHEMA="/opt/keybuzz/keybuzz-client/keybuzz-studio-api/src/db/schema.sql"
  if [ -f "$SCHEMA" ]; then
    PGPASSWORD="$STUDIO_PASS" psql -h "$CONNECT_HOST" -p "$DB_PORT" -U kb_studio -d keybuzz_studio -f "$SCHEMA" 2>&1 | tail -20
  else
    echo "Schema not found"
  fi

  TABLE_COUNT=$(PGPASSWORD="$STUDIO_PASS" psql -h "$CONNECT_HOST" -p "$DB_PORT" -U kb_studio -d keybuzz_studio -t -A -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';" 2>/dev/null || echo "?")
  echo "Tables: $TABLE_COUNT"

  echo ""
  echo "=== Store in Vault ==="
  STUDIO_URL="postgresql://kb_studio:${STUDIO_PASS}@${DB_HOST}:${DB_PORT}/keybuzz_studio"
  vault kv put secret/keybuzz/dev/studio-postgres \
    DATABASE_URL="$STUDIO_URL" \
    PGHOST="$DB_HOST" \
    PGPORT="$DB_PORT" \
    PGDATABASE="keybuzz_studio" \
    PGUSER="kb_studio" \
    PGPASSWORD="$STUDIO_PASS" 2>&1 | head -5
  echo "Vault updated"

  echo ""
  echo "=== Update K8s secret ==="
  kubectl create secret generic keybuzz-studio-api-db \
    --namespace=keybuzz-studio-api-dev \
    --from-literal=DATABASE_URL="$STUDIO_URL" \
    --dry-run=client -o yaml | kubectl apply -f - 2>&1
  
  echo ""
  echo "=== Restart API pod ==="
  kubectl rollout restart deployment/keybuzz-studio-api -n keybuzz-studio-api-dev 2>&1

  echo ""
  echo "=== Fix TLS (delete errored certs) ==="
  kubectl delete certificate keybuzz-studio-tls -n keybuzz-studio-dev 2>&1 || true
  kubectl delete certificate keybuzz-studio-api-tls -n keybuzz-studio-api-dev 2>&1 || true
  kubectl delete challenges --all -n keybuzz-studio-dev 2>&1 || true
  kubectl delete challenges --all -n keybuzz-studio-api-dev 2>&1 || true
  kubectl delete orders --all -n keybuzz-studio-dev 2>&1 || true
  kubectl delete orders --all -n keybuzz-studio-api-dev 2>&1 || true
  sleep 3
  
  kubectl get ingress keybuzz-studio -n keybuzz-studio-dev -o yaml | kubectl apply -f - 2>&1
  kubectl get ingress keybuzz-studio-api -n keybuzz-studio-api-dev -o yaml | kubectl apply -f - 2>&1

  echo ""
  echo "Waiting 60s for pods + certs..."
  sleep 60

  echo ""
  echo "=== Final check ==="
  echo "--- Pods ---"
  kubectl get pods -n keybuzz-studio-dev
  kubectl get pods -n keybuzz-studio-api-dev
  echo ""
  echo "--- Certs ---"
  kubectl get certificate -A 2>&1 | grep studio || echo "no certs"
  echo ""
  echo "--- Challenges ---"
  kubectl get challenges -A 2>&1 | grep studio || echo "no challenges"
  echo ""
  echo "--- Health ---"
  kubectl run curl-final --namespace=keybuzz-studio-api-dev \
    --image=curlimages/curl --rm -it --restart=Never \
    -- curl -s http://keybuzz-studio-api.keybuzz-studio-api-dev.svc.cluster.local:80/health 2>&1 | tail -3
  echo ""
  echo "--- Ready ---"
  kubectl run curl-final-r --namespace=keybuzz-studio-api-dev \
    --image=curlimages/curl --rm -it --restart=Never \
    -- curl -s http://keybuzz-studio-api.keybuzz-studio-api-dev.svc.cluster.local:80/ready 2>&1 | tail -3
  echo ""
  echo "--- Logs API ---"
  kubectl logs -n keybuzz-studio-api-dev deployment/keybuzz-studio-api --tail=10 2>&1
else
  echo "FAIL: Could not create keybuzz_studio"
fi

echo ""
echo "=== DONE ==="
