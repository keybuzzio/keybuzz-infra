#!/bin/bash
# PH8-05 - Test Vault dynamic credentials (executed on vault-01)
set -e

export VAULT_ADDR="https://127.0.0.1:8200"
export VAULT_SKIP_VERIFY="true"
export VAULT_TOKEN=$(cat /root/.vault-token 2>/dev/null)

if [ -z "$VAULT_TOKEN" ]; then
    echo "[ERROR] VAULT_TOKEN not found"
    exit 1
fi

LOG_FILE="/opt/keybuzz/logs/phase8/ph8-05-test-vault-creds.log"
mkdir -p /opt/keybuzz/logs/phase8/
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[INFO] Testing Vault dynamic credentials generation..."

# Generate dynamic credentials
vault read mariadb/creds/erpnext-mariadb-role > /tmp/vault_erpnext_creds.txt 2>&1

if [ $? -eq 0 ]; then
    USER=$(grep "username" /tmp/vault_erpnext_creds.txt | awk '{print $2}')
    PASS=$(grep "password" /tmp/vault_erpnext_creds.txt | awk '{print $2}')
    echo "[INFO]   ✅ Dynamic credentials generated"
    echo "[INFO]   ✅ Username: ${USER}"
    echo "[INFO]   ✅ Password: ${PASS:0:10}..."
    echo "${USER}" > /tmp/vault_dynamic_user.txt
    echo "${PASS}" > /tmp/vault_dynamic_pass.txt
    
    # Test connection via LB
    echo "[INFO] Testing connection via LB (10.0.0.10:3306)..."
    
    # Ensure mysql client is installed
    if ! command -v mysql &> /dev/null; then
        echo "[INFO]   Installing mysql client..."
        apt-get update && apt-get install -y mariadb-client
    fi
    
    mysql -h 10.0.0.10 -P3306 -u "${USER}" -p"${PASS}" -e "
USE erpnextdb;
CREATE TABLE IF NOT EXISTS vault_test_final (id INT AUTO_INCREMENT PRIMARY KEY, v VARCHAR(255));
INSERT INTO vault_test_final (v) VALUES ('VAULT_FIX_OK');
SELECT * FROM vault_test_final;
" 2>&1 | tee /opt/keybuzz/logs/phase8/vault_mariadb_dynamic_test_final.log
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo "[INFO]   ✅ Connection test successful via LB"
        echo "[INFO]   ✅ Table created, data inserted, and selected"
        exit 0
    else
        echo "[ERROR]   ❌ Connection test failed"
        exit 1
    fi
else
    echo "[ERROR]   ❌ Failed to generate dynamic credentials"
    cat /tmp/vault_erpnext_creds.txt
    exit 1
fi

