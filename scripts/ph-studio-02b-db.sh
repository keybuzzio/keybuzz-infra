#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=$(cat /root/.vault-cluster-root-token 2>/dev/null || echo "")

DB_HOST="10.0.0.10"
DB_PORT="5432"

echo "=== Retrieve postgres superuser from Vault admin-v2 ==="
PG_DATA=$(vault kv get -format=json secret/keybuzz/admin-v2/postgres 2>/dev/null || echo "")
if [ -z "$PG_DATA" ]; then
  echo "FAIL: secret/keybuzz/admin-v2/postgres not found"
  exit 1
fi

echo "Keys found:"
echo "$PG_DATA" | jq -r '.data.data | keys[]'

PG_USER=$(echo "$PG_DATA" | jq -r '.data.data.username // .data.data.PGUSER // .data.data.user // "postgres"')
PG_PASS=$(echo "$PG_DATA" | jq -r '.data.data.password // .data.data.PGPASSWORD // .data.data.pass // empty')

if [ -z "$PG_PASS" ]; then
  echo "FAIL: No password field found in admin-v2/postgres"
  echo "Trying bootstrap..."
  PG_DATA=$(vault kv get -format=json secret/keybuzz/admin-v2/bootstrap 2>/dev/null || echo "")
  echo "Bootstrap keys:"
  echo "$PG_DATA" | jq -r '.data.data | keys[]' 2>/dev/null
  PG_PASS=$(echo "$PG_DATA" | jq -r '.data.data.postgres_password // .data.data.PGPASSWORD // .data.data.password // empty' 2>/dev/null || echo "")
  PG_USER="postgres"
fi

echo "PG user: $PG_USER"
echo "PG pass length: ${#PG_PASS}"

echo ""
echo "=== Test connection ==="
PGPASSWORD="$PG_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$PG_USER" -d postgres -c "SELECT version();" 2>&1 | head -3

echo ""
echo "=== Check if keybuzz_studio exists ==="
DB_EXISTS=$(PGPASSWORD="$PG_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$PG_USER" -d postgres -t -A -c "SELECT 1 FROM pg_database WHERE datname='keybuzz_studio';" 2>/dev/null || echo "0")

if [ "$DB_EXISTS" = "1" ]; then
  echo "Database keybuzz_studio already exists"
else
  echo "Creating keybuzz_studio..."
  PGPASSWORD="$PG_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$PG_USER" -d postgres -c "CREATE DATABASE keybuzz_studio ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8' TEMPLATE template0;" 2>&1
fi

echo ""
echo "=== Create kb_studio user ==="
STUDIO_PASS=$(openssl rand -base64 24 | tr -d '=/+' | head -c 32)

PGPASSWORD="$PG_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$PG_USER" -d keybuzz_studio <<EOSQL
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

echo ""
echo "=== Apply Studio schema ==="
SCHEMA="/opt/keybuzz/keybuzz-client/keybuzz-studio-api/src/db/schema.sql"
if [ -f "$SCHEMA" ]; then
  PGPASSWORD="$STUDIO_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U kb_studio -d keybuzz_studio -f "$SCHEMA" 2>&1 | tail -20
else
  echo "Schema file not found at $SCHEMA"
fi

TABLE_COUNT=$(PGPASSWORD="$STUDIO_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U kb_studio -d keybuzz_studio -t -A -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';" 2>/dev/null || echo "?")
echo "Tables in keybuzz_studio: $TABLE_COUNT"

echo ""
echo "=== Store in Vault ==="
STUDIO_URL="postgresql://kb_studio:${STUDIO_PASS}@${DB_HOST}:${DB_PORT}/keybuzz_studio"
vault kv put secret/keybuzz/dev/studio-postgres \
  DATABASE_URL="$STUDIO_URL" \
  PGHOST="$DB_HOST" \
  PGPORT="$DB_PORT" \
  PGDATABASE="keybuzz_studio" \
  PGUSER="kb_studio" \
  PGPASSWORD="$STUDIO_PASS" 2>&1 | head -10

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
echo "=== Fix TLS ==="
kubectl delete certificate keybuzz-studio-tls -n keybuzz-studio-dev 2>&1 || true
kubectl delete certificate keybuzz-studio-api-tls -n keybuzz-studio-api-dev 2>&1 || true
sleep 3
kubectl delete challenges --all -n keybuzz-studio-dev 2>&1 || true
kubectl delete challenges --all -n keybuzz-studio-api-dev 2>&1 || true
kubectl delete orders --all -n keybuzz-studio-dev 2>&1 || true
kubectl delete orders --all -n keybuzz-studio-api-dev 2>&1 || true
sleep 5

# Re-apply ingress to trigger fresh cert issuance
kubectl get ingress keybuzz-studio -n keybuzz-studio-dev -o yaml | kubectl apply -f - 2>&1
kubectl get ingress keybuzz-studio-api -n keybuzz-studio-api-dev -o yaml | kubectl apply -f - 2>&1

echo ""
echo "Waiting 60s for certs + pods..."
sleep 60

echo ""
echo "=== Final status ==="

echo "--- Certs ---"
kubectl get certificate -A 2>&1 | grep studio || echo "No studio certs yet"

echo "--- Challenges ---"
kubectl get challenges -A 2>&1 | grep studio || echo "No challenges"

echo "--- Pods ---"
kubectl get pods -n keybuzz-studio-dev -o wide
kubectl get pods -n keybuzz-studio-api-dev -o wide

echo ""
echo "--- Health ---"
kubectl run curl-02b --namespace=keybuzz-studio-api-dev \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -s http://keybuzz-studio-api.keybuzz-studio-api-dev.svc.cluster.local:80/health 2>&1 | tail -3

echo ""
echo "--- Ready ---"
kubectl run curl-02b-ready --namespace=keybuzz-studio-api-dev \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -s http://keybuzz-studio-api.keybuzz-studio-api-dev.svc.cluster.local:80/ready 2>&1 | tail -3

echo ""
echo "--- DB connection verification ---"
kubectl logs -n keybuzz-studio-api-dev deployment/keybuzz-studio-api --tail=10 2>&1

echo ""
echo "DONE"
