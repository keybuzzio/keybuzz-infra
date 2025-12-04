#!/bin/bash
# PH8-02 - Complete Rebuild Process
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== PH8-02 Complete Rebuild Process ==="
echo ""

# Step 1: Rebuild servers
echo "Step 1: Rebuilding servers..."
bash scripts/ph8-02-rebuild-servers.sh 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-rebuild-servers.log

# Step 2: Format and mount volumes
echo ""
echo "Step 2: Formatting and mounting volumes..."
bash scripts/ph8-02-format-volumes.sh 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-format-volumes.log

# Step 3: Deploy SSH keys
echo ""
echo "Step 3: Deploying SSH keys..."
bash scripts/ph8-02-deploy-ssh-keys.sh 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-deploy-ssh-keys.log

# Step 4: Verify SSH mesh
echo ""
echo "Step 4: Verifying SSH mesh..."
ansible all -m ping -i ansible/inventory/hosts.yml --limit "maria-01,maria-02,maria-03,proxysql-01,proxysql-02" 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-ssh-mesh.log

# Step 5: Deploy MariaDB Galera
echo ""
echo "Step 5: Deploying MariaDB Galera..."
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/mariadb_galera_v3.yml --limit "maria-01,maria-02,maria-03" 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-mariadb-deploy.log

# Step 6: Bootstrap Galera cluster
echo ""
echo "Step 6: Bootstrapping Galera cluster..."
echo "Bootstraping maria-02..."
scp scripts/mariadb_bootstrap_direct.sh root@10.0.0.171:/root/
ssh root@10.0.0.171 "chmod +x /root/mariadb_bootstrap_direct.sh && bash /root/mariadb_bootstrap_direct.sh" 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-mariadb-bootstrap.log

sleep 10

echo "Joining maria-01..."
bash scripts/ph8-01-join-node.sh 10.0.0.170 2>&1 | tee -a /opt/keybuzz/logs/phase8/ph8-02-mariadb-bootstrap.log

sleep 10

echo "Joining maria-03..."
bash scripts/ph8-01-join-node.sh 10.0.0.172 2>&1 | tee -a /opt/keybuzz/logs/phase8/ph8-02-mariadb-bootstrap.log

# Step 7: Verify cluster
echo ""
echo "Step 7: Verifying cluster..."
sleep 15
bash scripts/ph8-01-check-cluster.sh 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-cluster-verify.log

# Step 8: Deploy ProxySQL
echo ""
echo "Step 8: Deploying ProxySQL..."
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/proxysql_v3.yml --limit "proxysql-01,proxysql-02" 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-proxysql-deploy.log

# Step 9: End-to-end tests
echo ""
echo "Step 9: Running end-to-end tests..."
bash scripts/mariadb_ha_end_to_end.sh 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-e2e-tests.log

echo ""
echo "=== Rebuild process completed ==="

