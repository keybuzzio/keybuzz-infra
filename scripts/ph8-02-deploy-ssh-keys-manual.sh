#!/bin/bash
# PH8-02 - Deploy SSH keys manually (requires password on first connection)
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== PH8-02 Deploy SSH Keys Manually ==="
echo ""
echo "This script will deploy SSH keys to all servers."
echo "You may be prompted for passwords on first connection."
echo ""

SSH_KEY_PATH="$HOME/.ssh/id_rsa_keybuzz_v3.pub"

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "❌ SSH key not found at $SSH_KEY_PATH"
    exit 1
fi

# Clean known_hosts first
for ip in 10.0.0.170 10.0.0.171 10.0.0.172 10.0.0.173 10.0.0.174; do
    ssh-keygen -f ~/.ssh/known_hosts -R $ip 2>/dev/null || true
done

# Deploy keys using ssh-copy-id
for server in "10.0.0.170:maria-01" "10.0.0.171:maria-02" "10.0.0.172:maria-03" "10.0.0.173:proxysql-01" "10.0.0.174:proxysql-02"; do
    IFS=':' read -r IP NAME <<< "$server"
    echo "Deploying SSH key to $NAME ($IP)..."
    
    if ssh-copy-id -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no root@$IP 2>&1; then
        echo "✅ SSH key deployed to $NAME"
    else
        echo "⚠️  Failed to deploy SSH key to $NAME (may require password)"
    fi
done

echo ""
echo "Verifying SSH connectivity..."
ansible all -m ping -i ansible/inventory/hosts.yml --limit "maria-01,maria-02,maria-03,proxysql-01,proxysql-02" 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-ssh-verify-manual.log

echo ""
echo "=== SSH key deployment completed ==="

