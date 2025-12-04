#!/bin/bash
# Final MariaDB Galera Bootstrap Script
set -e

DATA_DIR='/data/mariadb/data'
LOG_DIR='/data/mariadb/logs'
ROOT_PASSWORD='CHANGE_ME_LATER_VIA_VAULT'
SST_PASSWORD='CHANGE_ME_LATER_VIA_VAULT'
NODE_NAME="${1:-maria-02}"
NODE_IP="${2:-10.0.0.171}"

echo "=== Bootstraping MariaDB Galera Cluster on ${NODE_NAME} ==="

# Stop MariaDB
systemctl stop mariadb || true
sleep 3

# Clean data completely
if [ -d "${DATA_DIR}" ]; then
    echo "Cleaning data directory..."
    cd "${DATA_DIR}"
    rm -rf * .* 2>/dev/null || true
fi

# Ensure directories exist
mkdir -p "${DATA_DIR}" "${LOG_DIR}"
chown -R mysql:mysql "${DATA_DIR}" "${LOG_DIR}"

# Initialize MariaDB
echo "Initializing MariaDB..."
sudo -u mysql mysqld --initialize-insecure --datadir="${DATA_DIR}" 2>&1 | tail -5 || true
chown -R mysql:mysql "${DATA_DIR}"

# Modify galera.cnf for bootstrap
echo "Configuring Galera for bootstrap..."
sed -i 's|^wsrep_cluster_address = .*|wsrep_cluster_address = gcomm://|' /etc/mysql/conf.d/galera.cnf
sed -i "s|^wsrep_node_name = .*|wsrep_node_name = ${NODE_NAME}|" /etc/mysql/conf.d/galera.cnf
sed -i "s|^wsrep_node_address = .*|wsrep_node_address = ${NODE_IP}|" /etc/mysql/conf.d/galera.cnf

# Start MariaDB with bootstrap
echo "Starting MariaDB with bootstrap..."
systemctl start mariadb
sleep 30

# Check if running
if systemctl is-active --quiet mariadb; then
    echo "✅ MariaDB started successfully"
    sleep 10
    
    # Set root password and create users
    echo "Configuring users..."
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
    sed -i 's|^wsrep_cluster_address = gcomm://|wsrep_cluster_address = gcomm://10.0.0.170,10.0.0.171,10.0.0.172|' /etc/mysql/conf.d/galera.cnf
    systemctl restart mariadb
    sleep 15
    
    # Check cluster status
    echo "Checking cluster status..."
    mysql -u root -p"${ROOT_PASSWORD}" -e "SHOW STATUS LIKE 'wsrep_cluster_size';" || echo "Not ready yet"
    mysql -u root -p"${ROOT_PASSWORD}" -e "SHOW STATUS LIKE 'wsrep_local_state_comment';" || true
    mysql -u root -p"${ROOT_PASSWORD}" -e "SHOW STATUS LIKE 'wsrep_cluster_state_uuid';" || true
else
    echo "❌ Failed to start MariaDB"
    echo "Last 30 lines of error log:"
    tail -30 "${LOG_DIR}/mysql.err" || journalctl -u mariadb -n 30 --no-pager
    exit 1
fi

echo "=== Bootstrap completed ==="

