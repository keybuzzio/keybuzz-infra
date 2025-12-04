#!/bin/bash
# PH7-05 Complete Setup - Execute on install-v3
set -euo pipefail

VAULT_IP="10.0.0.150"
HAPROXY_IP="10.0.0.11"
POSTGRES_PORT="5432"
VAULT_ADDR_LOCAL="https://127.0.0.1:8200"

echo "=========================================="
echo "PH7-05 Complete Vault PostgreSQL Setup"
echo "=========================================="
echo ""

# Get PostgreSQL password
cd /opt/keybuzz/keybuzz-infra
PG_PASS=$(python3 << 'PYEOF'
import yaml
with open('ansible/group_vars/postgres.yml') as f:
    data = yaml.safe_load(f)
    print(data.get('postgres_superuser_password', 'CHANGE_ME'))
PYEOF
)

echo "PostgreSQL password retrieved: ${PG_PASS:0:8}..."
echo ""

# Execute configuration on vault-01
echo "Executing Vault configuration on vault-01..."
ssh -o StrictHostKeyChecking=no root@${VAULT_IP} bash <<VAULTCONFIG
export VAULT_ADDR="${VAULT_ADDR_LOCAL}"
export VAULT_SKIP_VERIFY="true"

echo "1. Enabling database secrets engine..."
vault secrets enable database 2>&1 | grep -v "path is already in use" || true

echo "2. Configuring database connection..."
vault write database/config/keybuzz-postgres \\
    plugin_name=postgresql-database-plugin \\
    allowed_roles="keybuzz-api-db,chatwoot-db,n8n-db,workers-db" \\
    connection_url="postgresql://{{username}}:{{password}}@${HAPROXY_IP}:${POSTGRES_PORT}/postgres?sslmode=disable" \\
    username="vault_admin" \\
    password="${PG_PASS}" 2>&1

echo "3. Creating dynamic roles..."
vault write database/roles/keybuzz-api-db \\
    db_name=keybuzz-postgres \\
    creation_statements='CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '\''{{password}}'\'' VALID UNTIL '\''{{expiration}}'\''; GRANT keybuzz_api TO "{{name}}";' \\
    default_ttl="1h" \\
    max_ttl="24h" 2>&1

vault write database/roles/chatwoot-db \\
    db_name=keybuzz-postgres \\
    creation_statements='CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '\''{{password}}'\'' VALID UNTIL '\''{{expiration}}'\''; GRANT chatwoot TO "{{name}}";' \\
    default_ttl="1h" \\
    max_ttl="24h" 2>&1

vault write database/roles/n8n-db \\
    db_name=keybuzz-postgres \\
    creation_statements='CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '\''{{password}}'\'' VALID UNTIL '\''{{expiration}}'\''; GRANT n8n TO "{{name}}";' \\
    default_ttl="1h" \\
    max_ttl="24h" 2>&1

vault write database/roles/workers-db \\
    db_name=keybuzz-postgres \\
    creation_statements='CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '\''{{password}}'\'' VALID UNTIL '\''{{expiration}}'\''; GRANT keybuzz_workers TO "{{name}}";' \\
    default_ttl="1h" \\
    max_ttl="24h" 2>&1

echo ""
echo "✅ Configuration completed!"
VAULTCONFIG

echo ""
echo "Verifying configuration..."
VAULT_CONFIG=$(ssh -o StrictHostKeyChecking=no root@${VAULT_IP} bash <<VERIFY
export VAULT_ADDR="${VAULT_ADDR_LOCAL}"
export VAULT_SKIP_VERIFY="true"
vault read database/config/keybuzz-postgres 2>&1 | head -8
VERIFY
)

echo "$VAULT_CONFIG"

ROLES_LIST=$(ssh -o StrictHostKeyChecking=no root@${VAULT_IP} bash <<ROLES
export VAULT_ADDR="${VAULT_ADDR_LOCAL}"
export VAULT_SKIP_VERIFY="true"
vault list database/roles 2>&1
ROLES
)

echo ""
echo "Roles configured:"
echo "$ROLES_LIST"

echo ""
echo "=========================================="
echo "✅ PH7-05 Setup Completed"
echo "=========================================="

