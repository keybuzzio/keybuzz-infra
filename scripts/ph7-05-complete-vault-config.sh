#!/bin/bash
# PH7-05 - Complete Vault PostgreSQL Configuration
# This script completes the Vault database configuration

set -euo pipefail

VAULT_ADDR="https://vault.keybuzz.io:8200"
VAULT_SKIP_VERIFY="true"
HAPROXY_IP="10.0.0.11"
POSTGRES_PORT="5432"

# Get PostgreSQL password from install-v3
PG_SUPERUSER_PASSWORD=$(ssh root@46.62.171.61 "cd /opt/keybuzz/keybuzz-infra && python3 << 'PYEOF'
import yaml
with open('ansible/group_vars/postgres.yml') as f:
    data = yaml.safe_load(f)
    print(data.get('postgres_superuser_password', 'CHANGE_ME'))
PYEOF
")

export VAULT_ADDR
export VAULT_SKIP_VERIFY

echo "Configuring Vault database secrets engine..."

# Enable database secrets engine
echo "1. Enabling database secrets engine..."
vault secrets enable database 2>&1 | grep -v "path is already in use" || true

# Configure database connection
echo "2. Configuring database connection..."
vault write database/config/keybuzz-postgres \
    plugin_name=postgresql-database-plugin \
    allowed_roles="keybuzz-api-db,chatwoot-db,n8n-db,workers-db" \
    connection_url="postgresql://{{username}}:{{password}}@${HAPROXY_IP}:${POSTGRES_PORT}/postgres?sslmode=disable" \
    username="vault_admin" \
    password="${PG_SUPERUSER_PASSWORD}"

# Create dynamic roles
echo "3. Creating dynamic roles..."

vault write database/roles/keybuzz-api-db \
    db_name=keybuzz-postgres \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT keybuzz_api TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"

vault write database/roles/chatwoot-db \
    db_name=keybuzz-postgres \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT chatwoot TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"

vault write database/roles/n8n-db \
    db_name=keybuzz-postgres \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT n8n TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"

vault write database/roles/workers-db \
    db_name=keybuzz-postgres \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT keybuzz_workers TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"

echo ""
echo "✅ Configuration completed!"
echo ""
echo "Test with:"
echo "  vault read database/creds/keybuzz-api-db"

