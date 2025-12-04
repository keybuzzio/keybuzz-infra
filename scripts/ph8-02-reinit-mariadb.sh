#!/bin/bash
# PH8-02 - Reinitialize MariaDB databases
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== Reinitializing MariaDB databases ==="
echo ""

for ip in 10.0.0.170 10.0.0.171 10.0.0.172; do
    echo "=== Reinitializing maria node $ip ==="
    ssh root@$ip bash <<'REINIT_SCRIPT'
    set -e
    
    # Stop MariaDB
    systemctl stop mariadb 2>/dev/null || true
    
    # Clean data directory completely
    rm -rf /data/mariadb/data/*
    rm -rf /data/mariadb/data/.* 2>/dev/null || true
    
    # Initialize database
    mysqld --initialize-insecure --datadir=/data/mariadb/data --user=mysql
    
    # Fix permissions
    chown -R mysql:mysql /data/mariadb/data
    
    # Set galera.cnf to bootstrap mode
    sed -i 's|wsrep_cluster_address = .*|wsrep_cluster_address = gcomm://|g' /etc/mysql/conf.d/galera.cnf
    
    echo "✅ Database reinitialized on $(hostname)"
REINIT_SCRIPT
done

echo "✅ All databases reinitialized"

