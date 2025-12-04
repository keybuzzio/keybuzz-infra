#!/bin/bash
# PH8-02 Execute Step by Step
set -e

cd /opt/keybuzz/keybuzz-infra

# Load token
ENV_FILE="/opt/keybuzz/credentials/hcloud.env"
if [ -f "${ENV_FILE}" ]; then
    source "${ENV_FILE}"
    export HCLOUD_TOKEN
fi

echo "=== PH8-02 Step by Step Execution ==="
echo ""

# Step 1: Create SSH key
echo "Step 1: Creating Hetzner SSH key..."
PUBKEY=$(cat /root/.ssh/id_rsa_keybuzz_v3.pub)
SSH_KEY_NAME="install-v3-keybuzz"

if hcloud ssh-key list 2>/dev/null | grep -q "$SSH_KEY_NAME"; then
    echo "✅ SSH key exists"
else
    hcloud ssh-key create --name "$SSH_KEY_NAME" --public-key "$PUBKEY" && echo "✅ SSH key created" || echo "❌ Failed"
fi

# Step 2: Rebuild servers
echo ""
echo "Step 2: Rebuilding servers..."
for name in maria-01 maria-02 maria-03 proxysql-01 proxysql-02; do
    echo "Rebuilding $name..."
    SERVER_ID=$(hcloud server list --output columns=id,name | grep -w "$name" | awk '{print $1}')
    if [ -n "$SERVER_ID" ]; then
        hcloud server poweroff "$SERVER_ID" 2>/dev/null || true
        sleep 2
        hcloud server rebuild "$SERVER_ID" --image ubuntu-24.04 --ssh-key "$SSH_KEY_NAME" && echo "  ✅ $name rebuild OK" || echo "  ❌ $name rebuild FAILED"
        sleep 3
    fi
done

# Step 3: Wait and verify SSH
echo ""
echo "Step 3: Waiting for SSH..."
sleep 60

for ip in 10.0.0.170 10.0.0.171 10.0.0.172 10.0.0.173 10.0.0.174; do
    ssh-keygen -f ~/.ssh/known_hosts -R $ip 2>/dev/null || true
    for i in {1..30}; do
        if ssh -i /root/.ssh/id_rsa_keybuzz_v3 -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$ip "echo OK" 2>/dev/null | grep -q OK; then
            echo "  ✅ $ip SSH OK"
            break
        fi
        sleep 5
    done
done

# Step 4: Deploy
echo ""
echo "Step 4: Starting deployment..."
bash scripts/ph8-02-complete-deployment.sh

echo ""
echo "=== Execution completed ==="

