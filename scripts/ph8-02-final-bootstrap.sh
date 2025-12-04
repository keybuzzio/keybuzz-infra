#!/bin/bash
# PH8-02 Final Bootstrap Script
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== PH8-02 Final Bootstrap ==="
echo ""

# Fix galera.cnf on maria-03
echo "Step 1: Fixing galera.cnf on maria-03..."
ssh root@10.0.0.172 bash <<'FIX'
sed -i '/wsrep_replicate_myisam/d' /etc/mysql/conf.d/galera.cnf
sed -i '/pxc_strict_mode/d' /etc/mysql/conf.d/galera.cnf
echo "Fixed galera.cnf"
FIX

# Bootstrap maria-03
echo "Step 2: Bootstrapping maria-03..."
ssh root@10.0.0.172 bash <<'BOOTSTRAP'
set -e
DATA_DIR='/data/mariadb/data'
ROOT_PASSWORD='CHANGE_ME_LATER_VIA_VAULT'
SST_PASSWORD='CHANGE_ME_LATER_VIA_VAULT'

systemctl stop mariadb || true
sleep 3

rm -rf ${DATA_DIR}/* ${DATA_DIR}/.* 2>/dev/null || true

mysqld --initialize-insecure --datadir=${DATA_DIR} --user=mysql 2>&1 | tail -3 || true
chown -R mysql:mysql ${DATA_DIR}

sed -i 's|^wsrep_cluster_address = .*|wsrep_cluster_address = gcomm://|' /etc/mysql/conf.d/galera.cnf

systemctl start mariadb
sleep 35

if systemctl is-active --quiet mariadb; then
    echo "MariaDB started"
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
    sleep 20
    
    mysql -u root -p"${ROOT_PASSWORD}" -e "SHOW STATUS LIKE 'wsrep_cluster_size';" || echo "Not ready"
    mysql -u root -p"${ROOT_PASSWORD}" -e "SHOW STATUS LIKE 'wsrep_local_state_comment';" || echo "Not ready"
else
    echo "Failed to start MariaDB"
    exit 1
fi
BOOTSTRAP

echo ""
echo "Step 3: Checking cluster status..."
sleep 10
bash scripts/ph8-01-check-cluster.sh 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-cluster-status.log

echo ""
echo "Step 4: Fixing ProxySQL playbook..."
# Fix the proxysql playbook file directly
sed -i 's/Configure ProxySQL users (default: root user can connect)/Configure ProxySQL users/' ansible/roles/proxysql_v3/tasks/main.yml

echo ""
echo "Step 5: Deploying ProxySQL..."
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/proxysql_v3.yml --limit proxysql-01,proxysql-02 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-proxysql-deploy-final.log

echo ""
echo "Step 6: Running end-to-end tests..."
bash scripts/mariadb_ha_end_to_end.sh 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-e2e-final.log

echo ""
echo "=== Bootstrap completed ==="

