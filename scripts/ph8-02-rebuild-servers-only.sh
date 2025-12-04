#!/bin/bash
# PH8-02 Rebuild servers only
set -e

cd /opt/keybuzz/keybuzz-infra

# Load token
source /opt/keybuzz/credentials/hcloud.env
export HCLOUD_TOKEN

SSH_KEY_NAME="install-v3-keybuzz"

echo "=== Rebuilding 5 servers ==="
for name in maria-01 maria-02 maria-03 proxysql-01 proxysql-02; do
    echo "Rebuilding $name..."
    SERVER_ID=$(hcloud server list --output columns=id,name | grep -w "$name" | awk '{print $1}')
    if [ -n "$SERVER_ID" ]; then
        hcloud server poweroff "$SERVER_ID" 2>/dev/null || true
        sleep 2
        hcloud server rebuild "$SERVER_ID" --image ubuntu-24.04 --ssh-key "$SSH_KEY_NAME"
        echo "  ✅ $name rebuild OK"
        sleep 3
    fi
done

echo "✅ All servers rebuilt"

