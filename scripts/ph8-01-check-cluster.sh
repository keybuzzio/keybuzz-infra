#!/bin/bash
# Check MariaDB Galera Cluster Status
set -e

ROOT_PASSWORD='CHANGE_ME_LATER_VIA_VAULT'

echo "=== Checking MariaDB Galera Cluster ==="
echo ""

for host in 10.0.0.171 10.0.0.172; do
    echo "Checking $host..."
    
    # Check if MariaDB is running
    if ssh root@$host "systemctl is-active --quiet mariadb"; then
        echo "  ✅ MariaDB is running"
        
        # Get cluster size
        CLUSTER_SIZE=$(ssh root@$host "mysql -u root -p'${ROOT_PASSWORD}' -e \"SHOW STATUS LIKE 'wsrep_cluster_size';\" 2>&1" | grep -v Warning | tail -1 | awk '{print $2}' || echo "0")
        echo "  Cluster size: $CLUSTER_SIZE"
        
        # Get node status
        NODE_STATUS=$(ssh root@$host "mysql -u root -p'${ROOT_PASSWORD}' -e \"SHOW STATUS LIKE 'wsrep_local_state_comment';\" 2>&1" | grep -v Warning | tail -1 | awk '{print $2}' || echo "UNKNOWN")
        echo "  Node status: $NODE_STATUS"
        
        # Get cluster UUID
        CLUSTER_UUID=$(ssh root@$host "mysql -u root -p'${ROOT_PASSWORD}' -e \"SHOW STATUS LIKE 'wsrep_cluster_state_uuid';\" 2>&1" | grep -v Warning | tail -1 | awk '{print $2}' || echo "UNKNOWN")
        echo "  Cluster UUID: $CLUSTER_UUID"
    else
        echo "  ❌ MariaDB is NOT running"
    fi
    echo ""
done

echo "=== Check completed ==="

