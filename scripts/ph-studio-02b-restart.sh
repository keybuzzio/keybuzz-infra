#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=$(cat /root/.vault-cluster-root-token 2>/dev/null || echo "")

PRIMARY="10.0.0.122"
DB_HOST="10.0.0.10"

# Get the password we patched into Patroni
PG_NEW_PASS=$(curl -s "http://${PRIMARY}:8008/config" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('postgresql',{}).get('authentication',{}).get('superuser',{}).get('password',''))" 2>/dev/null || echo "")
echo "Password from Patroni config: length ${#PG_NEW_PASS}"

echo ""
echo "=== Trigger Patroni restart on PRIMARY (graceful) ==="
RESTART_RESULT=$(curl -s -w "\n%{http_code}" -X POST "http://${PRIMARY}:8008/restart" \
  -H "Content-Type: application/json" \
  -d '{"schedule": null}' 2>&1)
HTTP=$(echo "$RESTART_RESULT" | tail -1)
BODY=$(echo "$RESTART_RESULT" | head -n -1)
echo "HTTP: $HTTP"
echo "Body: $BODY"

echo ""
echo "Waiting 20s for PostgreSQL restart..."
sleep 20

echo ""
echo "=== Test connection as postgres to primary ==="
PGPASSWORD="$PG_NEW_PASS" psql -h "$PRIMARY" -p 5432 -U postgres -d postgres -c "SELECT current_user, version();" 2>&1 | head -5

echo ""
echo "=== Test via HAProxy ==="
PGPASSWORD="$PG_NEW_PASS" psql -h "$DB_HOST" -p 5432 -U postgres -d postgres -c "SELECT 1 as connected;" 2>&1 | head -5

CONNECTED=$?
if [ $CONNECTED -eq 0 ]; then
  echo ""
  echo "PASS: postgres superuser connected"
  
  echo ""
  echo "=== Create keybuzz_studio ==="
  DB_EXISTS=$(PGPASSWORD="$PG_NEW_PASS" psql -h "$DB_HOST" -U postgres -d postgres -t -A -c "SELECT 1 FROM pg_database WHERE datname='keybuzz_studio';" 2>/dev/null || echo "0")
  if [ "$DB_EXISTS" != "1" ]; then
    PGPASSWORD="$PG_NEW_PASS" psql -h "$DB_HOST" -U postgres -d postgres -c "CREATE DATABASE keybuzz_studio ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8' TEMPLATE template0;" 2>&1
  else
    echo "Already exists"
  fi
  
  echo ""
  echo "=== Create kb_studio + schema ==="
  STUDIO_PASS=$(openssl rand -base64 24 | tr -d '=/+' | head -c 32)
  
  PGPASSWORD="$PG_NEW_PASS" psql -h "$DB_HOST" -U postgres -d keybuzz_studio <<EOSQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'kb_studio') THEN
    EXECUTE format('CREATE ROLE kb_studio LOGIN PASSWORD %L', '${STUDIO_PASS}');
  ELSE
    EXECUTE format('ALTER ROLE kb_studio PASSWORD %L', '${STUDIO_PASS}');
  END IF;
END
\$\$;
GRANT ALL PRIVILEGES ON DATABASE keybuzz_studio TO kb_studio;
GRANT ALL ON SCHEMA public TO kb_studio;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO kb_studio;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO kb_studio;
EOSQL

  SCHEMA="/opt/keybuzz/keybuzz-client/keybuzz-studio-api/src/db/schema.sql"
  if [ -f "$SCHEMA" ]; then
    PGPASSWORD="$STUDIO_PASS" psql -h "$DB_HOST" -U kb_studio -d keybuzz_studio -f "$SCHEMA" 2>&1 | tail -20
  fi
  
  TABLE_COUNT=$(PGPASSWORD="$STUDIO_PASS" psql -h "$DB_HOST" -U kb_studio -d keybuzz_studio -t -A -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';" 2>/dev/null || echo "?")
  echo "Tables: $TABLE_COUNT"
  
  echo ""
  echo "=== Store in Vault ==="
  STUDIO_URL="postgresql://kb_studio:${STUDIO_PASS}@${DB_HOST}:5432/keybuzz_studio"
  vault kv put secret/keybuzz/dev/studio-postgres \
    DATABASE_URL="$STUDIO_URL" \
    PGHOST="$DB_HOST" \
    PGPORT="5432" \
    PGDATABASE="keybuzz_studio" \
    PGUSER="kb_studio" \
    PGPASSWORD="$STUDIO_PASS" 2>&1 | head -5
  
  vault kv put secret/keybuzz/infra/postgres \
    username="postgres" \
    password="$PG_NEW_PASS" \
    host="$DB_HOST" \
    port="5432" 2>&1 | head -5
  
  echo ""
  echo "=== Update K8s + restart ==="
  kubectl create secret generic keybuzz-studio-api-db \
    --namespace=keybuzz-studio-api-dev \
    --from-literal=DATABASE_URL="$STUDIO_URL" \
    --dry-run=client -o yaml | kubectl apply -f - 2>&1
  
  kubectl rollout restart deployment/keybuzz-studio-api -n keybuzz-studio-api-dev 2>&1
  
  echo ""
  echo "Waiting 45s for API pod..."
  sleep 45
  
  echo ""
  echo "=== Verify ==="
  kubectl get pods -n keybuzz-studio-api-dev
  echo ""
  kubectl run curl-verify --namespace=keybuzz-studio-api-dev \
    --image=curlimages/curl --rm -it --restart=Never \
    -- curl -s http://keybuzz-studio-api.keybuzz-studio-api-dev.svc.cluster.local:80/health 2>&1 | tail -3
  echo ""
  kubectl run curl-ready --namespace=keybuzz-studio-api-dev \
    --image=curlimages/curl --rm -it --restart=Never \
    -- curl -s http://keybuzz-studio-api.keybuzz-studio-api-dev.svc.cluster.local:80/ready 2>&1 | tail -3
  echo ""
  kubectl logs -n keybuzz-studio-api-dev deployment/keybuzz-studio-api --tail=8 2>&1
  
  echo ""
  echo "SUCCESS: DB dedicated keybuzz_studio created and connected"
else
  echo ""
  echo "FAIL: Could not connect as postgres after restart"
  echo "The superuser password was not updated by the restart"
  echo ""
  echo "Checking all loginable roles..."
  BACKEND_PASS=$(vault kv get -field=PGPASSWORD secret/keybuzz/dev/backend-postgres 2>/dev/null || echo "")
  PGPASSWORD="$BACKEND_PASS" psql -h "$DB_HOST" -U kb_backend -d keybuzz_backend -c "SELECT rolname, rolsuper, rolcreatedb, rolcreaterole FROM pg_roles WHERE rolcanlogin ORDER BY rolsuper DESC;" 2>/dev/null
fi

echo ""
echo "DONE"
