#!/bin/bash
# PH8-02 - Wait for servers and deploy
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== PH8-02 Wait and Deploy ==="
echo ""

# Clean known_hosts
for ip in 10.0.0.170 10.0.0.171 10.0.0.172 10.0.0.173 10.0.0.174; do
    ssh-keygen -f ~/.ssh/known_hosts -R $ip 2>/dev/null || true
done

# Wait for servers to be ready (cloud-init may still be running)
echo "Waiting for servers to be ready (checking every 10 seconds, max 5 minutes)..."
MAX_ATTEMPTS=30
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    READY_COUNT=0
    for ip in 10.0.0.170 10.0.0.171 10.0.0.172 10.0.0.173 10.0.0.174; do
        if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes root@$ip "echo OK" 2>/dev/null | grep -q "OK"; then
            READY_COUNT=$((READY_COUNT + 1))
        fi
    done
    
    if [ $READY_COUNT -eq 5 ]; then
        echo "✅ All 5 servers are accessible!"
        break
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
    echo "Attempt $ATTEMPT/$MAX_ATTEMPTS: $READY_COUNT/5 servers accessible..."
    sleep 10
done

if [ $READY_COUNT -lt 5 ]; then
    echo "⚠️  Only $READY_COUNT/5 servers are accessible. Continuing anyway..."
fi

echo ""
echo "Starting deployment..."
bash scripts/ph8-02-complete-deployment.sh 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-complete-deployment-final.log

