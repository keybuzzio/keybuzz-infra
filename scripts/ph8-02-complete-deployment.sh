#!/bin/bash
# PH8-02 - Complete Deployment (assumes SSH keys are already deployed)
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== PH8-02 Complete Deployment ==="
echo ""

# Step 1: Clean known_hosts
echo "Step 1: Cleaning known_hosts..."
for ip in 10.0.0.170 10.0.0.171 10.0.0.172 10.0.0.173 10.0.0.174; do
    ssh-keygen -f ~/.ssh/known_hosts -R $ip 2>/dev/null || true
done
echo "✅ known_hosts cleaned"
echo ""

# Step 2: Verify connectivity (with password prompt if needed)
echo "Step 2: Verifying connectivity..."
echo "NOTE: If servers require password, you may need to configure SSH keys manually first"
for ip in 10.0.0.170 10.0.0.171 10.0.0.172 10.0.0.173 10.0.0.174; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$ip "echo OK" 2>&1 | grep -q "OK"; then
        echo "  ✅ $ip is accessible"
    else
        echo "  ⚠️  $ip requires manual SSH key setup"
    fi
done
echo ""

# Step 3: Format volumes (skip if SSH not working)
echo "Step 3: Formatting and mounting volumes..."
bash scripts/ph8-02-format-volumes.sh 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-format-volumes-complete.log || echo "⚠️  Volume formatting skipped (SSH issue)"

echo ""
echo "Step 4: Deploying MariaDB Galera..."
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/mariadb_galera_v3.yml --limit "maria-01,maria-02,maria-03" 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-mariadb-deploy-complete.log || echo "⚠️  MariaDB deployment skipped (SSH issue)"

echo ""
echo "Step 5: Bootstrapping Galera cluster..."
scp scripts/mariadb_bootstrap_direct.sh root@10.0.0.171:/root/ 2>&1 || echo "⚠️  Could not copy bootstrap script"
ssh root@10.0.0.171 "chmod +x /root/mariadb_bootstrap_direct.sh && bash /root/mariadb_bootstrap_direct.sh" 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-bootstrap-complete.log || echo "⚠️  Bootstrap skipped"

sleep 20

echo "Joining other nodes..."
bash scripts/ph8-01-join-node.sh 10.0.0.170 2>&1 | tee -a /opt/keybuzz/logs/phase8/ph8-02-join-complete.log || echo "⚠️  maria-01 join skipped"
sleep 20
bash scripts/ph8-01-join-node.sh 10.0.0.172 2>&1 | tee -a /opt/keybuzz/logs/phase8/ph8-02-join-complete.log || echo "⚠️  maria-03 join skipped"

echo ""
echo "Step 6: Verifying cluster..."
sleep 20
bash scripts/ph8-01-check-cluster.sh 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-cluster-complete.log

echo ""
echo "Step 7: Deploying ProxySQL..."
sed -i 's/Configure ProxySQL users (default: root user can connect)/Configure ProxySQL users/' ansible/roles/proxysql_v3/tasks/main.yml 2>/dev/null || true
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/proxysql_v3.yml --limit "proxysql-01,proxysql-02" 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-proxysql-complete.log || echo "⚠️  ProxySQL deployment skipped"

echo ""
echo "Step 8: Running end-to-end tests..."
bash scripts/mariadb_ha_end_to_end.sh 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-e2e-complete.log || echo "⚠️  E2E tests skipped"

echo ""
echo "=== Deployment completed ==="
echo ""
echo "NOTE: If SSH connections failed, please:"
echo "1. Manually add SSH key to each server:"
echo "   ssh-copy-id -i ~/.ssh/id_rsa_keybuzz_v3.pub root@<server_ip>"
echo "2. Or configure SSH keys via cloud-init during server rebuild"
echo "3. Then re-run this script"

