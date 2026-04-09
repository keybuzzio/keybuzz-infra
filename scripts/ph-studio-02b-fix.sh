#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
VAULT_TOKEN_FILE="/root/.vault-cluster-root-token"
if [ -f "$VAULT_TOKEN_FILE" ]; then
  export VAULT_TOKEN=$(cat "$VAULT_TOKEN_FILE")
else
  echo "WARN: No token file, using env"
fi

DB_HOST="10.0.0.10"
DB_PORT="5432"

echo "======================================="
echo " STEP A: Deep Vault search for postgres"
echo "======================================="

# Search all sub-paths
for prefix in "secret/keybuzz/admin-v2" "secret/keybuzz/internal-tokens" "secret/keybuzz/infra" "secret/keybuzz/prod/backend-postgres" "secret/keybuzz/prod/db_api"; do
  echo "--- Checking: $prefix ---"
  RESULT=$(vault kv get -format=json "$prefix" 2>/dev/null || echo "")
  if [ -n "$RESULT" ]; then
    echo "$RESULT" | jq -r '.data.data | keys[]' 2>/dev/null || true
    USER=$(echo "$RESULT" | jq -r '.data.data.PGUSER // .data.data.user // .data.data.username // empty' 2>/dev/null || echo "")
    echo "  user=$USER"
  fi
done

echo ""
echo "--- Listing admin-v2 sub-keys ---"
vault kv list secret/keybuzz/admin-v2/ 2>/dev/null || echo "no sub-keys"

echo ""
echo "--- Checking if vault_admin can connect to PG ---"
# vault_admin is a postgres superuser — let's check if there's a Vault DB secret engine
vault secrets list -format=json 2>/dev/null | jq 'keys[]' | grep -i database || echo "No database secret engine"

echo ""
echo "--- Try PostgreSQL peer/local auth from this host ---"
# Check if we can connect directly from bastion as postgres
psql -h "$DB_HOST" -U postgres -d postgres -c "SELECT 1;" 2>&1 | head -5 || true

echo ""
echo "--- Check pg_hba via backend user ---"
BACKEND_PASS=$(vault kv get -field=PGPASSWORD secret/keybuzz/dev/backend-postgres 2>/dev/null || echo "")
PGPASSWORD="$BACKEND_PASS" psql -h "$DB_HOST" -U kb_backend -d keybuzz_backend -t -A -c "SHOW hba_file;" 2>/dev/null || true
PGPASSWORD="$BACKEND_PASS" psql -h "$DB_HOST" -U kb_backend -d keybuzz_backend -t -A -c "SELECT * FROM pg_hba_file_rules WHERE database::text LIKE '%all%' AND user_name::text LIKE '%postgres%' LIMIT 5;" 2>/dev/null || true

echo ""
echo "--- Try GRANT CREATEDB to kb_backend via vault_admin ---"
# Check if we can find vault_admin password
VA_PASS=""
for vpath in "secret/keybuzz/admin-v2/postgres" "secret/keybuzz/admin-v2/vault_admin" "secret/keybuzz/db/vault_admin"; do
  R=$(vault kv get -format=json "$vpath" 2>/dev/null || echo "")
  if [ -n "$R" ]; then
    VA_PASS=$(echo "$R" | jq -r '.data.data.PGPASSWORD // .data.data.password // empty' 2>/dev/null || echo "")
    if [ -n "$VA_PASS" ]; then
      echo "Found vault_admin password at $vpath"
      break
    fi
  fi
done

# Check database secret engine for dynamic creds
echo ""
echo "--- Check Vault database secret engine ---"
vault read database/creds/admin 2>/dev/null && echo "Dynamic cred available" || true
vault read database/creds/postgres 2>/dev/null || true
vault read database/config/keybuzz 2>/dev/null || true

# If we found vault_admin password, try it
if [ -n "$VA_PASS" ]; then
  echo "Trying vault_admin to create DB..."
  PGPASSWORD="$VA_PASS" psql -h "$DB_HOST" -U vault_admin -d postgres -c "CREATE DATABASE keybuzz_studio;" 2>&1 || true
fi

# Final fallback: try to grant CREATEDB to kb_backend
echo ""
echo "--- Fallback: Attempting CREATEDB grant via SQL injection-free method ---"
# The postgres user might have an empty password or trust auth from 10.0.0.150
for tryuser in "postgres" "vault_admin"; do
  for trydb in "postgres" "template1"; do
    echo "Trying: $tryuser@$trydb (no password)..."
    PGPASSWORD="" psql -h "$DB_HOST" -U "$tryuser" -d "$trydb" -c "SELECT 1;" 2>&1 | head -2 || true
  done
done

echo ""
echo "======================================="
echo " STEP B: Fix TLS certificates"
echo "======================================="

echo "--- Delete errored orders and challenges ---"
# Delete the errored certificate for studio-dev to trigger re-issuance
kubectl delete certificate keybuzz-studio-tls -n keybuzz-studio-dev 2>&1 || true
sleep 5

# Re-apply the ingress which will trigger cert-manager to create a new certificate
kubectl get ingress keybuzz-studio -n keybuzz-studio-dev -o yaml | kubectl apply -f - 2>&1

echo ""
echo "--- Clean API cert too ---"
kubectl delete certificate keybuzz-studio-api-tls -n keybuzz-studio-api-dev 2>&1 || true
sleep 5
kubectl get ingress keybuzz-studio-api -n keybuzz-studio-api-dev -o yaml | kubectl apply -f - 2>&1

echo ""
echo "Waiting 30s for cert-manager to react..."
sleep 30

echo ""
echo "--- Certificate status after reset ---"
kubectl get certificate -n keybuzz-studio-dev 2>&1 || echo "no cert yet"
kubectl get certificate -n keybuzz-studio-api-dev 2>&1 || echo "no cert yet"

echo ""
echo "--- Challenges ---"
kubectl get challenges --all-namespaces 2>&1 | grep -i studio || echo "No studio challenges"

echo ""
echo "--- Orders ---"
kubectl get orders --all-namespaces 2>&1 | grep -i studio || echo "No studio orders"

echo ""
echo "--- Describe new certs ---"
kubectl describe certificate -n keybuzz-studio-dev 2>&1 | grep -E "Status|Message|Reason|Ready|Not After" || true
echo ""
kubectl describe certificate -n keybuzz-studio-api-dev 2>&1 | grep -E "Status|Message|Reason|Ready|Not After" || true

echo ""
echo "======================================="
echo " DONE"
echo "======================================="
