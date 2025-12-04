#!/bin/bash
# Bootstrap MariaDB Galera Cluster
# Execute on maria-01 first, then maria-02 and maria-03

set -euo pipefail

NODE_IP="${1:-}"
IS_FIRST_NODE="${2:-false}"

if [ -z "$NODE_IP" ]; then
    echo "Usage: $0 <node_ip> <is_first_node>"
    exit 1
fi

echo "Bootstraping MariaDB Galera on $NODE_IP (first_node=$IS_FIRST_NODE)"

ssh root@${NODE_IP} bash <<EOF
set -e

DATA_DIR="/data/mariadb/data"
LOG_DIR="/data/mariadb/logs"

# Stop MariaDB
systemctl stop mariadb || true
sleep 2

# Clean data if first node
if [ "$IS_FIRST_NODE" = "true" ]; then
    echo "Cleaning data directory for bootstrap..."
    rm -rf \${DATA_DIR}/*
    rm -rf \${DATA_DIR}/.* || true
    
    # Initialize MariaDB
    echo "Initializing MariaDB..."
    mysqld --initialize-insecure --datadir=\${DATA_DIR} --user=mysql 2>&1 | tail -5
    
    # Set permissions
    chown -R mysql:mysql \${DATA_DIR}
    chown -R mysql:mysql \${LOG_DIR} || true
    
    # Start with bootstrap
    echo "Starting MariaDB with bootstrap..."
    systemctl start mariadb@bootstrap || systemctl start mariadb
else
    echo "Starting MariaDB to join cluster..."
    systemctl start mariadb
fi

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
for i in {1..30}; do
    if mysql -u root -e "SELECT 1;" > /dev/null 2>&1; then
        echo "MariaDB is ready!"
        break
    fi
    sleep 2
done

# Check cluster status
echo "Checking cluster status..."
mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size';" 2>&1 || echo "Not connected to cluster yet"

EOF

echo "Bootstrap completed for $NODE_IP"

