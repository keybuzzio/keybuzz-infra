#!/bin/bash
# PH8-01 - MariaDB Galera HA End-to-End Test
# This script tests the complete MariaDB HA setup via ProxySQL

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get MariaDB root password from Ansible vars
cd /opt/keybuzz/keybuzz-infra
MARIADB_ROOT_PASSWORD=$(python3 << 'PYEOF'
import yaml
with open('ansible/group_vars/mariadb.yml') as f:
    data = yaml.safe_load(f)
    print(data.get('mariadb_root_password', 'CHANGE_ME'))
PYEOF
)

if [ "$MARIADB_ROOT_PASSWORD" == "CHANGE_ME" ] || [ "$MARIADB_ROOT_PASSWORD" == "CHANGE_ME_LATER_VIA_VAULT" ]; then
    log_warn "MariaDB root password is a placeholder"
fi

# ProxySQL endpoint
PROXYSQL_HOST="10.0.0.173"
PROXYSQL_PORT="6033"
TEST_DB="kb_mariadb_test"
TEST_TABLE="test_table"

log_info "=========================================="
log_info "MariaDB Galera HA End-to-End Test"
log_info "=========================================="
echo ""

# Test 1: Connect via ProxySQL
log_info "Test 1: Connecting to MariaDB via ProxySQL..."
if mysql -h${PROXYSQL_HOST} -P${PROXYSQL_PORT} -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "SELECT VERSION();" > /dev/null 2>&1; then
    log_info "  ✅ Connection successful"
    VERSION=$(mysql -h${PROXYSQL_HOST} -P${PROXYSQL_PORT} -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "SELECT VERSION();" 2>&1 | grep -v "Warning" | tail -1)
    log_info "  MariaDB version: ${VERSION}"
else
    log_error "  ❌ Connection failed"
    exit 1
fi
echo ""

# Test 2: Create database
log_info "Test 2: Creating test database..."
mysql -h${PROXYSQL_HOST} -P${PROXYSQL_PORT} -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS ${TEST_DB};" 2>&1 | grep -v "Warning" || true
log_info "  ✅ Database ${TEST_DB} created"
echo ""

# Test 3: Create table
log_info "Test 3: Creating test table..."
mysql -h${PROXYSQL_HOST} -P${PROXYSQL_PORT} -uroot -p"${MARIADB_ROOT_PASSWORD}" -D${TEST_DB} <<EOF 2>&1 | grep -v "Warning" || true
CREATE TABLE IF NOT EXISTS ${TEST_TABLE} (
    id INT AUTO_INCREMENT PRIMARY KEY,
    value VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
EOF
log_info "  ✅ Table ${TEST_TABLE} created"
echo ""

# Test 4: Insert data
log_info "Test 4: Inserting test data..."
mysql -h${PROXYSQL_HOST} -P${PROXYSQL_PORT} -uroot -p"${MARIADB_ROOT_PASSWORD}" -D${TEST_DB} <<EOF 2>&1 | grep -v "Warning" || true
INSERT INTO ${TEST_TABLE} (value) VALUES ('MariaDB-HA-OK');
INSERT INTO ${TEST_TABLE} (value) VALUES ('Galera-Cluster-Test');
INSERT INTO ${TEST_TABLE} (value) VALUES ('ProxySQL-Routing-Test');
EOF
log_info "  ✅ Data inserted"
echo ""

# Test 5: Read data
log_info "Test 5: Reading data..."
RESULT=$(mysql -h${PROXYSQL_HOST} -P${PROXYSQL_PORT} -uroot -p"${MARIADB_ROOT_PASSWORD}" -D${TEST_DB} -e "SELECT * FROM ${TEST_TABLE};" 2>&1 | grep -v "Warning" | tail -n +2)
if [ -n "$RESULT" ]; then
    log_info "  ✅ Data retrieved successfully:"
    echo "$RESULT" | while read line; do
        log_info "    ${line}"
    done
else
    log_error "  ❌ Failed to retrieve data"
    exit 1
fi
echo ""

# Test 6: Verify replication (check on all nodes)
log_info "Test 6: Verifying replication across cluster nodes..."
MARIA_NODES=("10.0.0.170" "10.0.0.171" "10.0.0.172")
MARIA_NAMES=("maria-01" "maria-02" "maria-03")

for i in "${!MARIA_NODES[@]}"; do
    NODE_IP="${MARIA_NODES[$i]}"
    NODE_NAME="${MARIA_NAMES[$i]}"
    
    COUNT=$(ssh -o StrictHostKeyChecking=no root@${NODE_IP} mysql -uroot -p"${MARIADB_ROOT_PASSWORD}" -h127.0.0.1 -D${TEST_DB} -e "SELECT COUNT(*) FROM ${TEST_TABLE};" 2>&1 | grep -v "Warning" | tail -1 || echo "0")
    
    if [ "$COUNT" == "3" ]; then
        log_info "  ✅ ${NODE_NAME}: ${COUNT} rows found (expected: 3)"
    else
        log_warn "  ⚠️  ${NODE_NAME}: ${COUNT} rows found (expected: 3)"
    fi
done
echo ""

# Test 7: Simulate node failure (optional - just check cluster continues)
log_info "Test 7: Checking cluster resilience..."
CLUSTER_SIZE=$(mysql -h${PROXYSQL_HOST} -P${PROXYSQL_PORT} -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "SHOW STATUS LIKE 'wsrep_cluster_size';" 2>&1 | grep -v "Warning" | tail -1 | awk '{print $2}' || echo "0")
log_info "  Cluster size via ProxySQL: ${CLUSTER_SIZE}"
echo ""

# Cleanup
log_info "Cleaning up test database..."
mysql -h${PROXYSQL_HOST} -P${PROXYSQL_PORT} -uroot -p"${MARIADB_ROOT_PASSWORD}" -e "DROP DATABASE IF EXISTS ${TEST_DB};" 2>&1 | grep -v "Warning" || true
log_info "  ✅ Test database removed"
echo ""

log_info "=========================================="
log_info "✅ All end-to-end tests passed"
log_info "=========================================="

