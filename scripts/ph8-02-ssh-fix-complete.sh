#!/bin/bash
# PH8-02 SSH Fix and Complete Deployment
set -e

cd /opt/keybuzz/keybuzz-infra

# Load Hetzner token from credentials file
ENV_FILE="/opt/keybuzz/credentials/hcloud.env"
if [ -f "${ENV_FILE}" ]; then
    echo "Loading Hetzner token from ${ENV_FILE}..."
    source "${ENV_FILE}"
    export HCLOUD_TOKEN
    echo "✅ Token loaded"
else
    echo "⚠️  Token file not found: ${ENV_FILE}"
    echo "Trying to use hcloud context..."
    hcloud context use default 2>/dev/null || true
fi

echo "=== PH8-02 SSH Fix and Complete Deployment ==="
echo ""

# Step 1: Get public key
echo "Step 1: Getting install-v3 public key..."
PUBKEY=$(cat /root/.ssh/id_rsa_keybuzz_v3.pub)

if [ -z "$PUBKEY" ]; then
    echo "❌ Public key not found at /root/.ssh/id_rsa_keybuzz_v3.pub"
    exit 1
fi

echo "✅ Public key retrieved"
echo ""

# Step 2: Create/verify Hetzner SSH key
echo "Step 2: Creating/verifying Hetzner SSH key..."
SSH_KEY_NAME="install-v3-keybuzz"

if hcloud ssh-key list --output columns=id,name | grep -q "$SSH_KEY_NAME"; then
    echo "✅ SSH key '$SSH_KEY_NAME' already exists"
else
    echo "Creating SSH key '$SSH_KEY_NAME'..."
    hcloud ssh-key create --name "$SSH_KEY_NAME" --public-key "$PUBKEY" || {
        echo "❌ Failed to create SSH key"
        exit 1
    }
    echo "✅ SSH key created"
fi
echo ""

# Step 3: Get server IDs and rebuild
echo "Step 3: Rebuilding servers with SSH key..."
SERVERS=("maria-01:10.0.0.170" "maria-02:10.0.0.171" "maria-03:10.0.0.172" "proxysql-01:10.0.0.173" "proxysql-02:10.0.0.174")

for server in "${SERVERS[@]}"; do
    IFS=':' read -r NAME IP <<< "$server"
    echo "Processing $NAME ($IP)..."
    
    # Get server ID
    SERVER_ID=$(hcloud server list --output columns=id,name | grep -w "$NAME" | awk '{print $1}' || echo "")
    
    if [ -z "$SERVER_ID" ]; then
        echo "  ⚠️  Server $NAME not found, skipping..."
        continue
    fi
    
    echo "  Server ID: $SERVER_ID"
    
    # Stop server if running
    echo "  Stopping server..."
    hcloud server poweroff "$SERVER_ID" 2>/dev/null || true
    sleep 3
    
    # Rebuild with SSH key
    echo "  Rebuilding with Ubuntu 24.04 and SSH key..."
    hcloud server rebuild "$SERVER_ID" --image ubuntu-24.04 --ssh-key "$SSH_KEY_NAME" || {
        echo "  ❌ Failed to rebuild $NAME"
        continue
    }
    
    echo "  ✅ $NAME rebuild initiated"
    sleep 5
done

echo ""
echo "Step 4: Waiting for servers to be ready..."
sleep 30

# Wait for SSH on all servers
MAX_ATTEMPTS=60
for server in "${SERVERS[@]}"; do
    IFS=':' read -r NAME IP <<< "$server"
    echo "Waiting for $NAME ($IP)..."
    
    ATTEMPT=0
    while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        # Check ping
        if ping -c 1 -W 2 $IP >/dev/null 2>&1; then
            # Check SSH port
            if nc -zv -w 2 $IP 22 >/dev/null 2>&1; then
                # Try SSH connection
                if ssh -i /root/.ssh/id_rsa_keybuzz_v3 -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$IP "echo 'SSH_OK'" >/dev/null 2>&1; then
                    echo "  ✅ $NAME is ready (SSH OK)"
                    break
                fi
            fi
        fi
        
        ATTEMPT=$((ATTEMPT + 1))
        if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
            sleep 5
        fi
    done
    
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        echo "  ⚠️  $NAME not ready after $MAX_ATTEMPTS attempts"
    fi
done

echo ""
echo "Step 5: Verifying SSH connectivity..."
# Clean known_hosts
for server in "${SERVERS[@]}"; do
    IFS=':' read -r NAME IP <<< "$server"
    ssh-keygen -f ~/.ssh/known_hosts -R $IP 2>/dev/null || true
done

# Verify SSH
ALL_OK=true
for server in "${SERVERS[@]}"; do
    IFS=':' read -r NAME IP <<< "$server"
    if ssh -i /root/.ssh/id_rsa_keybuzz_v3 -o StrictHostKeyChecking=no root@$IP "echo 'OK-$NAME'" >/dev/null 2>&1; then
        echo "  ✅ $NAME: SSH OK"
    else
        echo "  ❌ $NAME: SSH FAILED"
        ALL_OK=false
    fi
done

if [ "$ALL_OK" != "true" ]; then
    echo "⚠️  Some servers are not accessible via SSH"
    echo "Continuing anyway..."
fi

echo ""
echo "Step 6: Starting complete deployment..."
bash scripts/ph8-02-complete-deployment.sh 2>&1 | tee /opt/keybuzz/logs/phase8/ph8-02-complete-deployment-after-ssh-fix.log

echo ""
echo "=== SSH Fix and Deployment completed ==="

