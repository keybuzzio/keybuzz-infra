#!/bin/bash
# PH8-02 FINAL FIX - Initialize MariaDB without Galera, then bootstrap cluster
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== PH8-02 FINAL FIX - MariaDB Galera Initialization ==="
echo ""

# Step 1: Disable Galera and initialize MariaDB on all nodes
echo "=== Step 1: Disabling Galera and initializing MariaDB ==="
for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "Processing $ip..."
    ssh root@$ip bash <<'INIT_SCRIPT'
    set -e
    
    # Stop MariaDB
    systemctl stop mariadb || true
    
    # Disable Galera
    if [ -f /etc/mysql/conf.d/galera.cnf ]; then
        mv /etc/mysql/conf.d/galera.cnf /etc/mysql/conf.d/galera.cnf.disabled
        echo "  ✅ Galera disabled"
    fi
    
    # Clean and initialize MariaDB
    rm -rf /data/mariadb/data/*
    mysqld --initialize-insecure --datadir=/data/mariadb/data --user=mysql
    chown -R mysql:mysql /data/mariadb/data
    
    echo "  ✅ MariaDB initialized on $(hostname)"
INIT_SCRIPT
done

echo ""
echo "=== Step 2: Re-enabling Galera ==="
for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "Re-enabling Galera on $ip..."
    ssh root@$ip bash <<'REENABLE_SCRIPT'
    if [ -f /etc/mysql/conf.d/galera.cnf.disabled ]; then
        mv /etc/mysql/conf.d/galera.cnf.disabled /etc/mysql/conf.d/galera.cnf
        echo "  ✅ Galera re-enabled"
    fi
REENABLE_SCRIPT
done

echo ""
echo "=== Step 3: Bootstrap cluster on maria-02 (10.0.0.171) ==="
ssh root@10.0.0.171 bash <<'BOOTSTRAP_SCRIPT'
    galera_new_cluster
    sleep 5
    systemctl status mariadb --no-pager | head -10
BOOTSTRAP_SCRIPT

echo ""
echo "=== Step 4: Starting maria-01 and maria-03 ==="
ssh root@10.0.0.170 "systemctl start mariadb && echo '✅ maria-01 started'"
ssh root@10.0.0.172 "systemctl start mariadb && echo '✅ maria-03 started'"

echo ""
echo "=== Waiting for cluster to stabilize ==="
sleep 10

echo ""
echo "=== Step 5: Verifying cluster ==="
bash scripts/ph8-02-check-cluster.sh

echo ""
echo "✅ Initialization complete!"

