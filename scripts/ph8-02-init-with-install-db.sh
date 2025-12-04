#!/bin/bash
# PH8-02 INIT FIX - Initialize MariaDB with mariadb-install-db and bootstrap Galera
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== PH8-02 INIT FIX - MariaDB Galera Initialization ==="
echo ""

# Step 1: Disable Galera on all nodes
echo "=== Step 1: Disabling Galera on all nodes ==="
for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "Disabling Galera on $ip..."
    ssh root@$ip bash <<'DISABLE_SCRIPT'
    systemctl stop mariadb || true
    if [ -f /etc/mysql/conf.d/galera.cnf ]; then
        mv /etc/mysql/conf.d/galera.cnf /etc/mysql/conf.d/galera.cnf.disabled
        echo "  ✅ Galera disabled"
    else
        echo "  ⚠️  galera.cnf not found (may already be disabled)"
    fi
DISABLE_SCRIPT
done

echo ""
echo "=== Step 2: Initializing MariaDB with mariadb-install-db ==="
for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "Initializing MariaDB on $ip..."
    ssh root@$ip bash <<'INIT_SCRIPT'
    set -e
    
    # Clean data directory
    rm -rf /data/mariadb/data/*
    
    # Initialize with mariadb-install-db
    mariadb-install-db --user=mysql --datadir=/data/mariadb/data --skip-test-db
    
    # Fix permissions
    chown -R mysql:mysql /data/mariadb/data
    
    # Verify mysql directory exists
    if [ -d /data/mariadb/data/mysql ]; then
        echo "  ✅ mysql directory created"
        ls -l /data/mariadb/data | grep mysql
    else
        echo "  ❌ mysql directory missing - initialization failed"
        exit 1
    fi
INIT_SCRIPT
done

echo ""
echo "=== Step 3: Re-enabling Galera ==="
for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "Re-enabling Galera on $ip..."
    ssh root@$ip bash <<'REENABLE_SCRIPT'
    if [ -f /etc/mysql/conf.d/galera.cnf.disabled ]; then
        mv /etc/mysql/conf.d/galera.cnf.disabled /etc/mysql/conf.d/galera.cnf
        echo "  ✅ Galera re-enabled"
    else
        echo "  ⚠️  galera.cnf.disabled not found"
    fi
REENABLE_SCRIPT
done

echo ""
echo "=== Step 4: Bootstrap cluster on maria-02 (10.0.0.171) ==="
ssh root@10.0.0.171 bash <<'BOOTSTRAP_SCRIPT'
    # Set bootstrap mode (gcomm://)
    sed -i 's|wsrep_cluster_address = .*|wsrep_cluster_address = gcomm://|g' /etc/mysql/conf.d/galera.cnf
    
    # Bootstrap cluster
    galera_new_cluster
    
    # Wait for startup
    sleep 10
    
    # Check status
    systemctl status mariadb --no-pager | head -10
    
    # Verify cluster size
    mysql -u root -p'CHANGE_ME_LATER_VIA_VAULT' -e "SHOW STATUS LIKE 'wsrep_cluster_size';" 2>&1 | grep -E '(wsrep_cluster_size|Value)'
BOOTSTRAP_SCRIPT

echo ""
echo "=== Step 5: Restore cluster address on maria-02 ==="
ssh root@10.0.0.171 "sed -i 's|wsrep_cluster_address = gcomm://|wsrep_cluster_address = gcomm://10.0.0.170,10.0.0.171,10.0.0.172|g' /etc/mysql/conf.d/galera.cnf"
ssh root@10.0.0.171 "systemctl restart mariadb"
sleep 5

echo ""
echo "=== Step 6: Starting maria-01 and maria-03 ==="
ssh root@10.0.0.170 "systemctl start mariadb && echo '✅ maria-01 started'"
ssh root@10.0.0.172 "systemctl start mariadb && echo '✅ maria-03 started'"

echo ""
echo "=== Waiting for cluster to stabilize ==="
sleep 15

echo ""
echo "=== Step 7: Verifying cluster ==="
bash scripts/ph8-02-check-cluster-status.sh

echo ""
echo "=== Step 8: Final cluster status ==="
for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "=== $ip ==="
    ssh root@$ip bash <<'STATUS_SCRIPT'
    if systemctl is-active --quiet mariadb; then
        mysql -u root -p'CHANGE_ME_LATER_VIA_VAULT' -e "SHOW STATUS LIKE 'wsrep_cluster_size'; SHOW STATUS LIKE 'wsrep_local_state_comment';" 2>&1 | grep -E '(wsrep_cluster_size|wsrep_local_state_comment|Value)' || echo "⚠️  Could not query status"
    else
        echo "❌ MariaDB is NOT running"
    fi
STATUS_SCRIPT
    echo ""
done

echo "✅ Initialization complete!"

