#!/bin/bash
# PH8-02 COMPLETE INIT - Complete MariaDB Galera initialization
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== PH8-02 COMPLETE INIT - MariaDB Galera ==="
echo ""

# Step 1: Initialize all nodes without Galera
echo "=== Step 1: Initializing MariaDB without Galera ==="
for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "Processing $ip..."
    ssh root@$ip bash <<'INIT_SCRIPT'
    set -e
    
    systemctl stop mariadb || true
    
    # Disable Galera
    if [ -f /etc/mysql/conf.d/galera.cnf ]; then
        mv /etc/mysql/conf.d/galera.cnf /etc/mysql/conf.d/galera.cnf.disabled
    fi
    
    # Clean and initialize
    rm -rf /data/mariadb/data/*
    mysqld --initialize-insecure --datadir=/data/mariadb/data --user=mysql
    chown -R mysql:mysql /data/mariadb/data
    
    # Verify mysql directory exists
    if [ -d /data/mariadb/data/mysql ]; then
        echo "  ✅ mysql directory created"
    else
        echo "  ❌ mysql directory missing"
        exit 1
    fi
INIT_SCRIPT
done

echo ""
echo "=== Step 2: Re-enabling Galera ==="
for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "Re-enabling Galera on $ip..."
    ssh root@$ip "mv /etc/mysql/conf.d/galera.cnf.disabled /etc/mysql/conf.d/galera.cnf"
done

echo ""
echo "=== Step 3: Bootstrap cluster on maria-02 ==="
ssh root@10.0.0.171 bash <<'BOOTSTRAP_SCRIPT'
    # Set bootstrap mode
    sed -i 's|wsrep_cluster_address = .*|wsrep_cluster_address = gcomm://|g' /etc/mysql/conf.d/galera.cnf
    
    # Bootstrap
    galera_new_cluster
    
    # Wait for startup
    sleep 10
    
    # Check status
    systemctl status mariadb --no-pager | head -10
BOOTSTRAP_SCRIPT

echo ""
echo "=== Step 4: Restore cluster address on maria-02 ==="
ssh root@10.0.0.171 "sed -i 's|wsrep_cluster_address = gcomm://|wsrep_cluster_address = gcomm://10.0.0.170,10.0.0.171,10.0.0.172|g' /etc/mysql/conf.d/galera.cnf"
ssh root@10.0.0.171 "systemctl restart mariadb"
sleep 5

echo ""
echo "=== Step 5: Starting maria-01 and maria-03 ==="
ssh root@10.0.0.170 "systemctl start mariadb"
ssh root@10.0.0.172 "systemctl start mariadb"

echo ""
echo "=== Waiting for cluster to stabilize ==="
sleep 15

echo ""
echo "=== Step 6: Verifying cluster ==="
bash scripts/ph8-02-check-cluster-status.sh

echo ""
echo "✅ Initialization complete!"

