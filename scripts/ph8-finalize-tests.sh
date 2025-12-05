#!/bin/bash
# PH8 - Finalize tests and document results
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase8/ph8-finalize-tests.log"
mkdir -p /opt/keybuzz/logs/phase8/
exec > >(tee -a "$LOG_FILE") 2>&1

MARIADB_ROOT_PASSWORD="${MARIADB_ROOT_PASSWORD:-CHANGE_ME_LATER_VIA_VAULT}"

echo "[INFO] =========================================="
echo "[INFO] PH8 - Finalize Tests and Document"
echo "[INFO] =========================================="
echo ""

# Step 1: Get or reset ERPNext password
echo "[INFO] Step 1: Checking ERPNext user..."
USER_EXISTS=$(ssh root@10.0.0.171 "mysql -u root -p\"$MARIADB_ROOT_PASSWORD\" -e \"SELECT COUNT(*) FROM mysql.user WHERE User='erpnext';\" 2>&1" | tail -1 | awk '{print $1}' || echo "0")

if [ "$USER_EXISTS" = "1" ]; then
    echo "[INFO]   ERPNext user exists, resetting password for testing..."
    NEW_ERP_PASS="erpnext_test_$(openssl rand -hex 8)"
    ssh root@10.0.0.171 "mysql -u root -p\"$MARIADB_ROOT_PASSWORD\" <<SQL
ALTER USER 'erpnext'@'%' IDENTIFIED BY '${NEW_ERP_PASS}';
FLUSH PRIVILEGES;
SQL
" 2>&1 | grep -v "Warning" || true
    
    # Update ProxySQL
    for proxysql_ip in 10.0.0.173 10.0.0.174; do
        ssh root@$proxysql_ip "mysql -h 127.0.0.1 -P6032 -u admin -padmin <<SQL
UPDATE mysql_users SET password='${NEW_ERP_PASS}' WHERE username='erpnext';
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
SQL
" 2>&1 | grep -v "Warning" || true
    done
    
    export ERP_PASS="$NEW_ERP_PASS"
    echo "[INFO]   ✅ ERPNext password reset"
else
    echo "[WARN]   ERPNext user does not exist, creating..."
    NEW_ERP_PASS="erpnext_test_$(openssl rand -hex 8)"
    ssh root@10.0.0.171 "mysql -u root -p\"$MARIADB_ROOT_PASSWORD\" <<SQL
CREATE USER IF NOT EXISTS 'erpnext'@'%' IDENTIFIED BY '${NEW_ERP_PASS}';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EXECUTE, REFERENCES, CREATE TEMPORARY TABLES, LOCK TABLES ON erpnextdb.* TO 'erpnext'@'%';
FLUSH PRIVILEGES;
SQL
" 2>&1 | grep -v "Warning" || true
    
    # Add to ProxySQL
    for proxysql_ip in 10.0.0.173 10.0.0.174; do
        ssh root@$proxysql_ip "mysql -h 127.0.0.1 -P6032 -u admin -padmin <<SQL
INSERT INTO mysql_users (username, password, default_hostgroup, active) VALUES ('erpnext', '${NEW_ERP_PASS}', 0, 1) ON DUPLICATE KEY UPDATE password='${NEW_ERP_PASS}';
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
SQL
" 2>&1 | grep -v "Warning" || true
    done
    
    export ERP_PASS="$NEW_ERP_PASS"
    echo "[INFO]   ✅ ERPNext user created"
fi

echo ""

# Step 2: Test ERPNext user via LB
echo "[INFO] Step 2: Testing ERPNext user via LB..."
if [ -f scripts/mariadb_erpnext_test.sh ]; then
    chmod +x scripts/mariadb_erpnext_test.sh
    export ERP_PASS
    if bash scripts/mariadb_erpnext_test.sh 2>&1 | tee /opt/keybuzz/logs/phase8/mariadb_erpnext_test_final.log; then
        echo "[INFO]   ✅ ERPNext static user test passed"
        ERP_TEST_OK=true
    else
        echo "[ERROR]   ❌ ERPNext static user test failed"
        ERP_TEST_OK=false
    fi
fi

echo ""

# Step 3: Test Vault dynamic credentials
echo "[INFO] Step 3: Testing Vault dynamic credentials..."
if [ -f scripts/ph8-05-test-vault-creds.sh ]; then
    chmod +x scripts/ph8-05-test-vault-creds.sh
    scp scripts/ph8-05-test-vault-creds.sh root@10.0.0.150:/tmp/ >/dev/null 2>&1
    if ssh root@10.0.0.150 "bash /tmp/ph8-05-test-vault-creds.sh" 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-05-test-vault-creds-final.log; then
        echo "[INFO]   ✅ Vault dynamic credentials test passed"
        VAULT_TEST_OK=true
    else
        echo "[ERROR]   ❌ Vault dynamic credentials test failed"
        VAULT_TEST_OK=false
    fi
fi

echo ""
echo "[INFO] =========================================="
echo "[INFO] PH8 Final Test Summary"
echo "[INFO] =========================================="
echo "[INFO] ERPNext Static User: $([ \"$ERP_TEST_OK\" = true ] && echo '✅ OK' || echo '❌ FAILED')"
echo "[INFO] Vault Dynamic Creds: $([ \"$VAULT_TEST_OK\" = true ] && echo '✅ OK' || echo '❌ FAILED')"
echo "[INFO] =========================================="
echo ""

