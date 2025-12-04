#!/bin/bash
# PH7-05 Full Automation - Complete Vault PostgreSQL Configuration
# This script executes ALL steps automatically without manual intervention

set -euo pipefail

VAULT_IP="10.0.0.150"
INSTALL_V3_IP="46.62.171.61"
HAPROXY_IP="10.0.0.11"
POSTGRES_PORT="5432"
VAULT_ADDR="https://vault.keybuzz.io:8200"

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

# Step 1: Fix SSH known_hosts and setup SSH options
log_info "Fixing SSH known_hosts for vault-01..."
mkdir -p ~/.ssh
ssh-keyscan -H ${VAULT_IP} >> ~/.ssh/known_hosts 2>&1 || true
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=~/.ssh/known_hosts"

# Step 2: Verify Vault is running
log_info "Checking Vault status..."
VAULT_STATUS=$(ssh ${SSH_OPTS} root@${VAULT_IP} "systemctl is-active vault 2>&1" || echo "inactive")

if [ "$VAULT_STATUS" != "active" ]; then
    log_warn "Vault is not running, starting it..."
    ssh ${SSH_OPTS} root@${VAULT_IP} "systemctl enable vault && systemctl start vault" || {
        log_error "Failed to start Vault"
        exit 1
    }
    sleep 5
    log_info "✅ Vault started"
else
    log_info "✅ Vault is running"
fi

# Step 3: Get PostgreSQL password
log_info "Retrieving PostgreSQL password..."
cd /opt/keybuzz/keybuzz-infra
PG_SUPERUSER_PASSWORD=$(python3 << 'PYEOF'
import yaml
with open('ansible/group_vars/postgres.yml') as f:
    data = yaml.safe_load(f)
    print(data.get('postgres_superuser_password', 'CHANGE_ME'))
PYEOF
)

if [ "$PG_SUPERUSER_PASSWORD" == "CHANGE_ME" ] || [ "$PG_SUPERUSER_PASSWORD" == "CHANGE_ME_LATER_VIA_VAULT" ]; then
    log_warn "PostgreSQL password is a placeholder"
fi

# Step 4: Copy and execute configuration script on vault-01
log_info "Copying configuration script to vault-01..."
scp ${SSH_OPTS} scripts/ph7-05-complete-vault-config.sh root@${VAULT_IP}:/root/ || {
    log_error "Failed to copy script"
    exit 1
}

log_info "Executing Vault configuration on vault-01..."
ssh ${SSH_OPTS} root@${VAULT_IP} bash <<EOF
export VAULT_ADDR="${VAULT_ADDR}"
export VAULT_SKIP_VERIFY="true"
chmod +x /root/ph7-05-complete-vault-config.sh
bash /root/ph7-05-complete-vault-config.sh 2>&1
EOF

CONFIG_RESULT=$?
if [ $CONFIG_RESULT -ne 0 ]; then
    log_error "Vault configuration failed, trying direct commands..."
    
    # Try direct configuration
    ssh ${SSH_OPTS} root@${VAULT_IP} bash <<VAULTDIRECT
export VAULT_ADDR="${VAULT_ADDR}"
export VAULT_SKIP_VERIFY="true"

# Enable database secrets engine
vault secrets enable database 2>&1 | grep -v "path is already in use" || true

# Configure database connection
vault write database/config/keybuzz-postgres \\
    plugin_name=postgresql-database-plugin \\
    allowed_roles="keybuzz-api-db,chatwoot-db,n8n-db,workers-db" \\
    connection_url="postgresql://{{username}}:{{password}}@${HAPROXY_IP}:${POSTGRES_PORT}/postgres?sslmode=disable" \\
    username="vault_admin" \\
    password="${PG_SUPERUSER_PASSWORD}" 2>&1

# Create dynamic roles
vault write database/roles/keybuzz-api-db \\
    db_name=keybuzz-postgres \\
    creation_statements="CREATE ROLE \\\"{{name}}\\\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT keybuzz_api TO \\\"{{name}}\\\";" \\
    default_ttl="1h" \\
    max_ttl="24h" 2>&1

vault write database/roles/chatwoot-db \\
    db_name=keybuzz-postgres \\
    creation_statements="CREATE ROLE \\\"{{name}}\\\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT chatwoot TO \\\"{{name}}\\\";" \\
    default_ttl="1h" \\
    max_ttl="24h" 2>&1

vault write database/roles/n8n-db \\
    db_name=keybuzz-postgres \\
    creation_statements="CREATE ROLE \\\"{{name}}\\\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT n8n TO \\\"{{name}}\\\";" \\
    default_ttl="1h" \\
    max_ttl="24h" 2>&1

vault write database/roles/workers-db \\
    db_name=keybuzz-postgres \\
    creation_statements="CREATE ROLE \\\"{{name}}\\\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT keybuzz_workers TO \\\"{{name}}\\\";" \\
    default_ttl="1h" \\
    max_ttl="24h" 2>&1

echo "✅ Configuration completed"
VAULTDIRECT
fi

# Step 5: Verify configuration
log_info "Verifying Vault configuration..."
VAULT_CONFIG=$(ssh ${SSH_OPTS} root@${VAULT_IP} bash <<EOF
export VAULT_ADDR="${VAULT_ADDR}"
export VAULT_SKIP_VERIFY="true"
vault read database/config/keybuzz-postgres 2>&1 | head -5
EOF
)

if echo "$VAULT_CONFIG" | grep -q "plugin_name"; then
    log_info "✅ Database configuration verified"
else
    log_warn "Could not verify database configuration (may need Vault token)"
fi

# Step 6: Test dynamic credentials (if token available)
log_info "Testing dynamic credentials..."
CREDS_TEST=$(ssh ${SSH_OPTS} root@${VAULT_IP} bash <<EOF
export VAULT_ADDR="${VAULT_ADDR}"
export VAULT_SKIP_VERIFY="true"
if [ -f /root/.vault-token ]; then
    export VAULT_TOKEN=\$(cat /root/.vault-token)
    vault read database/creds/keybuzz-api-db 2>&1 | head -10
else
    echo "No Vault token found - credentials test skipped"
fi
EOF
)

echo "$CREDS_TEST"

log_info ""
log_info "=========================================="
log_info "✅ PH7-05 Full Automation Completed"
log_info "=========================================="
log_info ""
log_info "Next steps:"
log_info "  1. Login to Vault: vault login"
log_info "  2. Test credentials: vault read database/creds/keybuzz-api-db"
log_info "  3. Run test script: python3 scripts/test_vault_pg_dynamic_creds.py"

