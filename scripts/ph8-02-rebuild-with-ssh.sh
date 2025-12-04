#!/bin/bash
# PH8-02 Rebuild servers with SSH key attached
set -e

cd /opt/keybuzz/keybuzz-infra

# Load token
source /opt/keybuzz/credentials/hcloud.env
export HCLOUD_TOKEN

SSH_KEY_NAME="install-v3-keybuzz"
SSH_KEY_ID=$(hcloud ssh-key list --output columns=id,name | grep "$SSH_KEY_NAME" | awk '{print $1}')

if [ -z "$SSH_KEY_ID" ]; then
    echo "❌ SSH key '$SSH_KEY_NAME' not found"
    exit 1
fi

echo "=== Rebuilding 5 servers with SSH key $SSH_KEY_ID ==="

for name in maria-01 maria-02 maria-03 proxysql-01 proxysql-02; do
    echo "Processing $name..."
    SERVER_ID=$(hcloud server list --output columns=id,name | grep -w "$name" | awk '{print $1}')
    
    if [ -z "$SERVER_ID" ]; then
        echo "  ⚠️  Server not found, skipping..."
        continue
    fi
    
    echo "  Server ID: $SERVER_ID"
    
    # Check if SSH key is already attached
    if hcloud server describe "$SERVER_ID" --output json | jq -r '.public_net.ipv4.ip' >/dev/null 2>&1; then
        CURRENT_KEYS=$(hcloud server describe "$SERVER_ID" --output json | jq -r '.public_net.ssh_keys[].id' 2>/dev/null || echo "")
        if echo "$CURRENT_KEYS" | grep -q "$SSH_KEY_ID"; then
            echo "  ✅ SSH key already attached"
        else
            echo "  Attaching SSH key..."
            hcloud server add-ssh-key "$SERVER_ID" --ssh-key "$SSH_KEY_ID" || echo "  ⚠️  Failed to attach SSH key"
        fi
    fi
    
    # Stop server
    echo "  Stopping server..."
    hcloud server poweroff "$SERVER_ID" 2>/dev/null || true
    sleep 3
    
    # Rebuild
    echo "  Rebuilding with Ubuntu 24.04..."
    hcloud server rebuild "$SERVER_ID" --image ubuntu-24.04 || {
        echo "  ❌ Failed to rebuild $name"
        continue
    }
    
    echo "  ✅ $name rebuild OK"
    sleep 5
done

echo "✅ All servers rebuilt"

