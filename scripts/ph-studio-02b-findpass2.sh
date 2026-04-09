#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=$(cat /root/.vault-cluster-root-token 2>/dev/null || echo "")

echo "=== Check PH7 setup scripts for PG password ==="
grep -n "postgres_superuser_password\|PGPASSWORD.*postgres\|ALTER.*postgres.*PASSWORD" \
  /opt/keybuzz/keybuzz-infra/scripts/ph7-05-setup-vault-postgres.sh 2>/dev/null | head -15

echo ""
echo "=== ph7-05-complete-setup.sh ==="
grep -n "postgres_superuser_password\|PGPASSWORD\|SUPERUSER\|superuser" \
  /opt/keybuzz/keybuzz-infra/scripts/ph7-05-complete-setup.sh 2>/dev/null | head -15

echo ""
echo "=== ph7-05-full-automation.sh ==="
grep -n "postgres_superuser_password\|PGPASSWORD\|superuser" \
  /opt/keybuzz/keybuzz-infra/scripts/ph7-05-full-automation.sh 2>/dev/null | head -15

echo ""
echo "=== Check Vault for stored PG superuser password ==="
# Try common paths where the pg superuser password might be stored
for path in \
  "secret/keybuzz/postgres_superuser" \
  "secret/keybuzz/infra/postgres" \
  "secret/keybuzz/patroni" \
  "secret/keybuzz/db_superuser" \
  "secret/keybuzz/pg_admin" \
  "secret/infrastructure/postgres" \
  "secret/postgres" \
  "secret/patroni" \
  "secret/database/postgres"; do
  R=$(vault kv get -format=json "$path" 2>/dev/null || echo "")
  if [ -n "$R" ]; then
    echo "Found: $path"
    echo "$R" | jq '.data.data | keys[]' 2>/dev/null
  fi
done

echo ""
echo "=== Full vault list of secret/ ==="
vault kv list secret/ 2>/dev/null

echo ""
echo "=== Full vault list of secret/database/ ==="
vault kv list -format=json secret/database/ 2>/dev/null || echo "empty"

echo ""
echo "=== Check runbook for actual password used ==="
grep -n "postgres_superuser_password\|PGPASSWORD" \
  /opt/keybuzz/keybuzz-infra/keybuzz-docs/runbooks/PH7-02c-postgres-ha-bootstrap-success.md 2>/dev/null | head -10

echo ""
echo "=== Check Patroni API directly for leader ==="
curl -s http://10.0.0.121:8008/patroni 2>/dev/null | jq '{state, role, server_version}' 2>/dev/null || true
curl -s http://10.0.0.120:8008/patroni 2>/dev/null | jq '{state, role}' 2>/dev/null || true
curl -s http://10.0.0.122:8008/patroni 2>/dev/null | jq '{state, role}' 2>/dev/null || true

echo ""
echo "=== Check Patroni config via API (might expose superuser password) ==="
curl -s http://10.0.0.121:8008/config 2>/dev/null | jq 'if .postgresql.authentication.superuser then {superuser_exists: true} else {superuser_exists: false} end' 2>/dev/null || true

echo ""
echo "=== Check pg_hba.conf from Patroni ==="
curl -s http://10.0.0.121:8008/config 2>/dev/null | jq '.postgresql.pg_hba' 2>/dev/null || true

echo ""
echo "=== Try using Vault root to reset PG superuser password via Patroni REST API ==="
# Get current postgres password from Patroni config
PG_PASS_FROM_PATRONI=$(curl -s http://10.0.0.121:8008/config 2>/dev/null | jq -r '.postgresql.authentication.superuser.password // empty' 2>/dev/null || echo "")
if [ -n "$PG_PASS_FROM_PATRONI" ]; then
  echo "Found superuser password from Patroni API (length: ${#PG_PASS_FROM_PATRONI})"
  
  echo ""
  echo "=== Test postgres superuser connection ==="
  PGPASSWORD="$PG_PASS_FROM_PATRONI" psql -h 10.0.0.10 -U postgres -d postgres -c "SELECT current_user, current_database();" 2>&1
else
  echo "Patroni API did not expose superuser password"
fi

echo ""
echo "DONE"
