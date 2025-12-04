#!/bin/bash
# PH8-04 - ERPNext MariaDB End-to-End Test via LB
set -e

cd /opt/keybuzz/keybuzz-infra

# Get ERPNext password (should be set by ph8-04-erpnext-db-setup.sh)
ERP_PASS=${ERP_PASS:-"erpnext_temp_pass_$(openssl rand -hex 12)"}

LB_ENDPOINT="10.0.0.10"
LB_PORT="3306"
DB_NAME="erpnextdb"

echo "[INFO] =========================================="
echo "[INFO] ERPNext MariaDB End-to-End Test"
echo "[INFO] =========================================="
echo "[INFO] LB Endpoint: ${LB_ENDPOINT}:${LB_PORT}"
echo "[INFO] Database: ${DB_NAME}"
echo "[INFO] User: erpnext"
echo ""

# Test connection
echo "[INFO] Test 1: Connecting to MariaDB via LB..."
if mysql -h${LB_ENDPOINT} -P${LB_PORT} -u erpnext -p"${ERP_PASS}" -e "SELECT VERSION();" 2>&1; then
    echo "[INFO]   ✅ Connection successful"
else
    echo "[ERROR]   ❌ Connection failed"
    exit 1
fi

# Test database access
echo ""
echo "[INFO] Test 2: Accessing erpnextdb..."
if mysql -h${LB_ENDPOINT} -P${LB_PORT} -u erpnext -p"${ERP_PASS}" ${DB_NAME} -e "SHOW TABLES;" 2>&1; then
    echo "[INFO]   ✅ Database access successful"
else
    echo "[ERROR]   ❌ Database access failed"
    exit 1
fi

# Test table creation and operations
echo ""
echo "[INFO] Test 3: Creating test table..."
mysql -h${LB_ENDPOINT} -P${LB_PORT} -u erpnext -p"${ERP_PASS}" ${DB_NAME} <<SQL
CREATE TABLE IF NOT EXISTS test_e2e (
    id INT AUTO_INCREMENT PRIMARY KEY,
    v VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SQL

if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ Table created"
else
    echo "[ERROR]   ❌ Table creation failed"
    exit 1
fi

# Test INSERT
echo ""
echo "[INFO] Test 4: Inserting test data..."
mysql -h${LB_ENDPOINT} -P${LB_PORT} -u erpnext -p"${ERP_PASS}" ${DB_NAME} <<SQL
INSERT INTO test_e2e (v) VALUES ('OK_FROM_LB');
SQL

if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ Data inserted"
else
    echo "[ERROR]   ❌ Data insertion failed"
    exit 1
fi

# Test SELECT
echo ""
echo "[INFO] Test 5: Reading data..."
echo "[INFO]   Results:"
mysql -h${LB_ENDPOINT} -P${LB_PORT} -u erpnext -p"${ERP_PASS}" ${DB_NAME} -e "SELECT * FROM test_e2e;" 2>&1

if [ $? -eq 0 ]; then
    echo "[INFO]   ✅ Data read successfully"
else
    echo "[ERROR]   ❌ Data read failed"
    exit 1
fi

echo ""
echo "[INFO] =========================================="
echo "[INFO] ✅ All tests passed!"
echo "[INFO] =========================================="
echo ""

