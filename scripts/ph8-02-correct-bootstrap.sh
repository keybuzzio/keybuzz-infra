#!/bin/bash
# PH8-02 FINAL - Correct Galera Bootstrap Sequence
# CRITICAL: Do NOT restart maria-02 after galera_new_cluster
set -e

cd /opt/keybuzz/keybuzz-infra

echo "[INFO] =========================================="
echo "[INFO] PH8-02 FINAL Galera Bootstrap Fix"
echo "[INFO] =========================================="
echo ""

# Step 1: Stop MariaDB on all 3 nodes
echo "[INFO] Step 1: Stopping MariaDB on all nodes..."
ssh root@10.0.0.170 "systemctl stop mariadb || true"
ssh root@10.0.0.171 "systemctl stop mariadb || true"
ssh root@10.0.0.172 "systemctl stop mariadb || true"

echo "[INFO]   ✅ All nodes stopped"
sleep 2

# Step 2: Bootstrap cluster ONLY on maria-02
echo ""
echo "[INFO] Step 2: Bootstrapping cluster on maria-02 (10.0.0.171)..."
echo "[INFO]   ⚠️  CRITICAL: Will NOT restart maria-02 after bootstrap"
ssh root@10.0.0.171 "galera_new_cluster"

echo "[INFO]   Waiting for bootstrap to complete..."
sleep 10

# Verify bootstrap
echo "[INFO]   Verifying bootstrap..."
CLUSTER_SIZE=$(ssh root@10.0.0.171 "mysql -u root -p'CHANGE_ME_LATER_VIA_VAULT' -e \"SHOW STATUS LIKE 'wsrep_cluster_size';\" 2>&1" | grep -E '^wsrep_cluster_size' | awk '{print $2}' || echo "0")

if [ "$CLUSTER_SIZE" = "1" ]; then
    echo "[INFO]   ✅ Bootstrap successful (cluster_size = ${CLUSTER_SIZE})"
else
    echo "[ERROR]   ❌ Bootstrap failed (cluster_size = ${CLUSTER_SIZE})"
    exit 1
fi

# Step 3: Start maria-01 and maria-03 (DO NOT restart maria-02)
echo ""
echo "[INFO] Step 3: Starting maria-01 and maria-03..."
echo "[INFO]   ⚠️  CRITICAL: NOT restarting maria-02"
ssh root@10.0.0.170 "systemctl start mariadb && echo '✅ maria-01 started'"
ssh root@10.0.0.172 "systemctl start mariadb && echo '✅ maria-03 started'"

echo "[INFO]   Waiting for nodes to join cluster..."
sleep 15

# Step 4: Verify cluster
echo ""
echo "[INFO] Step 4: Verifying cluster status..."
bash scripts/ph8-02-check-cluster-status.sh

echo ""
echo "[INFO] Step 5: Detailed cluster status..."
for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "[INFO]   === $ip ==="
    ssh root@$ip bash <<'STATUS_SCRIPT'
    if systemctl is-active --quiet mariadb; then
        mysql -u root -p'CHANGE_ME_LATER_VIA_VAULT' -e "SHOW STATUS LIKE 'wsrep_cluster_size'; SHOW STATUS LIKE 'wsrep_local_state_comment';" 2>&1 | grep -E '(wsrep_cluster_size|wsrep_local_state_comment|Value)' || echo "⚠️  Could not query status"
    else
        echo "❌ MariaDB is NOT running"
    fi
STATUS_SCRIPT
    echo ""
done

# Final verification
FINAL_SIZE=$(ssh root@10.0.0.171 "mysql -u root -p'CHANGE_ME_LATER_VIA_VAULT' -e \"SHOW STATUS LIKE 'wsrep_cluster_size';\" 2>&1" | grep -E '^wsrep_cluster_size' | awk '{print $2}' || echo "0")

if [ "$FINAL_SIZE" = "3" ]; then
    echo "[INFO] =========================================="
    echo "[INFO] ✅ Cluster bootstrap successful!"
    echo "[INFO] =========================================="
    echo "[INFO] wsrep_cluster_size = ${FINAL_SIZE}"
    echo "[INFO] Cluster is stable and ready"
    echo ""
else
    echo "[ERROR] =========================================="
    echo "[ERROR] ❌ Cluster bootstrap incomplete"
    echo "[ERROR] =========================================="
    echo "[ERROR] wsrep_cluster_size = ${FINAL_SIZE} (expected 3)"
    exit 1
fi

