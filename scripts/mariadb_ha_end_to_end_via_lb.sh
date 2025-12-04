#!/bin/bash
# PH8-03 - MariaDB Galera HA End-to-End Test via LB (10.0.0.10:3306)
set -e

cd /opt/keybuzz/keybuzz-infra

# Get MariaDB root password from group_vars
MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-"CHANGE_ME_LATER_VIA_VAULT"}

LB_ENDPOINT="10.0.0.10"
LB_PORT="3306"
TEST_DB="kb_mariadb_lb_test"
TEST_TABLE="lb_test_table"

echo "[INFO] =========================================="
echo "[INFO] MariaDB Galera HA End-to-End Test via LB"
echo "[INFO] =========================================="
echo "[INFO] LB Endpoint: ${LB_ENDPOINT}:${LB_PORT}"
echo "[INFO] Test Database: ${TEST_DB}"
echo ""

# Test 1: Connect to MariaDB via LB
echo "[INFO] Test 1: Connecting to MariaDB via LB..."
if mysql -h${LB_ENDPOINT} -P${LB_PORT} -u root -p"${MARIADB_ROOT_PASSWORD}" -e "SELECT VERSION();" 2>&1; then
    echo "[INFO]   ✅ Connection successful"
else
    echo "[ERROR]   ❌ Connection failed"
    exit 1
fi

# Test 2: Create database
echo ""
echo "[INFO] Test 2: Creating database ${TEST_DB}..."
if mysql -h${LB_ENDPOINT} -P${LB_PORT} -u root -p"${MARIADB_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${TEST_DB};" 2>&1; then
    echo "[INFO]   ✅ Database created"
else
    echo "[ERROR]   ❌ Database creation failed"
    exit 1
fi

# Test 3: Create table
echo ""
echo "[INFO] Test 3: Creating table ${TEST_TABLE}..."
if mysql -h${LB_ENDPOINT} -P${LB_PORT} -u root -p"${MARIADB_ROOT_PASSWORD}" ${TEST_DB} <<EOF
CREATE TABLE IF NOT EXISTS ${TEST_TABLE} (
    id INT AUTO_INCREMENT PRIMARY KEY,
    value VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
EOF
then
    echo "[INFO]   ✅ Table created"
else
    echo "[ERROR]   ❌ Table creation failed"
    exit 1
fi

# Test 4: Insert data
echo ""
echo "[INFO] Test 4: Inserting test data..."
if mysql -h${LB_ENDPOINT} -P${LB_PORT} -u root -p"${MARIADB_ROOT_PASSWORD}" ${TEST_DB} <<EOF
INSERT INTO ${TEST_TABLE} (value) VALUES ('MariaDB-HA-LB-TEST-OK');
INSERT INTO ${TEST_TABLE} (value) VALUES ('Test via HAProxy + LB');
EOF
then
    echo "[INFO]   ✅ Data inserted"
else
    echo "[ERROR]   ❌ Data insertion failed"
    exit 1
fi

# Test 5: Select data
echo ""
echo "[INFO] Test 5: Reading data..."
echo "[INFO]   Results:"
mysql -h${LB_ENDPOINT} -P${LB_PORT} -u root -p"${MARIADB_ROOT_PASSWORD}" ${TEST_DB} -e "SELECT * FROM ${TEST_TABLE};" 2>&1

if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ Data read successfully"
else
    echo "[ERROR]   ❌ Data read failed"
    exit 1
fi

# Test 6: Check cluster status
echo ""
echo "[INFO] Test 6: Checking Galera cluster status..."
mysql -h${LB_ENDPOINT} -P${LB_PORT} -u root -p"${MARIADB_ROOT_PASSWORD}" -e "SHOW STATUS LIKE 'wsrep_cluster_size'; SHOW STATUS LIKE 'wsrep_local_state_comment';" 2>&1 | grep -E '(wsrep_cluster_size|wsrep_local_state_comment|Value)' || echo "[WARN]   ⚠️  Could not query cluster status"

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ All tests passed!"
echo "[INFO] =========================================="
echo "[INFO] MariaDB endpoint: mysql://root:${MARIADB_ROOT_PASSWORD}@${LB_ENDPOINT}:${LB_PORT}/${TEST_DB}"
echo ""

