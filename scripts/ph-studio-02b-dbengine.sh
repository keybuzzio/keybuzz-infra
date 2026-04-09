#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=$(cat /root/.vault-cluster-root-token 2>/dev/null || echo "")

DB_HOST="10.0.0.10"

echo "=== Check Vault database secret engine ==="
vault secrets list -format=json 2>/dev/null | jq 'to_entries[] | select(.key | startswith("database")) | {path: .key, type: .value.type}'

echo ""
echo "=== List database engine roles ==="
vault list database/roles 2>/dev/null || echo "no roles"

echo ""
echo "=== List database engine configs ==="
vault list database/config 2>/dev/null || echo "no configs"

echo ""
echo "=== Read database config ==="
for cfg in $(vault list -format=json database/config 2>/dev/null | jq -r '.[]' 2>/dev/null || echo ""); do
  echo "Config: $cfg"
  vault read "database/config/$cfg" 2>/dev/null | grep -E "connection_url|username|allowed_roles" || true
  echo ""
done

echo ""
echo "=== Try generating creds from database roles ==="
for role in $(vault list -format=json database/roles 2>/dev/null | jq -r '.[]' 2>/dev/null || echo ""); do
  echo "Role: $role"
  vault read "database/creds/$role" 2>/dev/null | head -10 || echo "failed"
  echo ""
done

echo ""
echo "=== Check secret/database/ path ==="
vault kv list secret/database/ 2>/dev/null || echo "empty"

echo ""
echo "=== litellm database_url (might reveal PG connection pattern) ==="
vault kv get -format=json secret/keybuzz/litellm/database_url 2>/dev/null | jq '.data.data | keys[]' || echo "not found"

echo ""
echo "=== Check if bastion can SSH to PG node ==="
ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@${DB_HOST} "whoami" 2>&1 | head -3 || echo "SSH to PG node failed"

echo ""
echo "=== Check patroni config on bastion ==="
cat /etc/patroni/patroni.yml 2>/dev/null | grep -A3 "superuser\|replication\|password" || echo "No patroni config on bastion"
find /opt/keybuzz -name "patroni*" -type f 2>/dev/null | head -5 || true
find /etc -name "patroni*" -type f 2>/dev/null | head -5 || true

echo ""
echo "=== PG node network check ==="
ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@${DB_HOST} "cat /etc/patroni/patroni.yml 2>/dev/null | grep -A2 superuser || cat /etc/patroni/*.yml 2>/dev/null | grep -A2 superuser || echo 'no patroni config found'" 2>&1 | head -10 || echo "Cannot access PG node"

echo ""
echo "DONE"
