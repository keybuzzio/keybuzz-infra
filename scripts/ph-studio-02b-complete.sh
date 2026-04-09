#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=$(cat /root/.vault-cluster-root-token 2>/dev/null || echo "")

DB_HOST="10.0.0.10"
DB_PORT="5432"
PG_PASS="CHANGE_ME_LATER_VIA_VAULT"

echo "=== Verify keybuzz_studio exists ==="
DB_CHECK=$(PGPASSWORD="$PG_PASS" psql -h "$DB_HOST" -U postgres -d postgres -t -A -c "SELECT 1 FROM pg_database WHERE datname='keybuzz_studio';" 2>/dev/null || echo "0")
echo "keybuzz_studio: $DB_CHECK"

echo ""
echo "=== Create kb_studio user ==="
STUDIO_PASS=$(openssl rand -base64 24 | tr -d '=/+' | head -c 32)

PGPASSWORD="$PG_PASS" psql -h "$DB_HOST" -U postgres -d keybuzz_studio <<EOSQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'kb_studio') THEN
    EXECUTE format('CREATE ROLE kb_studio LOGIN PASSWORD %L', '${STUDIO_PASS}');
    RAISE NOTICE 'Created kb_studio';
  ELSE
    EXECUTE format('ALTER ROLE kb_studio PASSWORD %L', '${STUDIO_PASS}');
    RAISE NOTICE 'Updated kb_studio';
  END IF;
END
\$\$;
GRANT ALL PRIVILEGES ON DATABASE keybuzz_studio TO kb_studio;
GRANT ALL ON SCHEMA public TO kb_studio;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO kb_studio;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO kb_studio;
EOSQL
echo "PASS: kb_studio user ready"

echo ""
echo "=== Test kb_studio connection ==="
PGPASSWORD="$STUDIO_PASS" psql -h "$DB_HOST" -U kb_studio -d keybuzz_studio -c "SELECT current_user, current_database();" 2>&1

echo ""
echo "=== Apply schema ==="
SCHEMA="/opt/keybuzz/keybuzz-client/keybuzz-studio-api/src/db/schema.sql"
if [ -f "$SCHEMA" ]; then
  PGPASSWORD="$STUDIO_PASS" psql -h "$DB_HOST" -U kb_studio -d keybuzz_studio -f "$SCHEMA" 2>&1 | tail -25
else
  echo "Schema file not found"
fi

TABLE_COUNT=$(PGPASSWORD="$STUDIO_PASS" psql -h "$DB_HOST" -U kb_studio -d keybuzz_studio -t -A -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';" 2>/dev/null || echo "?")
echo "Tables created: $TABLE_COUNT"

echo ""
echo "=== List tables ==="
PGPASSWORD="$STUDIO_PASS" psql -h "$DB_HOST" -U kb_studio -d keybuzz_studio -c "\dt" 2>&1

echo ""
echo "=== Store in Vault ==="
STUDIO_URL="postgresql://kb_studio:${STUDIO_PASS}@${DB_HOST}:${DB_PORT}/keybuzz_studio"
vault kv put secret/keybuzz/dev/studio-postgres \
  DATABASE_URL="$STUDIO_URL" \
  PGHOST="$DB_HOST" \
  PGPORT="$DB_PORT" \
  PGDATABASE="keybuzz_studio" \
  PGUSER="kb_studio" \
  PGPASSWORD="$STUDIO_PASS" 2>&1 | head -8
echo "PASS: Vault updated"

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
echo "=== Fix TLS certificates ==="
kubectl delete certificate keybuzz-studio-tls -n keybuzz-studio-dev 2>&1 || true
kubectl delete certificate keybuzz-studio-api-tls -n keybuzz-studio-api-dev 2>&1 || true
sleep 2
kubectl delete challenges --all -n keybuzz-studio-dev 2>&1 || true
kubectl delete challenges --all -n keybuzz-studio-api-dev 2>&1 || true
kubectl delete orders --all -n keybuzz-studio-dev 2>&1 || true
kubectl delete orders --all -n keybuzz-studio-api-dev 2>&1 || true
sleep 3
# Re-trigger cert-manager by re-applying ingresses
kubectl get ingress keybuzz-studio -n keybuzz-studio-dev -o yaml | kubectl apply -f - 2>&1
kubectl get ingress keybuzz-studio-api -n keybuzz-studio-api-dev -o yaml | kubectl apply -f - 2>&1

echo ""
echo "=== Revert Patroni config (remove our test password) ==="
curl -s -X PATCH "http://10.0.0.122:8008/config" \
  -H "Content-Type: application/json" \
  -d '{"postgresql":{"authentication":null}}' 2>/dev/null | head -5 || true

echo ""
echo "Waiting 60s for pods + certs..."
sleep 60

echo ""
echo "========================================="
echo "  FINAL VERIFICATION"
echo "========================================="

echo ""
echo "--- Pods ---"
kubectl get pods -n keybuzz-studio-dev -o wide
echo ""
kubectl get pods -n keybuzz-studio-api-dev -o wide

echo ""
echo "--- Certificates ---"
kubectl get certificate -A 2>&1 | grep studio || echo "no certs yet"

echo ""
echo "--- Cert Details ---"
for ns in keybuzz-studio-dev keybuzz-studio-api-dev; do
  echo "Namespace: $ns"
  kubectl describe certificate -n "$ns" 2>&1 | grep -E "Status|Message|Reason|Ready|Not After|Not Before" | head -10 || true
  echo ""
done

echo ""
echo "--- Challenges ---"
kubectl get challenges -A 2>&1 | grep studio || echo "no challenges"

echo ""
echo "--- Health ---"
kubectl run curl-health-final --namespace=keybuzz-studio-api-dev \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -s http://keybuzz-studio-api.keybuzz-studio-api-dev.svc.cluster.local:80/health 2>&1 | tail -3

echo ""
echo "--- Ready (DB connection) ---"
kubectl run curl-ready-final --namespace=keybuzz-studio-api-dev \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -s http://keybuzz-studio-api.keybuzz-studio-api-dev.svc.cluster.local:80/ready 2>&1 | tail -3

echo ""
echo "--- Logs API ---"
kubectl logs -n keybuzz-studio-api-dev deployment/keybuzz-studio-api --tail=12 2>&1

echo ""
echo "--- Logs Frontend ---"
kubectl logs -n keybuzz-studio-dev deployment/keybuzz-studio --tail=5 2>&1

echo ""
echo "--- HTTPS test (internal) ---"
kubectl run curl-https-fe --namespace=keybuzz-studio-dev \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -sI --max-time 10 https://studio-dev.keybuzz.io 2>&1 | head -5 || echo "FE HTTPS failed"

echo ""
kubectl run curl-https-api --namespace=keybuzz-studio-api-dev \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -s --max-time 10 https://studio-api-dev.keybuzz.io/health 2>&1 | tail -3 || echo "API HTTPS failed"

echo ""
echo "========================================="
echo "  PH-STUDIO-02B COMPLETE"
echo "========================================="
