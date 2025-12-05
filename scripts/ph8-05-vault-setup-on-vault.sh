#!/bin/bash
# PH8-05 - Vault Dynamic Credentials Setup (executed on vault-01)
set -e

export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"
export VAULT_TOKEN=$(cat /root/.vault-token 2>/dev/null || echo '')

if [ -z "$VAULT_TOKEN" ]; then
    echo "[ERROR] VAULT_TOKEN not found. Please login to Vault first."
    exit 1
fi

LOG_FILE="/opt/keybuzz/logs/phase8/ph8-05-vault-mariadb-setup.log"
mkdir -p /opt/keybuzz/logs/phase8/
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[INFO] =========================================="
echo "[INFO] PH8-05 - Vault Dynamic Credentials for MariaDB"
echo "[INFO] =========================================="
echo ""

# Step 1: Enable database secrets engine
echo "[INFO] Step 1: Enabling database secrets engine for MariaDB..."
if vault secrets enable -path=mariadb database 2>&1; then
    echo "[INFO]   ✅ Database secrets engine enabled"
elif vault secrets list | grep -q "^mariadb/"; then
    echo "[INFO]   ✅ Database secrets engine already enabled at mariadb/"
else
    echo "[ERROR]   ❌ Failed to enable database secrets engine"
    exit 1
fi

# Step 2: Configure Vault → MariaDB connection
echo ""
echo "[INFO] Step 2: Configuring Vault → MariaDB connection..."
HAPROXY_MARIADB="10.0.0.11:3306"
MARIADB_ROOT_PASSWORD="${MARIADB_ROOT_PASSWORD:-CHANGE_ME_LATER_VIA_VAULT}"

vault write mariadb/config/erpnext-mariadb \
    plugin_name="mysql-database-plugin" \
    connection_url="{{username}}:{{password}}@tcp(${HAPROXY_MARIADB})/" \
    allowed_roles="erpnext-mariadb-role" \
    username="root" \
    password="${MARIADB_ROOT_PASSWORD}" 2>&1

if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ MariaDB connection configured"
else
    echo "[ERROR]   ❌ Failed to configure MariaDB connection"
    exit 1
fi

# Step 3: Create dynamic role
echo ""
echo "[INFO] Step 3: Creating dynamic role erpnext-mariadb-role..."

PRIVS="SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EXECUTE, REFERENCES, CREATE TEMPORARY TABLES, LOCK TABLES"

vault write mariadb/roles/erpnext-mariadb-role \
    db_name="erpnext-mariadb" \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';
GRANT ${PRIVS} ON erpnextdb.* TO '{{name}}'@'%';
FLUSH PRIVILEGES;" \
    default_ttl="1h" \
    max_ttl="24h" 2>&1

if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ Dynamic role erpnext-mariadb-role created"
else
    echo "[ERROR]   ❌ Failed to create dynamic role"
    exit 1
fi

# Step 4: Create policy
echo ""
echo "[INFO] Step 4: Creating policy erpnext-db-policy..."

POLICY_FILE="/tmp/erpnext-db-policy.hcl"
cat <<EOF > ${POLICY_FILE}
path "mariadb/creds/erpnext-mariadb-role" {
  capabilities = ["read"]
}
EOF

vault policy write erpnext-db-policy ${POLICY_FILE} 2>&1
if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ Policy erpnext-db-policy created"
else
    echo "[ERROR]   ❌ Failed to create policy"
    exit 1
fi

# Step 5: Create AppRole
echo ""
echo "[INFO] Step 5: Creating AppRole erpnext-app..."

vault write auth/approle/role/erpnext-app \
    token_policies="erpnext-db-policy" \
    secret_id_ttl=0 \
    token_ttl=1h \
    token_max_ttl=4h 2>&1

if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ AppRole erpnext-app created"
else
    echo "[ERROR]   ❌ Failed to create AppRole"
    exit 1
fi

# Step 6: Get AppRole credentials
echo ""
echo "[INFO] Step 6: Retrieving AppRole credentials..."
vault read auth/approle/role/erpnext-app/role-id > /root/role_id_erpnext.txt 2>&1
vault write -force auth/approle/role/erpnext-app/secret-id > /root/secret_id_erpnext.txt 2>&1

if [ $? -eq 0 ]; then
    ROLE_ID=$(grep "role_id" /root/role_id_erpnext.txt | awk '{print $2}')
    SECRET_ID=$(grep "secret_id" /root/secret_id_erpnext.txt | awk '{print $2}')
    echo "[INFO]   ✅ Role ID: ${ROLE_ID}"
    echo "[INFO]   ✅ Secret ID: ${SECRET_ID:0:20}..."
    echo "[INFO]   ✅ Credentials saved to /root/role_id_erpnext.txt and /root/secret_id_erpnext.txt"
else
    echo "[ERROR]   ❌ Failed to retrieve AppRole credentials"
    exit 1
fi

# Step 7: Test dynamic credentials
echo ""
echo "[INFO] Step 7: Testing dynamic credentials generation..."
vault read mariadb/creds/erpnext-mariadb-role > /root/vault_erpnext_creds.txt 2>&1

if [ $? -eq 0 ]; then
    USER=$(grep "username" /root/vault_erpnext_creds.txt | awk '{print $2}')
    PASS=$(grep "password" /root/vault_erpnext_creds.txt | awk '{print $2}')
    echo "[INFO]   ✅ Dynamic credentials generated"
    echo "[INFO]   ✅ Username: ${USER}"
    echo "[INFO]   ✅ Password: ${PASS:0:10}..."
else
    echo "[ERROR]   ❌ Failed to generate dynamic credentials"
    exit 1
fi

# Step 8: Test connection via LB
echo ""
echo "[INFO] Step 8: Testing connection via LB (10.0.0.10:3306)..."
echo "[INFO]   Using dynamic credentials: ${USER}"

# Ensure mysql client is installed
if ! command -v mysql &> /dev/null; then
    echo "[INFO]   Installing mysql client..."
    apt-get update && apt-get install -y mariadb-client
fi

mysql -h 10.0.0.10 -P3306 -u "${USER}" -p"${PASS}" -e "
USE erpnextdb;
CREATE TABLE IF NOT EXISTS vault_test (id INT AUTO_INCREMENT PRIMARY KEY, v VARCHAR(255));
INSERT INTO vault_test (v) VALUES ('VAULT_OK');
SELECT * FROM vault_test;
" 2>&1 | tee /opt/keybuzz/logs/phase8/vault_mariadb_dynamic_test.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "[INFO]   ✅ Connection test successful via LB"
    echo "[INFO]   ✅ Table created, data inserted, and selected"
else
    echo "[ERROR]   ❌ Connection test failed"
    echo "[ERROR]   Check /opt/keybuzz/logs/phase8/vault_mariadb_dynamic_test.log for details"
    exit 1
fi

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ PH8-05 Vault Dynamic Credentials Setup Complete"
echo "[INFO] =========================================="
echo ""
echo "[INFO] Summary:"
echo "[INFO]   - Database secrets engine: mariadb/"
echo "[INFO]   - Dynamic role: erpnext-mariadb-role"
echo "[INFO]   - AppRole: erpnext-app"
echo "[INFO]   - Test credentials: ${USER}"
echo "[INFO]   - Test via LB: ✅ SUCCESS"
echo ""

