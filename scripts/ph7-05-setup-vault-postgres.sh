#!/bin/bash
# PH7-05 - Setup Vault Database Secrets Engine for PostgreSQL
# This script configures Vault to generate dynamic PostgreSQL credentials

set -euo pipefail

VAULT_IP="10.0.0.150"
VAULT_ADDR="https://vault.keybuzz.io:8200"
POSTGRES_LEADER="10.0.0.122"
HAPROXY_IP="10.0.0.11"
POSTGRES_PORT="5432"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get PostgreSQL superuser password
log_info "Récupération du mot de passe PostgreSQL..."
PG_SUPERUSER_PASSWORD=$(python3 << 'PYEOF'
import yaml
with open('ansible/group_vars/postgres.yml') as f:
    data = yaml.safe_load(f)
    print(data.get('postgres_superuser_password', 'CHANGE_ME'))
PYEOF
)

if [ "$PG_SUPERUSER_PASSWORD" == "CHANGE_ME" ] || [ "$PG_SUPERUSER_PASSWORD" == "CHANGE_ME_LATER_VIA_VAULT" ]; then
    log_warn "Mot de passe PostgreSQL est un placeholder"
fi

log_info "Mot de passe récupéré: ${PG_SUPERUSER_PASSWORD:0:8}..."

# Step 1: Create vault_admin user on PostgreSQL leader
log_info "Création de l'utilisateur vault_admin sur PostgreSQL..."
ssh root@${POSTGRES_LEADER} <<EOF
sudo -u postgres psql <<PSQL
DO \\\$\\\$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = 'vault_admin'
    ) THEN
        CREATE ROLE vault_admin WITH LOGIN PASSWORD '${PG_SUPERUSER_PASSWORD}' SUPERUSER;
    ELSE
        ALTER ROLE vault_admin WITH PASSWORD '${PG_SUPERUSER_PASSWORD}';
    END IF;
END
\\\$\\\$;
PSQL
EOF

log_info "✅ Utilisateur vault_admin créé/mis à jour"

# Step 2: Create database and roles
log_info "Création de la base de données keybuzz et des rôles..."
ssh root@${POSTGRES_LEADER} <<EOF
sudo -u postgres psql <<PSQL
-- Create database
SELECT 1 FROM pg_database WHERE datname = 'keybuzz' UNION ALL SELECT 0 LIMIT 1;
\\gexec
DO \\\$\\\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'keybuzz') THEN
        CREATE DATABASE keybuzz;
    END IF;
END
\\\$\\\$;

-- Create roles
DO \\\$\\\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'keybuzz_api') THEN
        CREATE ROLE keybuzz_api NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'chatwoot') THEN
        CREATE ROLE chatwoot NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'n8n') THEN
        CREATE ROLE n8n NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'keybuzz_workers') THEN
        CREATE ROLE keybuzz_workers NOLOGIN;
    END IF;
END
\\\$\\\$;

-- Grant permissions
GRANT CONNECT ON DATABASE keybuzz TO keybuzz_api, chatwoot, n8n, keybuzz_workers;
GRANT USAGE ON SCHEMA public TO keybuzz_api, chatwoot, n8n, keybuzz_workers;
PSQL
EOF

log_info "✅ Base de données et rôles créés"

# Step 3: Enable database secrets engine in Vault
log_info "Activation du secrets engine database dans Vault..."
ssh root@${VAULT_IP} bash <<EOF
export VAULT_ADDR="${VAULT_ADDR}"
export VAULT_SKIP_VERIFY=true

# Enable database secrets engine
vault secrets enable database 2>&1 | grep -v "path is already in use" || true

echo "✅ Secrets engine database activé"
EOF

log_info "✅ Secrets engine database activé"

# Step 4: Configure Vault database connection
log_info "Configuration de la connexion Vault → PostgreSQL..."
ssh root@${VAULT_IP} bash <<EOF
export VAULT_ADDR="${VAULT_ADDR}"
export VAULT_SKIP_VERIFY=true

vault write database/config/keybuzz-postgres \\
    plugin_name=postgresql-database-plugin \\
    allowed_roles="keybuzz-api-db,chatwoot-db,n8n-db,workers-db" \\
    connection_url="postgresql://{{username}}:{{password}}@${HAPROXY_IP}:${POSTGRES_PORT}/postgres?sslmode=disable" \\
    username="vault_admin" \\
    password="${PG_SUPERUSER_PASSWORD}"

echo "✅ Connexion Vault → PostgreSQL configurée"
EOF

log_info "✅ Connexion Vault → PostgreSQL configurée"

# Step 5: Create dynamic roles
log_info "Création des rôles dynamiques Vault..."

ssh root@${VAULT_IP} bash <<'VAULTROLES'
export VAULT_ADDR="https://vault.keybuzz.io:8200"
export VAULT_SKIP_VERIFY=true

# keybuzz-api-db
vault write database/roles/keybuzz-api-db \
    db_name=keybuzz-postgres \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT keybuzz_api TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"

# chatwoot-db
vault write database/roles/chatwoot-db \
    db_name=keybuzz-postgres \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT chatwoot TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"

# n8n-db
vault write database/roles/n8n-db \
    db_name=keybuzz-postgres \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT n8n TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"

# workers-db
vault write database/roles/workers-db \
    db_name=keybuzz-postgres \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT keybuzz_workers TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"

echo "✅ Rôles dynamiques créés"
VAULTROLES

log_info "✅ Rôles dynamiques créés"

log_info ""
log_info "=========================================="
log_info "✅ Configuration Vault PostgreSQL terminée"
log_info "=========================================="
log_info ""
log_info "Rôles dynamiques créés:"
log_info "  - keybuzz-api-db"
log_info "  - chatwoot-db"
log_info "  - n8n-db"
log_info "  - workers-db"
log_info ""
log_info "Pour tester:"
log_info "  vault read database/creds/keybuzz-api-db"

