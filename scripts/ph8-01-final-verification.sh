#!/bin/bash
# PH8-01 Final Verification and Deployment
set -e

cd /opt/keybuzz/keybuzz-infra

ROOT_PASSWORD='CHANGE_ME_LATER_VIA_VAULT'

echo "=== PH8-01 Final Verification ==="
echo ""

# Step 1: Verify cluster
echo "Step 1: Verifying MariaDB Galera cluster..."
bash scripts/mariadb_ha_checks.sh 2>&1 | tee /opt/keybuzz/logs/phase8/mariadb-ha-final-checks.log

echo ""
echo "Detailed cluster status:"
for host in 10.0.0.171 10.0.0.172; do
    echo "Checking $host..."
    if ssh root@$host "systemctl is-active --quiet mariadb"; then
        CLUSTER_SIZE=$(ssh root@$host "mysql -u root -p'${ROOT_PASSWORD}' -e \"SHOW STATUS LIKE 'wsrep_cluster_size';\" 2>&1" | grep -v Warning | tail -1 | awk '{print $2}' || echo "0")
        NODE_STATUS=$(ssh root@$host "mysql -u root -p'${ROOT_PASSWORD}' -e \"SHOW STATUS LIKE 'wsrep_local_state_comment';\" 2>&1" | grep -v Warning | tail -1 | awk '{print $2}' || echo "UNKNOWN")
        CLUSTER_UUID=$(ssh root@$host "mysql -u root -p'${ROOT_PASSWORD}' -e \"SHOW STATUS LIKE 'wsrep_cluster_state_uuid';\" 2>&1" | grep -v Warning | tail -1 | awk '{print $2}' || echo "UNKNOWN")
        echo "  ✅ $host: cluster_size=$CLUSTER_SIZE, status=$NODE_STATUS, uuid=$CLUSTER_UUID"
    else
        echo "  ❌ $host: MariaDB not running"
    fi
done

echo ""
echo "Step 2: Deploying ProxySQL..."
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/proxysql_v3.yml 2>&1 | tee /opt/keybuzz/logs/phase8/proxysql-deploy-final.log

echo ""
echo "Step 3: Verifying ProxySQL..."
for host in 10.0.0.173 10.0.0.174; do
    echo "Checking $host..."
    if ssh root@$host "systemctl is-active --quiet proxysql"; then
        echo "  ✅ ProxySQL is running"
        BACKEND_COUNT=$(ssh root@$host "mysql -h127.0.0.1 -P6032 -uadmin -padmin -e \"SELECT COUNT(*) FROM mysql_servers WHERE status='ONLINE';\" 2>&1" | grep -v Warning | tail -1 || echo "0")
        echo "  Backend servers ONLINE: $BACKEND_COUNT"
    else
        echo "  ❌ ProxySQL not running"
    fi
done

echo ""
echo "Step 4: Running end-to-end tests..."
chmod +x scripts/mariadb_ha_end_to_end.sh
bash scripts/mariadb_ha_end_to_end.sh 2>&1 | tee /opt/keybuzz/logs/phase8/mariadb-ha-e2e-final.log

echo ""
echo "=== Verification completed ==="

