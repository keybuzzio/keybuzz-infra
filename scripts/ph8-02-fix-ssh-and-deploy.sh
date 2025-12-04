#!/bin/bash
# PH8-02 - Fix SSH known_hosts and deploy keys
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== PH8-02 Fix SSH and Deploy ==="
echo ""

# Step 1: Clean known_hosts
echo "Step 1: Cleaning known_hosts..."
for ip in 10.0.0.170 10.0.0.171 10.0.0.172 10.0.0.173 10.0.0.174; do
    ssh-keygen -f ~/.ssh/known_hosts -R $ip 2>/dev/null || true
done
echo "✅ known_hosts cleaned"
echo ""

# Step 2: Deploy SSH keys
echo "Step 2: Deploying SSH keys..."
SSH_KEY_PATH="$HOME/.ssh/id_rsa_keybuzz_v3.pub"

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "❌ SSH key not found at $SSH_KEY_PATH"
    exit 1
fi

SSH_PUBLIC_KEY=$(cat "$SSH_KEY_PATH")

for server in "10.0.0.170:maria-01" "10.0.0.171:maria-02" "10.0.0.172:maria-03" "10.0.0.173:proxysql-01" "10.0.0.174:proxysql-02"; do
    IFS=':' read -r IP NAME <<< "$server"
    echo "Deploying SSH key to $NAME ($IP)..."
    
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$IP bash <<EOF
set -e
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "$SSH_PUBLIC_KEY" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
echo "✅ SSH key added to $NAME"
EOF
    
    echo "✅ $NAME SSH key deployed"
done

echo ""
echo "Step 3: Verifying SSH connectivity..."
ansible all -m ping -i ansible/inventory/hosts.yml --limit "maria-01,maria-02,maria-03,proxysql-01,proxysql-02" 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-ssh-verify.log

echo ""
echo "=== SSH setup completed ==="

