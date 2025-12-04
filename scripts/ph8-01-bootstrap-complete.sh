#!/bin/bash
# PH8-01 Complete Bootstrap - All steps in one script
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== PH8-01 MariaDB Galera Bootstrap ==="

# Bootstrap maria-02 directly via SSH
echo "Bootstrapping maria-02..."
ssh root@10.0.0.171 bash <<'BOOTSTRAP'
set -e
DATA_DIR='/data/mariadb/data'
LOG_DIR='/data/mariadb/logs'
ROOT_PASSWORD='CHANGE_ME_LATER_VIA_VAULT'
SST_PASSWORD='CHANGE_ME_LATER_VIA_VAULT'

echo "=== MariaDB Galera Bootstrap ==="

systemctl stop mariadb || true
sleep 3

if [ -d "${DATA_DIR}" ]; then
    cd "${DATA_DIR}"
    find . -mindepth 1 -delete 2>/dev/null || rm -rf * 2>/dev/null || true
fi

mkdir -p "${DATA_DIR}" "${LOG_DIR}"
chown -R mysql:mysql "${DATA_DIR}" "${LOG_DIR}"

echo "Initializing MariaDB..."
mysqld --initialize-insecure --datadir="${DATA_DIR}" --user=mysql 2>&1 | tail -3 || true
chown -R mysql:mysql "${DATA_DIR}"

echo "Configuring Galera..."
sed -i 's|^wsrep_cluster_address = .*|wsrep_cluster_address = gcomm://|' /etc/mysql/conf.d/galera.cnf

echo "Starting MariaDB..."
systemctl start mariadb || {
    echo "Failed to start, checking logs..."
    tail -50 "${LOG_DIR}/mysql.err" || journalctl -u mariadb -n 50 --no-pager
    exit 1
}

sleep 30

if systemctl is-active --quiet mariadb; then
    echo "MariaDB is running"
    sleep 10
    
    mysql -u root <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS 'sst_user'@'%' IDENTIFIED BY '${SST_PASSWORD}';
GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'sst_user'@'%';
FLUSH PRIVILEGES;
SQL
    
    sed -i 's|^wsrep_cluster_address = gcomm://|wsrep_cluster_address = gcomm://10.0.0.170,10.0.0.171,10.0.0.172|' /etc/mysql/conf.d/galera.cnf
    systemctl restart mariadb
    sleep 15
    
    mysql -u root -p"${ROOT_PASSWORD}" -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
    mysql -u root -p"${ROOT_PASSWORD}" -e "SHOW STATUS LIKE 'wsrep_local_state_comment';"
else
    echo "MariaDB failed to start"
    exit 1
fi

echo "=== Bootstrap completed ==="
BOOTSTRAP

echo ""
echo "Bootstrap completed. Joining other nodes..."

# Join maria-03
echo "Joining maria-03..."
ssh root@10.0.0.172 bash <<'JOIN'
set -e
systemctl stop mariadb || true
sleep 2
rm -rf /data/mariadb/data/* 2>/dev/null || true
systemctl start mariadb
sleep 20
for i in {1..30}; do
    if mysql -u root -e "SELECT 1;" > /dev/null 2>&1; then
        echo "MariaDB is ready!"
        break
    fi
    sleep 2
done
mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size';" 2>&1 || echo "Not connected yet"
JOIN

echo ""
echo "Verifying cluster..."
sleep 10

for host in 10.0.0.171 10.0.0.172; do
    echo "Checking $host..."
    CLUSTER_SIZE=$(ssh root@$host "mysql -u root -p'CHANGE_ME_LATER_VIA_VAULT' -e \"SHOW STATUS LIKE 'wsrep_cluster_size';\" 2>&1 | grep -v Warning | tail -1 | awk '{print \$2}'" || echo "0")
    NODE_STATUS=$(ssh root@$host "mysql -u root -p'CHANGE_ME_LATER_VIA_VAULT' -e \"SHOW STATUS LIKE 'wsrep_local_state_comment';\" 2>&1 | grep -v Warning | tail -1 | awk '{print \$2}'" || echo "UNKNOWN")
    echo "  $host: cluster_size=$CLUSTER_SIZE, status=$NODE_STATUS"
done

echo ""
echo "=== Bootstrap process completed ==="

