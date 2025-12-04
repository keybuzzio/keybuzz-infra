#!/bin/bash
# PH8-01 Full Bootstrap - Complete process
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== PH8-01 Full MariaDB Galera Bootstrap ==="
echo ""

# Step 1: Bootstrap maria-02
echo "Step 1: Bootstrapping maria-02..."
ssh root@10.0.0.171 bash <<'BOOTSTRAP'
set -e
DATA_DIR='/data/mariadb/data'
LOG_DIR='/data/mariadb/logs'
ROOT_PASSWORD='CHANGE_ME_LATER_VIA_VAULT'
SST_PASSWORD='CHANGE_ME_LATER_VIA_VAULT'

echo "=== Bootstrap Process ==="

# Stop MariaDB
echo "Stopping MariaDB..."
systemctl stop mariadb || true
sleep 3

# Clean data
echo "Cleaning data directory..."
if [ -d "${DATA_DIR}" ]; then
    cd "${DATA_DIR}"
    rm -rf * .* 2>/dev/null || true
fi

# Create directories
echo "Creating directories..."
mkdir -p "${DATA_DIR}" "${LOG_DIR}"
chown -R mysql:mysql "${DATA_DIR}" "${LOG_DIR}"

# Initialize
echo "Initializing MariaDB..."
mysqld --initialize-insecure --datadir="${DATA_DIR}" --user=mysql 2>&1 | tail -5 || true
chown -R mysql:mysql "${DATA_DIR}"

# Configure Galera for bootstrap
echo "Configuring Galera for bootstrap..."
sed -i 's|^wsrep_cluster_address = .*|wsrep_cluster_address = gcomm://|' /etc/mysql/conf.d/galera.cnf

# Start MariaDB
echo "Starting MariaDB..."
systemctl start mariadb
sleep 40

# Check if running
if systemctl is-active --quiet mariadb; then
    echo "✅ MariaDB started successfully"
    sleep 15
    
    # Configure users
    echo "Configuring users..."
    mysql -u root <<SQL || true
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS 'sst_user'@'%' IDENTIFIED BY '${SST_PASSWORD}';
GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'sst_user'@'%';
FLUSH PRIVILEGES;
SQL
    
    # Restore cluster config
    echo "Restoring cluster configuration..."
    sed -i 's|^wsrep_cluster_address = gcomm://|wsrep_cluster_address = gcomm://10.0.0.170,10.0.0.171,10.0.0.172|' /etc/mysql/conf.d/galera.cnf
    systemctl restart mariadb
    sleep 20
    
    # Show status
    echo "Cluster status:"
    mysql -u root -p"${ROOT_PASSWORD}" -e "SHOW STATUS LIKE 'wsrep_cluster_size';" 2>&1 | grep -v Warning || echo "Not ready"
    mysql -u root -p"${ROOT_PASSWORD}" -e "SHOW STATUS LIKE 'wsrep_local_state_comment';" 2>&1 | grep -v Warning || echo "Not ready"
else
    echo "❌ MariaDB failed to start"
    echo "Error log:"
    tail -50 "${LOG_DIR}/mysql.err" 2>/dev/null || journalctl -u mariadb -n 50 --no-pager
    exit 1
fi
BOOTSTRAP

echo ""
echo "Step 2: Joining maria-03..."
ssh root@10.0.0.172 bash <<'JOIN'
set -e
DATA_DIR='/data/mariadb/data'

echo "Stopping MariaDB..."
systemctl stop mariadb || true
sleep 3

echo "Cleaning data directory..."
if [ -d "${DATA_DIR}" ]; then
    cd "${DATA_DIR}"
    rm -rf * .* 2>/dev/null || true
fi

echo "Starting MariaDB to join cluster..."
systemctl start mariadb
sleep 30

echo "Waiting for MariaDB to be ready..."
for i in {1..30}; do
    if mysql -u root -e "SELECT 1;" > /dev/null 2>&1; then
        echo "✅ MariaDB is ready!"
        break
    fi
    sleep 2
done

echo "Cluster status:"
mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size';" 2>&1 | grep -v Warning || echo "Not ready"
mysql -u root -e "SHOW STATUS LIKE 'wsrep_local_state_comment';" 2>&1 | grep -v Warning || echo "Not ready"
JOIN

echo ""
echo "Step 3: Final verification..."
sleep 10

ROOT_PASSWORD='CHANGE_ME_LATER_VIA_VAULT'
for host in 10.0.0.171 10.0.0.172; do
    echo "Checking $host..."
    if ssh root@$host "systemctl is-active --quiet mariadb"; then
        CLUSTER_SIZE=$(ssh root@$host "mysql -u root -p'${ROOT_PASSWORD}' -e \"SHOW STATUS LIKE 'wsrep_cluster_size';\" 2>&1" | grep -v Warning | tail -1 | awk '{print $2}' || echo "0")
        NODE_STATUS=$(ssh root@$host "mysql -u root -p'${ROOT_PASSWORD}' -e \"SHOW STATUS LIKE 'wsrep_local_state_comment';\" 2>&1" | grep -v Warning | tail -1 | awk '{print $2}' || echo "UNKNOWN")
        echo "  ✅ $host: cluster_size=$CLUSTER_SIZE, status=$NODE_STATUS"
    else
        echo "  ❌ $host: MariaDB not running"
    fi
done

echo ""
echo "=== Bootstrap completed ==="

