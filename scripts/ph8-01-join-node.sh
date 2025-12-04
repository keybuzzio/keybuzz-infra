#!/bin/bash
# Join a MariaDB node to the Galera cluster
set -e

NODE_IP="${1:-}"
if [ -z "$NODE_IP" ]; then
    echo "Usage: $0 <node_ip>"
    exit 1
fi

echo "Joining $NODE_IP to cluster..."

ssh root@${NODE_IP} bash <<'JOIN'
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
sleep 25

echo "Waiting for MariaDB to be ready..."
for i in {1..30}; do
    if mysql -u root -e "SELECT 1;" > /dev/null 2>&1; then
        echo "✅ MariaDB is ready!"
        break
    fi
    sleep 2
done

echo "Checking cluster status..."
mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size';" 2>&1 || echo "Not connected yet"
mysql -u root -e "SHOW STATUS LIKE 'wsrep_local_state_comment';" 2>&1 || echo "Not connected yet"
JOIN

echo "✅ Node $NODE_IP joined successfully"

