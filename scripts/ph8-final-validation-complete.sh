#!/bin/bash
# PH8-FINAL-VALIDATION - Complete MariaDB Galera HA + ProxySQL + HAProxy + LB + Vault validation
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase8/ph8-final-validation-complete.log"
mkdir -p /opt/keybuzz/logs/phase8/
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[INFO] =========================================="
echo "[INFO] PH8-FINAL-VALIDATION COMPLETE"
echo "[INFO] =========================================="
echo ""

# Get MariaDB root password
echo "[INFO] Step 1: Retrieving MariaDB root password..."
MARIADB_ROOT_PASSWORD=$(python3 << 'PYEOF'
import yaml
with open('ansible/group_vars/mariadb.yml') as f:
    d = yaml.safe_load(f)
    print(d.get('mariadb_root_password', ''))
PYEOF
)

# Try Vault if placeholder
if [ -z "$MARIADB_ROOT_PASSWORD" ] || [ "$MARIADB_ROOT_PASSWORD" = "CHANGE_ME_LATER_VIA_VAULT" ]; then
    echo "[INFO] Password is placeholder, using CHANGE_ME_LATER_VIA_VAULT"
    MARIADB_ROOT_PASSWORD="CHANGE_ME_LATER_VIA_VAULT"
fi

export MARIADB_ROOT_PASSWORD
export MARIADB_LB_HOST="10.0.0.10"
export MARIADB_LB_PORT="3306"

echo "[INFO]   Using password: ${MARIADB_ROOT_PASSWORD:0:10}..."
echo ""

# Step 2: Verify Galera cluster
echo "[INFO] Step 2: Verifying Galera cluster status..."
GALERA_RESULTS="/tmp/galera_status.txt"
> "$GALERA_RESULTS"

for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "[INFO]   Checking node $ip..."
    ssh root@$ip "mysql -u root -p\"$MARIADB_ROOT_PASSWORD\" -e \"SHOW STATUS LIKE 'wsrep_cluster_size'; SHOW STATUS LIKE 'wsrep_local_state_comment';\" 2>&1" | grep -E "(wsrep_cluster_size|wsrep_local_state_comment)" >> "$GALERA_RESULTS" || echo "ERROR: $ip" >> "$GALERA_RESULTS"
done

cat "$GALERA_RESULTS"
CLUSTER_SIZE_COUNT=$(grep -c "wsrep_cluster_size.*3" "$GALERA_RESULTS" || echo "0")
SYNCED_COUNT=$(grep -c "wsrep_local_state_comment.*Synced" "$GALERA_RESULTS" || echo "0")

if [ "$CLUSTER_SIZE_COUNT" -eq 3 ] && [ "$SYNCED_COUNT" -eq 3 ]; then
    echo "[INFO]   ✅ Galera cluster OK: 3 nodes, all Synced"
    GALERA_OK=true
else
    echo "[WARN]   ⚠️  Galera cluster issues detected"
    GALERA_OK=false
fi

echo ""

# Step 3: Verify ProxySQL
echo "[INFO] Step 3: Verifying ProxySQL..."
PROXYSQL_OK=true
for ip in 10.0.0.173 10.0.0.174; do
    echo "[INFO]   Checking ProxySQL on $ip..."
    if ssh root@$ip "systemctl is-active proxysql >/dev/null 2>&1"; then
        echo "[INFO]     ✅ ProxySQL service active"
        SERVERS=$(ssh root@$ip "mysql -h 127.0.0.1 -P6032 -u admin -padmin -e 'SELECT COUNT(*) FROM runtime_mysql_servers;' 2>&1" | tail -1 | awk '{print $1}' || echo "0")
        echo "[INFO]     Runtime MySQL servers: $SERVERS"
        if [ "$SERVERS" -ge 3 ]; then
            echo "[INFO]     ✅ ProxySQL configured correctly"
            ssh root@$ip "mysql -h 127.0.0.1 -P6032 -u admin -padmin -e 'SELECT hostname, port, status FROM runtime_mysql_servers;' 2>&1" | grep -v "Warning" || true
        else
            echo "[WARN]     ⚠️  ProxySQL has less than 3 servers"
            PROXYSQL_OK=false
        fi
    else
        echo "[ERROR]     ❌ ProxySQL service not active"
        PROXYSQL_OK=false
    fi
done

echo ""

# Step 4: Verify HAProxy
echo "[INFO] Step 4: Verifying HAProxy MariaDB..."
HAPROXY_OK=true
for ip in 10.0.0.11 10.0.0.12; do
    echo "[INFO]   Checking HAProxy on $ip..."
    PORT_CHECK=$(ssh root@$ip "ss -ntlp 2>/dev/null | grep 3306 || netstat -plant 2>/dev/null | grep 3306 || echo 'NOT_FOUND'")
    if echo "$PORT_CHECK" | grep -q "3306"; then
        echo "[INFO]     ✅ Port 3306 listening"
        echo "[INFO]     $PORT_CHECK"
    else
        echo "[ERROR]     ❌ Port 3306 not listening"
        HAPROXY_OK=false
    fi
done

echo ""

# Step 5: Verify LB Hetzner
echo "[INFO] Step 5: Verifying Hetzner Load Balancer..."
LB_CHECK=$(hcloud load-balancer describe lb-haproxy 2>&1 | grep -c "3306" || echo "0")
if [ "$LB_CHECK" -gt 0 ]; then
    echo "[INFO]   ✅ LB service 3306 configured"
    hcloud load-balancer describe lb-haproxy 2>&1 | grep -A 5 "3306" || true
else
    echo "[WARN]   ⚠️  LB service 3306 not found"
    if [ -f scripts/ph8-03-configure-lb-mariadb.sh ]; then
        echo "[INFO]   Attempting to configure LB..."
        bash scripts/ph8-03-configure-lb-mariadb.sh || true
    fi
fi

echo ""

# Step 6: Test ERPNext static user via LB
echo "[INFO] Step 6: Testing ERPNext static user via LB..."
ERP_PASS=""
# Try to get from group_vars
ERP_PASS=$(python3 << 'PYEOF'
import yaml
try:
    with open('ansible/group_vars/mariadb.yml') as f:
        d = yaml.safe_load(f)
        print(d.get('erpnext_password', ''))
except:
    print('')
PYEOF
)

# If not found, check if user exists and get password from MariaDB
if [ -z "$ERP_PASS" ]; then
    echo "[INFO]   ERPNext password not in group_vars, checking if user exists..."
    USER_EXISTS=$(ssh root@10.0.0.171 "mysql -u root -p\"$MARIADB_ROOT_PASSWORD\" -e \"SELECT COUNT(*) FROM mysql.user WHERE User='erpnext';\" 2>&1" | tail -1 | awk '{print $1}' || echo "0")
    if [ "$USER_EXISTS" = "1" ]; then
        echo "[WARN]   ERPNext user exists but password unknown, skipping static test"
        echo "[INFO]   You may need to set erpnext_password in group_vars/mariadb.yml"
    else
        echo "[WARN]   ERPNext user does not exist, skipping static test"
    fi
else
    export ERP_PASS
    if [ -f scripts/mariadb_erpnext_test.sh ]; then
        chmod +x scripts/mariadb_erpnext_test.sh
        echo "[INFO]   Running ERPNext static user test..."
        if bash scripts/mariadb_erpnext_test.sh 2>&1 | tee /opt/keybuzz/logs/phase8/mariadb_erpnext_test.log; then
            echo "[INFO]   ✅ ERPNext static user test passed"
        else
            echo "[ERROR]   ❌ ERPNext static user test failed"
        fi
    fi
fi

echo ""

# Step 7: Test Vault dynamic credentials
echo "[INFO] Step 7: Testing Vault dynamic credentials..."
if [ -f scripts/ph8-05-test-vault-creds.sh ]; then
    chmod +x scripts/ph8-05-test-vault-creds.sh
    echo "[INFO]   Copying test script to vault-01..."
    scp scripts/ph8-05-test-vault-creds.sh root@10.0.0.150:/tmp/ >/dev/null 2>&1
    echo "[INFO]   Executing Vault dynamic credentials test..."
    if ssh root@10.0.0.150 "bash /tmp/ph8-05-test-vault-creds.sh" 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-05-test-vault-creds.log; then
        echo "[INFO]   ✅ Vault dynamic credentials test passed"
    else
        echo "[ERROR]   ❌ Vault dynamic credentials test failed"
        echo "[INFO]   Checking Vault configuration..."
        ssh root@10.0.0.150 "export VAULT_ADDR='https://127.0.0.1:8200' && export VAULT_SKIP_VERIFY='true' && export VAULT_TOKEN=\$(cat /root/.vault-token 2>/dev/null) && vault read mariadb/config/erpnext-mariadb 2>&1 | head -20" || true
    fi
else
    echo "[WARN]   Script ph8-05-test-vault-creds.sh not found"
fi

echo ""
echo "[INFO] =========================================="
echo "[INFO] PH8-FINAL-VALIDATION Summary"
echo "[INFO] =========================================="
echo "[INFO] Galera Cluster: $([ \"$GALERA_OK\" = true ] && echo '✅ OK' || echo '❌ ISSUES')"
echo "[INFO] ProxySQL: $([ \"$PROXYSQL_OK\" = true ] && echo '✅ OK' || echo '❌ ISSUES')"
echo "[INFO] HAProxy: $([ \"$HAPROXY_OK\" = true ] && echo '✅ OK' || echo '❌ ISSUES')"
echo "[INFO] Load Balancer: $([ \"$LB_CHECK\" -gt 0 ] && echo '✅ OK' || echo '❌ ISSUES')"
echo "[INFO] =========================================="
echo ""

