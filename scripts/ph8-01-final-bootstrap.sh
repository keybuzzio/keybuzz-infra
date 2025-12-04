#!/bin/bash
# PH8-01 Final Bootstrap Script - Execute from install-v3
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== PH8-01 Final MariaDB Galera Bootstrap ==="
echo ""

# Step 1: Verify SSH connectivity
echo "Step 1: Verifying SSH connectivity..."
for host in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "Testing SSH to $host..."
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$host "echo OK" 2>&1; then
        echo "  ✅ $host is reachable"
    else
        echo "  ❌ SSH FAILED for $host"
        exit 1
    fi
done
echo ""

# Step 2: Bootstrap maria-02
echo "Step 2: Bootstrapping maria-02 (10.0.0.171)..."
chmod +x scripts/mariadb_bootstrap_direct.sh
scp scripts/mariadb_bootstrap_direct.sh root@10.0.0.171:/root/
ssh root@10.0.0.171 "chmod +x /root/mariadb_bootstrap_direct.sh && bash /root/mariadb_bootstrap_direct.sh 2>&1" | tee /opt/keybuzz/logs/phase8/mariadb-bootstrap-maria02.log

# Verify bootstrap
echo "Verifying bootstrap on maria-02..."
CLUSTER_SIZE=$(ssh root@10.0.0.171 "mysql -u root -p'CHANGE_ME_LATER_VIA_VAULT' -e \"SHOW STATUS LIKE 'wsrep_cluster_size';\" 2>&1 | grep -v Warning | tail -1 | awk '{print \$2}'" || echo "0")
if [ "$CLUSTER_SIZE" -ge "1" ]; then
    echo "  ✅ Bootstrap successful, cluster_size=$CLUSTER_SIZE"
else
    echo "  ❌ Bootstrap failed, cluster_size=$CLUSTER_SIZE"
    exit 1
fi
echo ""

# Step 3: Join maria-01
echo "Step 3: Joining maria-01 (10.0.0.170) to cluster..."
chmod +x scripts/mariadb_bootstrap_cluster.sh
bash scripts/mariadb_bootstrap_cluster.sh 10.0.0.170 false 2>&1 | tee /opt/keybuzz/logs/phase8/mariadb-join-maria01.log

# Step 4: Join maria-03
echo "Step 4: Joining maria-03 (10.0.0.172) to cluster..."
bash scripts/mariadb_bootstrap_cluster.sh 10.0.0.172 false 2>&1 | tee /opt/keybuzz/logs/phase8/mariadb-join-maria03.log

# Step 5: Verify cluster
echo "Step 5: Verifying cluster status..."
sleep 10

for host in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "Checking $host..."
    CLUSTER_SIZE=$(ssh root@$host "mysql -u root -p'CHANGE_ME_LATER_VIA_VAULT' -e \"SHOW STATUS LIKE 'wsrep_cluster_size';\" 2>&1 | grep -v Warning | tail -1 | awk '{print \$2}'" || echo "0")
    NODE_STATUS=$(ssh root@$host "mysql -u root -p'CHANGE_ME_LATER_VIA_VAULT' -e \"SHOW STATUS LIKE 'wsrep_local_state_comment';\" 2>&1 | grep -v Warning | tail -1 | awk '{print \$2}'" || echo "UNKNOWN")
    echo "  Cluster size: $CLUSTER_SIZE, Status: $NODE_STATUS"
done
echo ""

echo "=== Bootstrap completed ==="

