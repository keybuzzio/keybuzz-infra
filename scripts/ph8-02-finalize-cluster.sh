#!/bin/bash
# PH8-02 - Finalize Galera cluster bootstrap
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== Finalizing Galera Cluster ==="
echo ""

# Check if maria-02 is running
echo "=== Checking maria-02 status ==="
if ssh root@10.0.0.171 "systemctl is-active --quiet mariadb"; then
    echo "✅ maria-02 is running"
else
    echo "⚠️  maria-02 is not running, starting..."
    ssh root@10.0.0.171 "systemctl start mariadb"
    sleep 5
fi

# Get cluster status from maria-02
echo ""
echo "=== Cluster status from maria-02 ==="
ssh root@10.0.0.171 bash <<'STATUS_SCRIPT'
    mysql -u root -p'CHANGE_ME_LATER_VIA_VAULT' -e "SHOW STATUS LIKE 'wsrep_cluster_size'; SHOW STATUS LIKE 'wsrep_local_state_comment';" 2>&1 | grep -E '(wsrep_cluster_size|wsrep_local_state_comment|Value)' || echo "⚠️  Could not query status"
STATUS_SCRIPT

# Start other nodes
echo ""
echo "=== Starting maria-01 and maria-03 ==="
ssh root@10.0.0.170 "systemctl start mariadb && echo '✅ maria-01 started'"
ssh root@10.0.0.172 "systemctl start mariadb && echo '✅ maria-03 started'"

echo ""
echo "=== Waiting for cluster to stabilize ==="
sleep 15

echo ""
echo "=== Final cluster status ==="
bash scripts/ph8-02-check-cluster-status.sh

echo ""
echo "✅ Cluster finalization complete!"

