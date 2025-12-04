#!/bin/bash
# Simple MariaDB Galera Bootstrap Script
set -e

DATA_DIR='/data/mariadb/data'
LOG_DIR='/data/mariadb/logs'
ROOT_PASSWORD='CHANGE_ME_LATER_VIA_VAULT'
SST_PASSWORD='CHANGE_ME_LATER_VIA_VAULT'

echo "=== Bootstraping MariaDB Galera Cluster ==="

# Stop MariaDB
systemctl stop mariadb || true
sleep 2

# Clean data
if [ -d "${DATA_DIR}" ]; then
    cd "${DATA_DIR}"
    rm -rf mysql* ib* aria* *.log *.pid 2>/dev/null || true
fi

# Initialize
echo "Initializing MariaDB..."
mysqld --initialize-insecure --datadir="${DATA_DIR}" --user=mysql 2>&1 | tail -3 || true
chown -R mysql:mysql "${DATA_DIR}"

# Modify galera.cnf for bootstrap
echo "Modifying galera.cnf for bootstrap..."
sed -i 's|wsrep_cluster_address = .*|wsrep_cluster_address = gcomm://|' /etc/mysql/conf.d/galera.cnf

# Start MariaDB
echo "Starting MariaDB..."
systemctl start mariadb
sleep 20

# Check if running
if systemctl is-active --quiet mariadb; then
    echo "MariaDB started successfully"
    sleep 5
    
    # Set root password
    echo "Setting root password..."
    mysql -u root <<SQL || true
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS 'sst_user'@'%' IDENTIFIED BY '${SST_PASSWORD}';
GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'sst_user'@'%';
FLUSH PRIVILEGES;
SQL
    
    # Restore cluster address
    echo "Restoring cluster configuration..."
    sed -i 's|wsrep_cluster_address = gcomm://|wsrep_cluster_address = gcomm://10.0.0.170,10.0.0.171,10.0.0.172|' /etc/mysql/conf.d/galera.cnf
    systemctl restart mariadb
    sleep 10
    
    # Check cluster status
    echo "Checking cluster status..."
    mysql -u root -p"${ROOT_PASSWORD}" -e "SHOW STATUS LIKE 'wsrep_cluster_size';" || echo "Not ready yet"
    mysql -u root -p"${ROOT_PASSWORD}" -e "SHOW STATUS LIKE 'wsrep_local_state_comment';" || true
else
    echo "Failed to start MariaDB"
    journalctl -u mariadb -n 30 --no-pager
    exit 1
fi

echo "=== Bootstrap completed ==="

