#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=$(cat /root/.vault-cluster-root-token 2>/dev/null || echo "")

echo "=== admin-v2/bootstrap ==="
vault kv get -format=json secret/keybuzz/admin-v2/bootstrap 2>/dev/null | jq '.data.data | to_entries[] | "\(.key) = \(.value | tostring | length) chars"' || echo "not found"

echo ""
echo "=== admin-v2/postgres-prod ==="
vault kv get -format=json secret/keybuzz/admin-v2/postgres-prod 2>/dev/null | jq '.data.data | to_entries[] | "\(.key) = \(.value | tostring | length) chars"' || echo "not found"

echo ""
echo "=== List all root Vault paths ==="
vault kv list secret/ 2>/dev/null || true

echo ""
echo "=== Check secret/postgres ==="
vault kv get -format=json secret/postgres 2>/dev/null | jq '.data.data | keys[]' || echo "not found"

echo ""
echo "=== Check secret/keybuzz/test/ ==="
vault kv list secret/keybuzz/test/ 2>/dev/null || true

echo ""
echo "=== Try auth path ==="
vault kv get -format=json secret/keybuzz/dev/auth 2>/dev/null | jq '.data.data | to_entries[] | "\(.key) = \(.value | tostring | length) chars"' || echo "not found"
vault kv get -format=json secret/keybuzz/prod/auth 2>/dev/null | jq '.data.data | to_entries[] | "\(.key) = \(.value | tostring | length) chars"' || echo "not found"

echo ""
echo "=== Deep scan: find any key with 'postgres' user ==="
for p in $(vault kv list -format=json secret/keybuzz/admin-v2/ 2>/dev/null | jq -r '.[]'); do
  DATA=$(vault kv get -format=json "secret/keybuzz/admin-v2/$p" 2>/dev/null || echo "")
  if [ -n "$DATA" ]; then
    USER=$(echo "$DATA" | jq -r '.data.data.PGUSER // .data.data.username // .data.data.user // empty' 2>/dev/null || echo "")
    echo "admin-v2/$p -> user=$USER"
  fi
done

echo ""
echo "=== Check observability/ ==="
vault kv list secret/keybuzz/observability/ 2>/dev/null || true

echo ""
echo "=== Check litellm/ ==="
vault kv list secret/keybuzz/litellm/ 2>/dev/null || true
vault kv get -format=json secret/keybuzz/litellm/postgres 2>/dev/null | jq '.data.data.PGUSER // "not found"' || echo "not found"

echo ""
echo "=== Check ai/ ==="
vault kv list secret/keybuzz/ai/ 2>/dev/null || true

echo ""
echo "=== Try patroni/replication paths ==="
vault kv get -format=json secret/keybuzz/patroni 2>/dev/null | jq '.data.data | keys[]' || echo "not found"
vault kv get -format=json secret/keybuzz/replication 2>/dev/null | jq '.data.data | keys[]' || echo "not found"
vault kv get -format=json secret/keybuzz/db 2>/dev/null | jq '.data.data | keys[]' || echo "not found"

echo ""
echo "=== Check Patroni env on PG node ==="
# Can we get the superuser from the running pg config?
DB_HOST="10.0.0.10"
BACKEND_PASS=$(vault kv get -field=PGPASSWORD secret/keybuzz/dev/backend-postgres 2>/dev/null || echo "")
PGPASSWORD="$BACKEND_PASS" psql -h "$DB_HOST" -U kb_backend -d keybuzz_backend -t -A -c "SELECT rolname, rolsuper FROM pg_roles WHERE rolsuper = true;" 2>/dev/null || true

echo ""
echo "=== Check if kb_backend can alter roles ==="
PGPASSWORD="$BACKEND_PASS" psql -h "$DB_HOST" -U kb_backend -d keybuzz_backend -t -A -c "SELECT has_database_privilege('kb_backend', 'keybuzz_backend', 'CREATE');" 2>/dev/null || true

echo ""
echo "DONE"
