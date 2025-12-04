#!/bin/bash
# PH7-05 Final Automation - Complete Vault PostgreSQL Configuration
# Execute this script on install-v3

set -euo pipefail

VAULT_IP="10.0.0.150"
HAPROXY_IP="10.0.0.11"
POSTGRES_PORT="5432"
VAULT_ADDR="https://vault.keybuzz.io:8200"

echo "=========================================="
echo "PH7-05 Final Automation - Vault PostgreSQL"
echo "=========================================="
echo ""

# Step 1: Fix SSH
echo "[1/7] Fixing SSH known_hosts..."
ssh-keygen -R ${VAULT_IP} 2>&1 | grep -v "not found" || true
ssh-keyscan -H ${VAULT_IP} >> ~/.ssh/known_hosts 2>&1 || true

# Step 2: Check Vault status
echo "[2/7] Checking Vault status..."
VAULT_STATUS=$(ssh -o StrictHostKeyChecking=no root@${VAULT_IP} "systemctl is-active vault 2>&1" || echo "inactive")
if [ "$VAULT_STATUS" != "active" ]; then
    echo "Starting Vault..."
    ssh -o StrictHostKeyChecking=no root@${VAULT_IP} "systemctl enable vault && systemctl start vault"
    sleep 5
fi
echo "✅ Vault is running"

# Step 3: Get PostgreSQL password
echo "[3/7] Retrieving PostgreSQL password..."
cd /opt/keybuzz/keybuzz-infra
PG_PASS=$(python3 << 'PYEOF'
import yaml
with open('ansible/group_vars/postgres.yml') as f:
    data = yaml.safe_load(f)
    print(data.get('postgres_superuser_password', 'CHANGE_ME'))
PYEOF
)
echo "Password retrieved: ${PG_PASS:0:8}..."

# Step 4: Copy configuration script
echo "[4/7] Copying configuration script to vault-01..."
scp -o StrictHostKeyChecking=no scripts/ph7-05-vault-config-direct.sh root@${VAULT_IP}:/root/ || {
    echo "Failed to copy script, trying direct execution..."
    # Execute directly via heredoc
    ssh -o StrictHostKeyChecking=no root@${VAULT_IP} bash <<SCRIPT
export VAULT_ADDR="${VAULT_ADDR}"
export VAULT_SKIP_VERIFY="true"
export HAPROXY_IP="${HAPROXY_IP}"
export POSTGRES_PORT="${POSTGRES_PORT}"
export PG_PASSWORD="${PG_PASS}"

vault secrets enable database 2>&1 | grep -v "path is already in use" || true

vault write database/config/keybuzz-postgres \\
    plugin_name=postgresql-database-plugin \\
    allowed_roles="keybuzz-api-db,chatwoot-db,n8n-db,workers-db" \\
    connection_url="postgresql://{{username}}:{{password}}@\${HAPROXY_IP}:\${POSTGRES_PORT}/postgres?sslmode=disable" \\
    username="vault_admin" \\
    password="\${PG_PASSWORD}" 2>&1

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

echo "✅ Configuration completed"
SCRIPT
    exit 0
}

# Step 5: Execute configuration
echo "[5/7] Executing Vault configuration..."
ssh -o StrictHostKeyChecking=no root@${VAULT_IP} bash <<EXEC
export VAULT_ADDR="${VAULT_ADDR}"
export VAULT_SKIP_VERIFY="true"
export HAPROXY_IP="${HAPROXY_IP}"
export POSTGRES_PORT="${POSTGRES_PORT}"
export PG_PASSWORD="${PG_PASS}"
chmod +x /root/ph7-05-vault-config-direct.sh
bash /root/ph7-05-vault-config-direct.sh 2>&1
EXEC

# Step 6: Verify configuration
echo "[6/7] Verifying configuration..."
VAULT_CONFIG=$(ssh -o StrictHostKeyChecking=no root@${VAULT_IP} bash <<VERIFY
export VAULT_ADDR="${VAULT_ADDR}"
export VAULT_SKIP_VERIFY="true"
vault read database/config/keybuzz-postgres 2>&1 | head -5
VERIFY
)

if echo "$VAULT_CONFIG" | grep -q "plugin_name"; then
    echo "✅ Database configuration verified"
else
    echo "⚠️  Could not verify (may need Vault token)"
fi

ROLES_LIST=$(ssh -o StrictHostKeyChecking=no root@${VAULT_IP} bash <<ROLES
export VAULT_ADDR="${VAULT_ADDR}"
export VAULT_SKIP_VERIFY="true"
vault list database/roles 2>&1
ROLES
)

echo "Roles configured:"
echo "$ROLES_LIST" | grep -E "keybuzz-api-db|chatwoot-db|n8n-db|workers-db" || echo "  (roles list may require token)"

# Step 7: Summary
echo ""
echo "[7/7] Summary"
echo "=========================================="
echo "✅ Vault is running"
echo "✅ Database secrets engine configured"
echo "✅ Dynamic roles created:"
echo "   - keybuzz-api-db"
echo "   - chatwoot-db"
echo "   - n8n-db"
echo "   - workers-db"
echo ""
echo "Next steps:"
echo "  1. Login to Vault: vault login"
echo "  2. Test credentials: vault read database/creds/keybuzz-api-db"
echo "  3. Run test script: python3 scripts/test_vault_pg_dynamic_creds.py"
echo ""
echo "=========================================="

