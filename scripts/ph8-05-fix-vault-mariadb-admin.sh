#!/bin/bash
# PH8-05 FIX - Correct MariaDB admin user for Vault
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase8/ph8-05-fix-vault-mariadb-admin.log"
mkdir -p /opt/keybuzz/logs/phase8/
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[INFO] =========================================="
echo "[INFO] PH8-05 FIX - Correct MariaDB admin user for Vault"
echo "[INFO] =========================================="
echo ""

# Vault configuration
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"

# MariaDB configuration
MARIADB_LEADER="10.0.0.171"
HAPROXY_MARIADB="10.0.0.11:3306"
MARIADB_ROOT_PASSWORD="${MARIADB_ROOT_PASSWORD:-CHANGE_ME_LATER_VIA_VAULT}"

# Step 1: Create vault_admin user on MariaDB leader
echo "[INFO] Step 1: Creating vault_admin user on MariaDB leader (${MARIADB_LEADER})..."

# Check if vault_admin already exists
VAULT_ADMIN_EXISTS=$(ssh root@${MARIADB_LEADER} "mysql -u root -p\"${MARIADB_ROOT_PASSWORD}\" -e \"SELECT COUNT(*) FROM mysql.user WHERE User='vault_admin';\" 2>&1" | grep -v "Warning" | tail -1 | awk '{print $1}')

if [ "$VAULT_ADMIN_EXISTS" = "1" ]; then
    echo "[INFO]   vault_admin user already exists, resetting password..."
    # Generate new password
    VAULT_ADMIN_PASS=$(openssl rand -hex 16)
    echo "[INFO]   Generated new password for vault_admin: ${VAULT_ADMIN_PASS:0:10}..."
    
    # Reset password
    ssh root@${MARIADB_LEADER} bash <<RESET_PASS
set -e
mysql -u root -p"${MARIADB_ROOT_PASSWORD}" <<SQL
ALTER USER 'vault_admin'@'%' IDENTIFIED BY '${VAULT_ADMIN_PASS}';
FLUSH PRIVILEGES;
SELECT User, Host FROM mysql.user WHERE User='vault_admin';
SQL
RESET_PASS
else
    # Generate password
    VAULT_ADMIN_PASS=$(openssl rand -hex 16)
    echo "[INFO]   Generated password for vault_admin: ${VAULT_ADMIN_PASS:0:10}..."
    
    # Create user on leader
    ssh root@${MARIADB_LEADER} bash <<CREATE_USER
set -e
mysql -u root -p"${MARIADB_ROOT_PASSWORD}" <<SQL
CREATE USER IF NOT EXISTS 'vault_admin'@'%' IDENTIFIED BY '${VAULT_ADMIN_PASS}';
GRANT ALL PRIVILEGES ON *.* TO 'vault_admin'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SELECT User, Host FROM mysql.user WHERE User='vault_admin';
SQL
CREATE_USER
fi

if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ vault_admin user created successfully"
else
    echo "[ERROR]   ❌ Failed to create vault_admin user"
    exit 1
fi

# Verify user exists on all nodes (Galera replication)
echo ""
echo "[INFO] Step 2: Verifying vault_admin user replication..."
for node_ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "[INFO]   Checking ${node_ip}..."
    if ssh root@${node_ip} "mysql -u root -p\"${MARIADB_ROOT_PASSWORD}\" -e \"SELECT User, Host FROM mysql.user WHERE User='vault_admin';\" 2>&1 | grep -q vault_admin"; then
        echo "[INFO]     ✅ vault_admin exists on ${node_ip}"
    else
        echo "[WARN]     ⚠️  vault_admin not found on ${node_ip} (may need manual replication)"
    fi
done

# Step 3: Update Vault configuration
echo ""
echo "[INFO] Step 3: Updating Vault configuration with vault_admin..."

# Get Vault token from vault-01
VAULT_TOKEN=$(ssh root@10.0.0.150 "cat /root/.vault-token 2>/dev/null" || echo '')

if [ -z "$VAULT_TOKEN" ]; then
    echo "[ERROR]   ❌ VAULT_TOKEN not found. Please ensure Vault is accessible and token is available."
    exit 1
fi

export VAULT_TOKEN

# Update Vault configuration via vault-01
ssh root@10.0.0.150 bash <<UPDATE_VAULT
set -e
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"
export VAULT_TOKEN=\$(cat /root/.vault-token 2>/dev/null)

if [ -z "\$VAULT_TOKEN" ]; then
    echo "[ERROR] VAULT_TOKEN not found on vault-01"
    exit 1
fi

# Update MariaDB connection configuration
vault write mariadb/config/erpnext-mariadb \\
    plugin_name="mysql-database-plugin" \\
    connection_url="{{username}}:{{password}}@tcp(${HAPROXY_MARIADB})/" \\
    allowed_roles="erpnext-mariadb-role" \\
    username="vault_admin" \\
    password="${VAULT_ADMIN_PASS}" 2>&1

if [ \$? -eq 0 ]; then
    echo "[INFO]   ✅ Vault configuration updated successfully"
else
    echo "[ERROR]   ❌ Failed to update Vault configuration"
    exit 1
fi
UPDATE_VAULT

if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ Vault configuration updated"
else
    echo "[ERROR]   ❌ Failed to update Vault configuration"
    exit 1
fi

# Step 4: Test dynamic credentials generation
echo ""
echo "[INFO] Step 4: Testing dynamic credentials generation..."

ssh root@10.0.0.150 bash <<TEST_CREDS
set -e
export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"
export VAULT_TOKEN=\$(cat /root/.vault-token 2>/dev/null)

# Generate dynamic credentials
vault read mariadb/creds/erpnext-mariadb-role > /tmp/vault_erpnext_creds.txt 2>&1

if [ \$? -eq 0 ]; then
    USER=\$(grep "username" /tmp/vault_erpnext_creds.txt | awk '{print \$2}')
    PASS=\$(grep "password" /tmp/vault_erpnext_creds.txt | awk '{print \$2}')
    echo "[INFO]   ✅ Dynamic credentials generated"
    echo "[INFO]   ✅ Username: \${USER}"
    echo "[INFO]   ✅ Password: \${PASS:0:10}..."
    echo "\${USER}" > /tmp/vault_dynamic_user.txt
    echo "\${PASS}" > /tmp/vault_dynamic_pass.txt
else
    echo "[ERROR]   ❌ Failed to generate dynamic credentials"
    exit 1
fi
TEST_CREDS

if [ $? -eq 0 ]; then
    DYNAMIC_USER=$(ssh root@10.0.0.150 "cat /tmp/vault_dynamic_user.txt 2>/dev/null")
    DYNAMIC_PASS=$(ssh root@10.0.0.150 "cat /tmp/vault_dynamic_pass.txt 2>/dev/null")
    echo "[INFO]   ✅ Dynamic credentials retrieved"
    echo "[INFO]   ✅ Username: ${DYNAMIC_USER}"
else
    echo "[ERROR]   ❌ Failed to generate dynamic credentials"
    exit 1
fi

# Step 5: Test connection via LB
echo ""
echo "[INFO] Step 5: Testing connection via LB (10.0.0.10:3306)..."

# Ensure mysql client is installed
if ! command -v mysql &> /dev/null; then
    echo "[INFO]   Installing mysql client..."
    apt-get update && apt-get install -y mariadb-client
fi

mysql -h 10.0.0.10 -P3306 -u "${DYNAMIC_USER}" -p"${DYNAMIC_PASS}" -e "
USE erpnextdb;
CREATE TABLE IF NOT EXISTS vault_test_fix (id INT AUTO_INCREMENT PRIMARY KEY, v VARCHAR(255));
INSERT INTO vault_test_fix (v) VALUES ('VAULT_FIX_OK');
SELECT * FROM vault_test_fix;
" 2>&1 | tee /opt/keybuzz/logs/phase8/vault_mariadb_dynamic_test_fix.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "[INFO]   ✅ Connection test successful via LB"
    echo "[INFO]   ✅ Table created, data inserted, and selected"
else
    echo "[ERROR]   ❌ Connection test failed"
    echo "[ERROR]   Check /opt/keybuzz/logs/phase8/vault_mariadb_dynamic_test_fix.log for details"
    exit 1
fi

# Save vault_admin password for future reference
echo "${VAULT_ADMIN_PASS}" > /root/vault_admin_password.txt
chmod 600 /root/vault_admin_password.txt
echo "[INFO]   ✅ vault_admin password saved to /root/vault_admin_password.txt"

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ PH8-05 FIX Complete"
echo "[INFO] =========================================="
echo ""
echo "[INFO] Summary:"
echo "[INFO]   - vault_admin user created on MariaDB"
echo "[INFO]   - Vault configuration updated"
echo "[INFO]   - Dynamic credentials generation: ✅ SUCCESS"
echo "[INFO]   - Connection via LB: ✅ SUCCESS"
echo "[INFO]   - vault_admin password saved to /root/vault_admin_password.txt"
echo ""

