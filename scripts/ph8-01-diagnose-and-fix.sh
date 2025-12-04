#!/bin/bash
# PH8-01 Diagnose and Fix MariaDB Galera Bootstrap
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== PH8-01 Diagnose and Fix ==="
echo ""

# Check maria-02 status
echo "Checking maria-02 (10.0.0.171)..."
ssh root@10.0.0.171 bash <<'CHECK'
echo "MariaDB service status:"
systemctl status mariadb --no-pager | head -10 || echo "Service not running"

echo ""
echo "Last 20 lines of MariaDB logs:"
journalctl -u mariadb -n 20 --no-pager || echo "No logs"

echo ""
echo "Error log (last 20 lines):"
tail -20 /data/mariadb/logs/mysql.err 2>/dev/null || echo "No error log"

echo ""
echo "Galera config:"
cat /etc/mysql/conf.d/galera.cnf 2>/dev/null || echo "No galera.cnf"

echo ""
echo "Data directory:"
ls -la /data/mariadb/data/ 2>/dev/null | head -10 || echo "No data directory"
CHECK

echo ""
echo "Attempting bootstrap on maria-02..."
ssh root@10.0.0.171 bash <<'BOOTSTRAP'
set -e
DATA_DIR='/data/mariadb/data'
LOG_DIR='/data/mariadb/logs'
ROOT_PASSWORD='CHANGE_ME_LATER_VIA_VAULT'
SST_PASSWORD='CHANGE_ME_LATER_VIA_VAULT'

echo "Stopping MariaDB..."
systemctl stop mariadb || true
sleep 3

echo "Cleaning data directory..."
if [ -d "${DATA_DIR}" ]; then
    cd "${DATA_DIR}"
    rm -rf * .* 2>/dev/null || true
fi

echo "Creating directories..."
mkdir -p "${DATA_DIR}" "${LOG_DIR}"
chown -R mysql:mysql "${DATA_DIR}" "${LOG_DIR}"

echo "Initializing MariaDB..."
mysqld --initialize-insecure --datadir="${DATA_DIR}" --user=mysql 2>&1 | tail -5 || true
chown -R mysql:mysql "${DATA_DIR}"

echo "Configuring Galera for bootstrap..."
sed -i 's|^wsrep_cluster_address = .*|wsrep_cluster_address = gcomm://|' /etc/mysql/conf.d/galera.cnf

echo "Starting MariaDB..."
systemctl start mariadb
sleep 35

if systemctl is-active --quiet mariadb; then
    echo "✅ MariaDB started successfully"
    sleep 10
    
    echo "Configuring users..."
    mysql -u root <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS 'sst_user'@'%' IDENTIFIED BY '${SST_PASSWORD}';
GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'sst_user'@'%';
FLUSH PRIVILEGES;
SQL
    
    echo "Restoring cluster configuration..."
    sed -i 's|^wsrep_cluster_address = gcomm://|wsrep_cluster_address = gcomm://10.0.0.170,10.0.0.171,10.0.0.172|' /etc/mysql/conf.d/galera.cnf
    systemctl restart mariadb
    sleep 20
    
    echo "Cluster status:"
    mysql -u root -p"${ROOT_PASSWORD}" -e "SHOW STATUS LIKE 'wsrep_cluster_size';" || echo "Not ready"
    mysql -u root -p"${ROOT_PASSWORD}" -e "SHOW STATUS LIKE 'wsrep_local_state_comment';" || echo "Not ready"
else
    echo "❌ MariaDB failed to start"
    echo "Last 30 lines of error log:"
    tail -30 "${LOG_DIR}/mysql.err" 2>/dev/null || journalctl -u mariadb -n 30 --no-pager
    exit 1
fi
BOOTSTRAP

echo ""
echo "Bootstrap completed. Checking status..."
sleep 5

for host in 10.0.0.171 10.0.0.172; do
    echo "Checking $host..."
    if ssh root@$host "systemctl is-active --quiet mariadb"; then
        CLUSTER_SIZE=$(ssh root@$host "mysql -u root -p'CHANGE_ME_LATER_VIA_VAULT' -e \"SHOW STATUS LIKE 'wsrep_cluster_size';\" 2>&1" | grep -v Warning | tail -1 | awk '{print $2}' || echo "0")
        NODE_STATUS=$(ssh root@$host "mysql -u root -p'CHANGE_ME_LATER_VIA_VAULT' -e \"SHOW STATUS LIKE 'wsrep_local_state_comment';\" 2>&1" | grep -v Warning | tail -1 | awk '{print $2}' || echo "UNKNOWN")
        echo "  ✅ $host: cluster_size=$CLUSTER_SIZE, status=$NODE_STATUS"
    else
        echo "  ❌ $host: MariaDB not running"
    fi
done

echo ""
echo "=== Diagnose and Fix completed ==="

