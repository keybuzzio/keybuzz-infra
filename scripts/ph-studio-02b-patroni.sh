#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=$(cat /root/.vault-cluster-root-token 2>/dev/null || echo "")

echo "=== Patroni template (superuser section) ==="
grep -A5 -B2 "superuser\|postgres.*password\|replication" /opt/keybuzz/keybuzz-infra/patroni.yml.j2 2>/dev/null | head -30 || true

echo ""
echo "=== Ansible patroni template ==="
grep -A5 -B2 "superuser\|postgres.*password\|replication" /opt/keybuzz/keybuzz-infra/ansible/roles/postgres_ha_v3/templates/patroni.yml.j2 2>/dev/null | head -30 || true

echo ""
echo "=== Check Ansible vault files ==="
find /opt/keybuzz/keybuzz-infra/ansible -name "vault*" -o -name "secrets*" -o -name "group_vars*" 2>/dev/null | head -10

echo ""
echo "=== Check group_vars for PG password ==="
find /opt/keybuzz/keybuzz-infra/ansible -name "*.yml" -path "*/group_vars/*" 2>/dev/null | while read f; do
  if grep -q "postgres\|pg_super\|superuser" "$f" 2>/dev/null; then
    echo "--- $f ---"
    grep -A2 "postgres\|pg_super\|superuser" "$f" | head -10
  fi
done

echo ""
echo "=== Vault secret/database/creds/ ==="
vault kv list secret/database/creds/ 2>/dev/null || echo "empty"
for item in $(vault kv list -format=json secret/database/creds/ 2>/dev/null | jq -r '.[]' 2>/dev/null || echo ""); do
  echo "creds/$item:"
  vault kv get -format=json "secret/database/creds/$item" 2>/dev/null | jq '.data.data | keys[]' || true
done

echo ""
echo "=== litellm database_url value (check user) ==="
LURL=$(vault kv get -field=value secret/keybuzz/litellm/database_url 2>/dev/null || echo "")
if [ -n "$LURL" ]; then
  echo "$LURL" | sed -E 's|://([^:]+):([^@]+)@|://\1:***@|'
fi

echo ""
echo "=== Patroni state backup ==="
cat /opt/keybuzz/backups/dr/weekly/20260322/postgres/patroni_state.txt 2>/dev/null | head -20

echo ""
echo "=== Check Vault for patroni-specific secrets ==="
vault kv get -format=json secret/keybuzz/patroni 2>/dev/null | jq '.data.data | keys[]' || echo "not found"
vault kv list secret/keybuzz/db/ 2>/dev/null || echo "no secret/keybuzz/db/"

echo ""
echo "=== Ansible inventory for pg password references ==="
grep -rl "postgres_password\|pg_superuser\|pg_password" /opt/keybuzz/keybuzz-infra/ansible/ 2>/dev/null | head -10

echo ""
echo "DONE"
