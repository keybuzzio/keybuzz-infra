#!/bin/bash
# PH8-02 - Simple Rebuild (reconfigure existing servers)
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== PH8-02 Simple Rebuild Process ==="
echo ""

# Step 1: Check server accessibility
echo "Step 1: Checking server accessibility..."
MARIA_SERVERS=("10.0.0.170:maria-01" "10.0.0.171:maria-02" "10.0.0.172:maria-03")
PROXYSQL_SERVERS=("10.0.0.173:proxysql-01" "10.0.0.174:proxysql-02")

for server in "${MARIA_SERVERS[@]}" "${PROXYSQL_SERVERS[@]}"; do
    IFS=':' read -r IP NAME <<< "$server"
    echo "Checking $NAME ($IP)..."
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$IP "echo OK" 2>/dev/null; then
        echo "  ✅ $NAME is accessible"
    else
        echo "  ⚠️  $NAME is NOT accessible - will skip"
    fi
done

echo ""
echo "Step 2: Formatting and mounting volumes..."
bash scripts/ph8-02-format-volumes.sh 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-format-volumes.log

echo ""
echo "Step 3: Deploying SSH keys..."
bash scripts/ph8-02-deploy-ssh-keys.sh 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-deploy-ssh-keys.log

echo ""
echo "Step 4: Verifying SSH mesh..."
ansible all -m ping -i ansible/inventory/hosts.yml --limit "maria-01,maria-02,maria-03,proxysql-01,proxysql-02" 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-ssh-mesh.log

echo ""
echo "Step 5: Deploying MariaDB Galera..."
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/mariadb_galera_v3.yml --limit "maria-01,maria-02,maria-03" 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-mariadb-deploy.log

echo ""
echo "Step 6: Bootstrapping Galera cluster..."
echo "Bootstraping maria-02..."
scp scripts/mariadb_bootstrap_direct.sh root@10.0.0.171:/root/ 2>&1 || echo "⚠️  Could not copy bootstrap script"
ssh root@10.0.0.171 "chmod +x /root/mariadb_bootstrap_direct.sh && bash /root/mariadb_bootstrap_direct.sh" 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-mariadb-bootstrap.log

sleep 15

echo "Joining maria-01..."
bash scripts/ph8-01-join-node.sh 10.0.0.170 2>&1 | tee -a /opt/keybuzz/logs/phase8/ph8-02-mariadb-bootstrap.log || echo "⚠️  maria-01 join failed"

sleep 15

echo "Joining maria-03..."
bash scripts/ph8-01-join-node.sh 10.0.0.172 2>&1 | tee -a /opt/keybuzz/logs/phase8/ph8-02-mariadb-bootstrap.log || echo "⚠️  maria-03 join failed"

echo ""
echo "Step 7: Verifying cluster..."
sleep 20
bash scripts/ph8-01-check-cluster.sh 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-cluster-verify.log

echo ""
echo "Step 8: Deploying ProxySQL..."
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/proxysql_v3.yml --limit "proxysql-01,proxysql-02" 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-proxysql-deploy.log

echo ""
echo "Step 9: Running end-to-end tests..."
bash scripts/mariadb_ha_end_to_end.sh 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-e2e-tests.log

echo ""
echo "=== Rebuild process completed ==="

