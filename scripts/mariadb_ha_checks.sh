#!/bin/bash
# PH8-01 - MariaDB Galera HA Cluster Checks
# This script verifies the MariaDB Galera cluster status

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

# MariaDB nodes
MARIA_NODES=("10.0.0.170" "10.0.0.171" "10.0.0.172")
MARIA_NAMES=("maria-01" "maria-02" "maria-03")

# ProxySQL nodes
PROXYSQL_NODES=("10.0.0.173" "10.0.0.174")
PROXYSQL_NAMES=("proxysql-01" "proxysql-02")

log_info "=========================================="
log_info "MariaDB Galera HA Cluster Checks"
log_info "=========================================="
echo ""

# Check MariaDB cluster status
log_info "Checking MariaDB Galera cluster status..."
echo ""

for i in "${!MARIA_NODES[@]}"; do
    NODE_IP="${MARIA_NODES[$i]}"
    NODE_NAME="${MARIA_NAMES[$i]}"
    
    log_info "Checking ${NODE_NAME} (${NODE_IP})..."
    
    # Check if MariaDB is listening
    if ssh -o StrictHostKeyChecking=no root@${NODE_IP} "ss -ntlp | grep :3306 > /dev/null 2>&1"; then
        log_info "  ✅ MariaDB is listening on port 3306"
    else
        log_error "  ❌ MariaDB is NOT listening on port 3306"
        continue
    fi
    
    # Check cluster size
    CLUSTER_SIZE=$(ssh -o StrictHostKeyChecking=no root@${NODE_IP} mysql -u root -p"${MARIADB_ROOT_PASSWORD}" -h127.0.0.1 -e "SHOW STATUS LIKE 'wsrep_cluster_size';" 2>&1 | grep -v "Warning" | tail -1 | awk '{print $2}' || echo "0")
    
    if [ "$CLUSTER_SIZE" == "3" ]; then
        log_info "  ✅ Cluster size: ${CLUSTER_SIZE} (expected: 3)"
    else
        log_warn "  ⚠️  Cluster size: ${CLUSTER_SIZE} (expected: 3)"
    fi
    
    # Check node status
    NODE_STATUS=$(ssh -o StrictHostKeyChecking=no root@${NODE_IP} mysql -u root -p"${MARIADB_ROOT_PASSWORD}" -h127.0.0.1 -e "SHOW STATUS LIKE 'wsrep_local_state_comment';" 2>&1 | grep -v "Warning" | tail -1 | awk '{print $2}' || echo "UNKNOWN")
    log_info "  Node status: ${NODE_STATUS}"
    
    # Check cluster UUID
    CLUSTER_UUID=$(ssh -o StrictHostKeyChecking=no root@${NODE_IP} mysql -u root -p"${MARIADB_ROOT_PASSWORD}" -h127.0.0.1 -e "SHOW STATUS LIKE 'wsrep_cluster_state_uuid';" 2>&1 | grep -v "Warning" | tail -1 | awk '{print $2}' || echo "UNKNOWN")
    log_info "  Cluster UUID: ${CLUSTER_UUID}"
    
    echo ""
done

# Check ProxySQL status
log_info "Checking ProxySQL status..."
echo ""

for i in "${!PROXYSQL_NODES[@]}"; do
    NODE_IP="${PROXYSQL_NODES[$i]}"
    NODE_NAME="${PROXYSQL_NAMES[$i]}"
    
    log_info "Checking ${NODE_NAME} (${NODE_IP})..."
    
    # Check if ProxySQL admin is listening
    if ssh -o StrictHostKeyChecking=no root@${NODE_IP} "ss -ntlp | grep :6032 > /dev/null 2>&1"; then
        log_info "  ✅ ProxySQL admin is listening on port 6032"
    else
        log_error "  ❌ ProxySQL admin is NOT listening on port 6032"
        continue
    fi
    
    # Check if ProxySQL MySQL is listening
    if ssh -o StrictHostKeyChecking=no root@${NODE_IP} "ss -ntlp | grep :6033 > /dev/null 2>&1"; then
        log_info "  ✅ ProxySQL MySQL is listening on port 6033"
    else
        log_warn "  ⚠️  ProxySQL MySQL is NOT listening on port 6033"
    fi
    
    # Check backend servers
    BACKEND_COUNT=$(ssh -o StrictHostKeyChecking=no root@${NODE_IP} mysql -h127.0.0.1 -P6032 -uadmin -padmin -e "SELECT COUNT(*) FROM mysql_servers WHERE status='ONLINE';" 2>&1 | grep -v "Warning" | tail -1 || echo "0")
    log_info "  Backend servers ONLINE: ${BACKEND_COUNT}"
    
    echo ""
done

log_info "=========================================="
log_info "Checks completed"
log_info "=========================================="

