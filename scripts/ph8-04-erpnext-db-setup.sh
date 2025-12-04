#!/bin/bash
# PH8-04 - ERPNext MariaDB Database Setup
set -e

cd /opt/keybuzz/keybuzz-infra

# Get MariaDB root password (placeholder for now)
MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-"CHANGE_ME_LATER_VIA_VAULT"}

# Generate ERPNext password
ERP_PASS="erpnext_temp_pass_$(openssl rand -hex 12)"

echo "[INFO] =========================================="
echo "[INFO] PH8-04 ERPNext MariaDB Database Setup"
echo "[INFO] =========================================="
echo "[INFO] MariaDB Root Password: [REDACTED]"
echo "[INFO] ERPNext Password: ${ERP_PASS}"
echo ""

# Step 1: Check cluster status
echo "[INFO] Step 1: Checking MariaDB Galera cluster status..."
CLUSTER_OK=false
if ssh root@10.0.0.171 "systemctl is-active --quiet mariadb"; then
    CLUSTER_SIZE=$(ssh root@10.0.0.171 "mysql -u root -p'${MARIADB_ROOT_PASSWORD}' -e \"SHOW STATUS LIKE 'wsrep_cluster_size';\" 2>&1" | grep -E 'Value' | awk '{print $2}' || echo "0")
    if [ "$CLUSTER_SIZE" = "3" ]; then
        echo "[INFO]   ✅ Cluster is operational (size: ${CLUSTER_SIZE})"
        CLUSTER_OK=true
    else
        echo "[WARN]   ⚠️  Cluster size is ${CLUSTER_SIZE}, expected 3"
    fi
else
    echo "[ERROR]   ❌ MariaDB is not running on maria-02"
fi

if [ "$CLUSTER_OK" = "false" ]; then
    echo "[ERROR] Cluster is not operational. Cannot proceed with ERPNext setup."
    echo "[ERROR] Please fix the MariaDB Galera cluster first (PH8-02)."
    exit 1
fi

# Step 2: Create erpnextdb database
echo ""
echo "[INFO] Step 2: Creating erpnextdb database..."
ssh root@10.0.0.171 bash <<EOF
mysql -u root -p'${MARIADB_ROOT_PASSWORD}' <<SQL
CREATE DATABASE IF NOT EXISTS erpnextdb
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
SQL
EOF

if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ Database erpnextdb created"
else
    echo "[ERROR]   ❌ Database creation failed"
    exit 1
fi

# Step 3: Create erpnext user
echo ""
echo "[INFO] Step 3: Creating erpnext user..."
ssh root@10.0.0.171 bash <<EOF
mysql -u root -p'${MARIADB_ROOT_PASSWORD}' <<SQL
CREATE USER IF NOT EXISTS 'erpnext'@'%' IDENTIFIED BY '${ERP_PASS}';

GRANT 
  SELECT, INSERT, UPDATE, DELETE,
  CREATE, DROP, INDEX, ALTER,
  CREATE VIEW, SHOW VIEW,
  CREATE ROUTINE, ALTER ROUTINE, EXECUTE,
  REFERENCES,
  CREATE TEMPORARY TABLES,
  LOCK TABLES
ON erpnextdb.* TO 'erpnext'@'%';

FLUSH PRIVILEGES;
SQL
EOF

if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ User erpnext created with required privileges"
else
    echo "[ERROR]   ❌ User creation failed"
    exit 1
fi

# Step 4: Verify Galera replication
echo ""
echo "[INFO] Step 4: Verifying Galera replication..."
echo "[INFO]   Checking cluster size..."
ssh root@10.0.0.171 "mysql -u root -p'${MARIADB_ROOT_PASSWORD}' -e \"SHOW STATUS LIKE 'wsrep_cluster_size';\" 2>&1" | grep -E '(wsrep_cluster_size|Value)'

echo "[INFO]   Checking erpnextdb on maria-01..."
ssh root@10.0.0.170 "mysql -u root -p'${MARIADB_ROOT_PASSWORD}' -e \"SHOW DATABASES LIKE 'erpnextdb';\" 2>&1" | grep erpnextdb && echo "[INFO]     ✅ erpnextdb exists on maria-01" || echo "[WARN]     ⚠️  erpnextdb not found on maria-01"

echo "[INFO]   Checking erpnextdb on maria-03..."
ssh root@10.0.0.172 "mysql -u root -p'${MARIADB_ROOT_PASSWORD}' -e \"SHOW DATABASES LIKE 'erpnextdb';\" 2>&1" | grep erpnextdb && echo "[INFO]     ✅ erpnextdb exists on maria-03" || echo "[WARN]     ⚠️  erpnextdb not found on maria-03"

# Step 5: Inject user into ProxySQL
echo ""
echo "[INFO] Step 5: Injecting erpnext user into ProxySQL..."
for proxysql_ip in 10.0.0.173 10.0.0.174; do
    echo "[INFO]   Configuring ProxySQL on ${proxysql_ip}..."
    ssh root@${proxysql_ip} bash <<EOF
mysql -h 127.0.0.1 -P6032 -u admin -padmin <<SQL
INSERT INTO mysql_users (username, password, default_hostgroup, active)
VALUES ('erpnext', '${ERP_PASS}', 0, 1)
ON DUPLICATE KEY UPDATE password='${ERP_PASS}', active=1;

LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
SQL
EOF
    if [ $? -eq 0 ]; then
        echo "[INFO]     ✅ ProxySQL configured on ${proxysql_ip}"
    else
        echo "[ERROR]     ❌ ProxySQL configuration failed on ${proxysql_ip}"
    fi
done

# Step 6: Test via LB
echo ""
echo "[INFO] Step 6: Testing connection via LB (10.0.0.10:3306)..."
LB_ENDPOINT="10.0.0.10"
LB_PORT="3306"

mysql -h${LB_ENDPOINT} -P${LB_PORT} -u erpnext -p"${ERP_PASS}" erpnextdb <<SQL
CREATE TABLE IF NOT EXISTS test_e2e (
    id INT AUTO_INCREMENT PRIMARY KEY,
    v VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO test_e2e (v) VALUES ('OK_FROM_LB');

SELECT * FROM test_e2e;
SQL

if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ End-to-end test via LB successful"
else
    echo "[ERROR]   ❌ End-to-end test failed"
    exit 1
fi

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ ERPNext database setup complete!"
echo "[INFO] =========================================="
echo "[INFO] Database: erpnextdb"
echo "[INFO] User: erpnext"
echo "[INFO] Password: ${ERP_PASS}"
echo "[INFO] Endpoint: mysql://erpnext:${ERP_PASS}@${LB_ENDPOINT}:${LB_PORT}/erpnextdb"
echo ""

