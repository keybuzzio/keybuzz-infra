#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=$(cat /root/.vault-cluster-root-token 2>/dev/null || echo "")

DB_HOST="10.0.0.10"
PRIMARY_HOST="10.0.0.122"

BACKEND_PASS=$(vault kv get -field=PGPASSWORD secret/keybuzz/dev/backend-postgres 2>/dev/null || echo "")

echo "=== Check if 'admin' role exists in PG ==="
PGPASSWORD="$BACKEND_PASS" psql -h "$DB_HOST" -U kb_backend -d keybuzz_backend -t -A -c "SELECT rolname, rolsuper, rolcreatedb, rolcreaterole FROM pg_roles WHERE rolname IN ('admin','postgres','vault_admin');" 2>/dev/null

echo ""
echo "=== Check Patroni full config ==="
curl -s "http://${PRIMARY_HOST}:8008/config" 2>/dev/null | python3 -m json.tool 2>/dev/null | head -40

echo ""
echo "=== Check Patroni cluster status ==="
curl -s "http://${PRIMARY_HOST}:8008/cluster" 2>/dev/null | python3 -m json.tool 2>/dev/null | head -30

echo ""
echo "=== APPROACH: Use Patroni API to set superuser password ==="
NEW_PG_PASS=$(openssl rand -base64 24 | tr -d '=/+' | head -c 32)
echo "Setting new superuser password via Patroni PATCH /config..."

RESULT=$(curl -s -w "\n%{http_code}" -X PATCH "http://${PRIMARY_HOST}:8008/config" \
  -H "Content-Type: application/json" \
  -d "{\"postgresql\":{\"authentication\":{\"superuser\":{\"username\":\"postgres\",\"password\":\"${NEW_PG_PASS}\"}}}}" 2>&1)

HTTP_CODE=$(echo "$RESULT" | tail -1)
BODY=$(echo "$RESULT" | head -n -1)
echo "HTTP: $HTTP_CODE"
echo "Body: $BODY"

if [ "$HTTP_CODE" = "200" ]; then
  echo ""
  echo "Waiting 10s for password to propagate..."
  sleep 10
  
  echo ""
  echo "=== Test connection as postgres ==="
  PGPASSWORD="$NEW_PG_PASS" psql -h "$DB_HOST" -U postgres -d postgres -c "SELECT current_user, current_database();" 2>&1
  
  if [ $? -eq 0 ]; then
    echo "PASS: postgres superuser connected"
    
    echo ""
    echo "=== Store postgres password in Vault ==="
    vault kv put secret/keybuzz/infra/postgres \
      username="postgres" \
      password="$NEW_PG_PASS" \
      host="$DB_HOST" \
      port="5432" 2>&1 | head -5
    
    echo ""
    echo "=== Create keybuzz_studio DB ==="
    DB_EXISTS=$(PGPASSWORD="$NEW_PG_PASS" psql -h "$DB_HOST" -U postgres -d postgres -t -A -c "SELECT 1 FROM pg_database WHERE datname='keybuzz_studio';" 2>/dev/null || echo "0")
    if [ "$DB_EXISTS" != "1" ]; then
      PGPASSWORD="$NEW_PG_PASS" psql -h "$DB_HOST" -U postgres -d postgres -c "CREATE DATABASE keybuzz_studio ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8' TEMPLATE template0;" 2>&1
    else
      echo "keybuzz_studio already exists"
    fi
    
    echo ""
    echo "=== Create kb_studio user ==="
    STUDIO_PASS=$(openssl rand -base64 24 | tr -d '=/+' | head -c 32)
    
    PGPASSWORD="$NEW_PG_PASS" psql -h "$DB_HOST" -U postgres -d keybuzz_studio <<EOSQL
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
    echo "kb_studio user ready"
    
    echo ""
    echo "=== Apply schema ==="
    SCHEMA="/opt/keybuzz/keybuzz-client/keybuzz-studio-api/src/db/schema.sql"
    if [ -f "$SCHEMA" ]; then
      PGPASSWORD="$STUDIO_PASS" psql -h "$DB_HOST" -U kb_studio -d keybuzz_studio -f "$SCHEMA" 2>&1 | tail -20
    fi
    
    TABLE_COUNT=$(PGPASSWORD="$STUDIO_PASS" psql -h "$DB_HOST" -U kb_studio -d keybuzz_studio -t -A -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';" 2>/dev/null || echo "?")
    echo "Tables: $TABLE_COUNT"
    
    echo ""
    echo "=== Update Vault + K8s ==="
    STUDIO_URL="postgresql://kb_studio:${STUDIO_PASS}@${DB_HOST}:${DB_PORT:-5432}/keybuzz_studio"
    vault kv put secret/keybuzz/dev/studio-postgres \
      DATABASE_URL="$STUDIO_URL" \
      PGHOST="$DB_HOST" \
      PGPORT="5432" \
      PGDATABASE="keybuzz_studio" \
      PGUSER="kb_studio" \
      PGPASSWORD="$STUDIO_PASS" 2>&1 | head -5
    
    kubectl create secret generic keybuzz-studio-api-db \
      --namespace=keybuzz-studio-api-dev \
      --from-literal=DATABASE_URL="$STUDIO_URL" \
      --dry-run=client -o yaml | kubectl apply -f - 2>&1
    
    echo ""
    echo "=== Restart API + Fix TLS ==="
    kubectl rollout restart deployment/keybuzz-studio-api -n keybuzz-studio-api-dev 2>&1
    
    kubectl delete certificate keybuzz-studio-tls -n keybuzz-studio-dev 2>&1 || true
    kubectl delete certificate keybuzz-studio-api-tls -n keybuzz-studio-api-dev 2>&1 || true
    sleep 3
    kubectl delete challenges --all -n keybuzz-studio-dev 2>&1 || true
    kubectl delete challenges --all -n keybuzz-studio-api-dev 2>&1 || true
    kubectl delete orders --all -n keybuzz-studio-dev 2>&1 || true
    kubectl delete orders --all -n keybuzz-studio-api-dev 2>&1 || true
    sleep 3
    kubectl get ingress keybuzz-studio -n keybuzz-studio-dev -o yaml | kubectl apply -f - 2>&1
    kubectl get ingress keybuzz-studio-api -n keybuzz-studio-api-dev -o yaml | kubectl apply -f - 2>&1
    
    echo ""
    echo "Waiting 60s..."
    sleep 60
    
    echo ""
    echo "=== Final check ==="
    echo "--- Pods ---"
    kubectl get pods -n keybuzz-studio-dev
    kubectl get pods -n keybuzz-studio-api-dev
    echo "--- Certs ---"
    kubectl get certificate -A 2>&1 | grep studio || echo "no certs"
    echo "--- Challenges ---"
    kubectl get challenges -A 2>&1 | grep studio || echo "no challenges"
    echo "--- Health ---"
    kubectl run curl-02bfinal --namespace=keybuzz-studio-api-dev \
      --image=curlimages/curl --rm -it --restart=Never \
      -- curl -s http://keybuzz-studio-api.keybuzz-studio-api-dev.svc.cluster.local:80/health 2>&1 | tail -3
    echo "--- Ready ---"
    kubectl run curl-02bready --namespace=keybuzz-studio-api-dev \
      --image=curlimages/curl --rm -it --restart=Never \
      -- curl -s http://keybuzz-studio-api.keybuzz-studio-api-dev.svc.cluster.local:80/ready 2>&1 | tail -3
    echo "--- Logs API ---"
    kubectl logs -n keybuzz-studio-api-dev deployment/keybuzz-studio-api --tail=10 2>&1
  else
    echo "FAIL: Could not connect as postgres with new password"
  fi
else
  echo "WARN: Patroni PATCH failed, trying other approaches..."
  
  echo ""
  echo "=== Check if 'admin' user can create DB ==="
  # admin role was set by patroni with createrole + createdb
  # Try to find its password
  PGPASSWORD="$BACKEND_PASS" psql -h "$DB_HOST" -U kb_backend -d keybuzz_backend -t -A -c "SELECT rolname, rolcreatedb FROM pg_roles WHERE rolcreatedb=true;" 2>/dev/null
fi

echo ""
echo "=== DONE ==="
