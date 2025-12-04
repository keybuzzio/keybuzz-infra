#!/bin/bash
# PH7-05 Direct Vault Configuration - Execute this on vault-01
set -e

VAULT_ADDR="${VAULT_ADDR:-https://vault.keybuzz.io:8200}"
VAULT_SKIP_VERIFY="${VAULT_SKIP_VERIFY:-true}"
HAPROXY_IP="${HAPROXY_IP:-10.0.0.11}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
PG_PASSWORD="${PG_PASSWORD:-CHANGE_ME_LATER_VIA_VAULT}"

export VAULT_ADDR
export VAULT_SKIP_VERIFY

echo "Configuring Vault database secrets engine..."
echo "VAULT_ADDR: $VAULT_ADDR"
echo "HAPROXY_IP: $HAPROXY_IP:$POSTGRES_PORT"

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
    password="${PG_PASSWORD}" 2>&1

# Create dynamic roles
echo "3. Creating dynamic roles..."

vault write database/roles/keybuzz-api-db \
    db_name=keybuzz-postgres \
    creation_statements='CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '\''{{password}}'\'' VALID UNTIL '\''{{expiration}}'\''; GRANT keybuzz_api TO "{{name}}";' \
    default_ttl="1h" \
    max_ttl="24h" 2>&1

vault write database/roles/chatwoot-db \
    db_name=keybuzz-postgres \
    creation_statements='CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '\''{{password}}'\'' VALID UNTIL '\''{{expiration}}'\''; GRANT chatwoot TO "{{name}}";' \
    default_ttl="1h" \
    max_ttl="24h" 2>&1

vault write database/roles/n8n-db \
    db_name=keybuzz-postgres \
    creation_statements='CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '\''{{password}}'\'' VALID UNTIL '\''{{expiration}}'\''; GRANT n8n TO "{{name}}";' \
    default_ttl="1h" \
    max_ttl="24h" 2>&1

vault write database/roles/workers-db \
    db_name=keybuzz-postgres \
    creation_statements='CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '\''{{password}}'\'' VALID UNTIL '\''{{expiration}}'\''; GRANT keybuzz_workers TO "{{name}}";' \
    default_ttl="1h" \
    max_ttl="24h" 2>&1

echo ""
echo "✅ Configuration completed!"
echo ""
echo "Verify with:"
echo "  vault read database/config/keybuzz-postgres"
echo "  vault read database/roles/keybuzz-api-db"

