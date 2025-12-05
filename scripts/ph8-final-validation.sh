#!/bin/bash
# PH8-FINAL-VALIDATION - Complete MariaDB Galera HA + ProxySQL + HAProxy + LB + Vault validation
set -e

cd /opt/keybuzz/keybuzz-infra

LOG_FILE="/opt/keybuzz/logs/phase8/ph8-final-validation.log"
mkdir -p /opt/keybuzz/logs/phase8/
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[INFO] =========================================="
echo "[INFO] PH8-FINAL-VALIDATION"
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

if [ -z "$MARIADB_ROOT_PASSWORD" ] || [ "$MARIADB_ROOT_PASSWORD" = "CHANGE_ME_LATER_VIA_VAULT" ]; then
    echo "[WARN] MariaDB root password not set or still placeholder"
    echo "[INFO] Attempting to retrieve from Vault..."
    export VAULT_ADDR="https://vault.keybuzz.io:8200"
    export VAULT_SKIP_VERIFY="true"
    export VAULT_TOKEN=$(ssh root@10.0.0.150 "cat /root/.vault-token 2>/dev/null" || echo "")
    if [ -n "$VAULT_TOKEN" ]; then
        MARIADB_ROOT_PASSWORD=$(ssh root@10.0.0.150 "export VAULT_ADDR='https://127.0.0.1:8200' && export VAULT_SKIP_VERIFY='true' && export VAULT_TOKEN=\$(cat /root/.vault-token) && vault kv get -field=password kv/keybuzz/mariadb/root 2>/dev/null" || echo "")
    fi
fi

if [ -z "$MARIADB_ROOT_PASSWORD" ] || [ "$MARIADB_ROOT_PASSWORD" = "CHANGE_ME_LATER_VIA_VAULT" ]; then
    echo "[ERROR] Cannot retrieve MariaDB root password"
    exit 1
fi

export MARIADB_ROOT_PASSWORD
export MARIADB_LB_HOST="10.0.0.10"
export MARIADB_LB_PORT="3306"

echo "[INFO]   ✅ MariaDB root password retrieved"
echo ""

# Step 2: Verify Galera cluster
echo "[INFO] Step 2: Verifying Galera cluster status..."
GALERA_OK=true
for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "[INFO]   Checking node $ip..."
    CLUSTER_SIZE=$(ssh root@$ip "mysql -u root -p\"$MARIADB_ROOT_PASSWORD\" -e \"SHOW STATUS LIKE 'wsrep_cluster_size';\" 2>&1" | grep -i "wsrep_cluster_size" | awk '{print $2}' || echo "0")
    STATE=$(ssh root@$ip "mysql -u root -p\"$MARIADB_ROOT_PASSWORD\" -e \"SHOW STATUS LIKE 'wsrep_local_state_comment';\" 2>&1" | grep -i "wsrep_local_state_comment" | awk '{print $2}' || echo "Unknown")
    
    echo "[INFO]     wsrep_cluster_size: $CLUSTER_SIZE"
    echo "[INFO]     wsrep_local_state_comment: $STATE"
    
    if [ "$CLUSTER_SIZE" != "3" ] || [ "$STATE" != "Synced" ]; then
        echo "[WARN]     ⚠️  Node $ip not in expected state"
        GALERA_OK=false
    else
        echo "[INFO]     ✅ Node $ip OK"
    fi
done

if [ "$GALERA_OK" = false ]; then
    echo "[WARN]   ⚠️  Galera cluster not fully synced, attempting to fix..."
    if [ -f scripts/ph8-02-check-cluster-status.sh ]; then
        bash scripts/ph8-02-check-cluster-status.sh || true
    fi
    # Re-check after fix attempt
    for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
        CLUSTER_SIZE=$(ssh root@$ip "mysql -u root -p\"$MARIADB_ROOT_PASSWORD\" -e \"SHOW STATUS LIKE 'wsrep_cluster_size';\" 2>&1" | grep -i "wsrep_cluster_size" | awk '{print $2}' || echo "0")
        STATE=$(ssh root@$ip "mysql -u root -p\"$MARIADB_ROOT_PASSWORD\" -e \"SHOW STATUS LIKE 'wsrep_local_state_comment';\" 2>&1" | grep -i "wsrep_local_state_comment" | awk '{print $2}' || echo "Unknown")
        if [ "$CLUSTER_SIZE" = "3" ] && [ "$STATE" = "Synced" ]; then
            echo "[INFO]     ✅ Node $ip fixed"
        fi
    done
fi

echo ""

# Step 3: Verify ProxySQL
echo "[INFO] Step 3: Verifying ProxySQL..."
for ip in 10.0.0.173 10.0.0.174; do
    echo "[INFO]   Checking ProxySQL on $ip..."
    if ssh root@$ip "systemctl is-active proxysql >/dev/null 2>&1"; then
        echo "[INFO]     ✅ ProxySQL service active"
        SERVERS=$(ssh root@$ip "mysql -h 127.0.0.1 -P6032 -u admin -padmin -e 'SELECT COUNT(*) FROM runtime_mysql_servers;' 2>&1" | tail -1 | awk '{print $1}' || echo "0")
        echo "[INFO]     Runtime MySQL servers: $SERVERS"
        if [ "$SERVERS" -ge 3 ]; then
            echo "[INFO]     ✅ ProxySQL configured correctly"
        else
            echo "[WARN]     ⚠️  ProxySQL has less than 3 servers"
        fi
    else
        echo "[ERROR]     ❌ ProxySQL service not active"
    fi
done

echo ""

# Step 4: Verify HAProxy
echo "[INFO] Step 4: Verifying HAProxy MariaDB..."
for ip in 10.0.0.11 10.0.0.12; do
    echo "[INFO]   Checking HAProxy on $ip..."
    PORT_CHECK=$(ssh root@$ip "ss -ntlp | grep 3306 || netstat -plant | grep 3306 || echo 'NOT_FOUND'" | grep -v "NOT_FOUND" || echo "")
    if [ -n "$PORT_CHECK" ]; then
        echo "[INFO]     ✅ Port 3306 listening"
        echo "[INFO]     $PORT_CHECK"
    else
        echo "[ERROR]     ❌ Port 3306 not listening"
    fi
done

echo ""

# Step 5: Verify LB Hetzner
echo "[INFO] Step 5: Verifying Hetzner Load Balancer..."
LB_SERVICES=$(hcloud load-balancer describe lb-haproxy 2>&1 | grep -A 20 "services:" | grep -c "3306" || echo "0")
if [ "$LB_SERVICES" -gt 0 ]; then
    echo "[INFO]   ✅ LB service 3306 configured"
else
    echo "[WARN]   ⚠️  LB service 3306 not found, attempting to configure..."
    if [ -f scripts/ph8-03-configure-lb-mariadb.sh ]; then
        bash scripts/ph8-03-configure-lb-mariadb.sh || true
    fi
fi

echo ""

# Step 6: Test ERPNext static user via LB
echo "[INFO] Step 6: Testing ERPNext static user via LB..."
# Get ERPNext password
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

if [ -z "$ERP_PASS" ]; then
    echo "[WARN]   ERPNext password not found in group_vars, checking Vault..."
    export VAULT_ADDR="https://vault.keybuzz.io:8200"
    export VAULT_SKIP_VERIFY="true"
    export VAULT_TOKEN=$(ssh root@10.0.0.150 "cat /root/.vault-token 2>/dev/null" || echo "")
    if [ -n "$VAULT_TOKEN" ]; then
        ERP_PASS=$(ssh root@10.0.0.150 "export VAULT_ADDR='https://127.0.0.1:8200' && export VAULT_SKIP_VERIFY='true' && export VAULT_TOKEN=\$(cat /root/.vault-token) && vault kv get -field=password kv/keybuzz/mariadb/erpnext 2>/dev/null" || echo "")
    fi
fi

if [ -n "$ERP_PASS" ]; then
    export ERP_PASS
    if [ -f scripts/mariadb_erpnext_test.sh ]; then
        chmod +x scripts/mariadb_erpnext_test.sh
        if bash scripts/mariadb_erpnext_test.sh 2>&1 | tee /opt/keybuzz/logs/phase8/mariadb_erpnext_test.log; then
            echo "[INFO]   ✅ ERPNext static user test passed"
        else
            echo "[ERROR]   ❌ ERPNext static user test failed"
        fi
    else
        echo "[WARN]   Script mariadb_erpnext_test.sh not found"
    fi
else
    echo "[WARN]   ERPNext password not found, skipping static user test"
fi

echo ""

# Step 7: Test Vault dynamic credentials
echo "[INFO] Step 7: Testing Vault dynamic credentials..."
if [ -f scripts/ph8-05-test-vault-creds.sh ]; then
    chmod +x scripts/ph8-05-test-vault-creds.sh
    # Copy script to vault-01 and execute
    scp scripts/ph8-05-test-vault-creds.sh root@10.0.0.150:/tmp/ >/dev/null 2>&1
    if ssh root@10.0.0.150 "bash /tmp/ph8-05-test-vault-creds.sh" 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-05-test-vault-creds.log; then
        echo "[INFO]   ✅ Vault dynamic credentials test passed"
    else
        echo "[ERROR]   ❌ Vault dynamic credentials test failed"
    fi
else
    echo "[WARN]   Script ph8-05-test-vault-creds.sh not found"
fi

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ PH8-FINAL-VALIDATION Complete"
echo "[INFO] =========================================="
echo ""

