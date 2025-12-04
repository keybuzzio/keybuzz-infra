#!/bin/bash
# PH8-02 Attach SSH keys and wait for servers
set -e

cd /opt/keybuzz/keybuzz-infra

source /opt/keybuzz/credentials/hcloud.env
export HCLOUD_TOKEN

SSH_KEY_NAME="install-v3-keybuzz"
SSH_KEY_ID=$(hcloud ssh-key list --output columns=id,name | grep "$SSH_KEY_NAME" | awk '{print $1}')

echo "=== Attaching SSH key $SSH_KEY_ID to servers ==="

for name in maria-01 maria-02 maria-03 proxysql-01 proxysql-02; do
    SERVER_ID=$(hcloud server list --output columns=id,name | grep -w "$name" | awk '{print $1}')
    if [ -n "$SERVER_ID" ]; then
        echo "Attaching SSH key to $name ($SERVER_ID)..."
        hcloud server attach-ssh-key "$SERVER_ID" "$SSH_KEY_ID" 2>&1 || echo "  (may already be attached)"
    fi
done

echo ""
echo "Waiting for servers to be ready (max 5 minutes)..."
sleep 30

for i in {1..60}; do
    READY=0
    for ip in 10.0.0.170 10.0.0.171 10.0.0.172 10.0.0.173 10.0.0.174; do
        ssh-keygen -f ~/.ssh/known_hosts -R $ip 2>/dev/null || true
        if ssh -i /root/.ssh/id_rsa_keybuzz_v3 -o StrictHostKeyChecking=no -o ConnectTimeout=3 root@$ip "echo OK" 2>/dev/null | grep -q OK; then
            READY=$((READY+1))
        fi
    done
    
    if [ $READY -eq 5 ]; then
        echo "✅ All 5 servers ready!"
        break
    fi
    
    echo "Attempt $i: $READY/5 servers ready..."
    sleep 5
done

if [ $READY -lt 5 ]; then
    echo "⚠️  Only $READY/5 servers ready"
fi

