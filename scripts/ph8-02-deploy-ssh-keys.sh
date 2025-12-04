#!/bin/bash
# PH8-02 - Deploy SSH keys
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== PH8-02 Deploy SSH Keys ==="
echo ""

SSH_KEY_PATH="$HOME/.ssh/id_rsa_keybuzz_v3.pub"

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "❌ SSH key not found at $SSH_KEY_PATH"
    exit 1
fi

SSH_PUBLIC_KEY=$(cat "$SSH_KEY_PATH")

# Function to deploy SSH key
deploy_key() {
    local SERVER_IP=$1
    local SERVER_NAME=$2
    
    echo "Deploying SSH key to $SERVER_NAME ($SERVER_IP)..."
    
    ssh -o StrictHostKeyChecking=no root@$SERVER_IP bash <<EOF
set -e

# Add key to authorized_keys if not present
if ! grep -q "$SSH_PUBLIC_KEY" ~/.ssh/authorized_keys 2>/dev/null; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    echo "$SSH_PUBLIC_KEY" >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    echo "✅ SSH key added"
else
    echo "✅ SSH key already present"
fi
EOF

    echo "✅ $SERVER_NAME SSH key deployed"
    echo ""
}

# Deploy to all servers
deploy_key "10.0.0.170" "maria-01"
deploy_key "10.0.0.171" "maria-02"
deploy_key "10.0.0.172" "maria-03"
deploy_key "10.0.0.173" "proxysql-01"
deploy_key "10.0.0.174" "proxysql-02"

echo "=== All SSH keys deployed ==="

