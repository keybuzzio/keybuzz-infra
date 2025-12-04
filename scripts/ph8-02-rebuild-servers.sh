#!/bin/bash
# PH8-02 - Rebuild MariaDB and ProxySQL servers
set -e

cd /opt/keybuzz/keybuzz-infra

echo "=== PH8-02 Rebuild MariaDB and ProxySQL Servers ==="
echo ""

# Check hcloud context
if ! hcloud context active &>/dev/null; then
    echo "⚠️  No hcloud context active. Trying to use default..."
    export HCLOUD_TOKEN="${HCLOUD_TOKEN:-}"
    if [ -z "$HCLOUD_TOKEN" ]; then
        echo "❌ HCLOUD_TOKEN not set. Please set it or activate a context."
        exit 1
    fi
fi

# Step 1: Get server IDs
echo "Step 1: Identifying servers..."
SERVERS=$(hcloud server list --output columns=id,name,ipv4 2>&1 | grep -E "(maria-|proxysql-)" || true)

if [ -z "$SERVERS" ]; then
    echo "⚠️  No servers found via hcloud. Continuing with manual IPs..."
    SERVERS=""
fi

echo "Found servers:"
echo "$SERVERS"
echo ""

# Function to rebuild a server
rebuild_server() {
    local SERVER_NAME=$1
    local VOLUME_SIZE=$2
    local VOLUME_NAME="${SERVER_NAME}-data"
    
    echo "=== Rebuilding $SERVER_NAME ==="
    
    # Get server ID
    SERVER_ID=$(hcloud server list --output columns=id,name | grep "$SERVER_NAME" | awk '{print $1}' || echo "")
    if [ -z "$SERVER_ID" ]; then
        echo "❌ Server $SERVER_NAME not found"
        return 1
    fi
    
    echo "Server ID: $SERVER_ID"
    
    # Stop server
    echo "Stopping server..."
    hcloud server poweroff "$SERVER_ID" || true
    sleep 5
    
    # Get volume ID if exists
    VOLUME_ID=$(hcloud volume list --output columns=id,name | grep "$VOLUME_NAME" | awk '{print $1}' || echo "")
    
    if [ -n "$VOLUME_ID" ]; then
        echo "Detaching volume $VOLUME_ID..."
        hcloud server detach-volume "$SERVER_ID" --volume "$VOLUME_ID" || true
        sleep 2
        
        echo "Deleting volume $VOLUME_ID..."
        hcloud volume delete "$VOLUME_ID" || true
        sleep 2
    fi
    
    # Create new volume
    echo "Creating new volume $VOLUME_NAME (${VOLUME_SIZE}GB)..."
    VOLUME_ID=$(hcloud volume create --name "$VOLUME_NAME" --size "$VOLUME_SIZE" --format json | jq -r '.id' || echo "")
    
    if [ -z "$VOLUME_ID" ] || [ "$VOLUME_ID" = "null" ]; then
        echo "❌ Failed to create volume"
        return 1
    fi
    
    echo "Volume created: $VOLUME_ID"
    
    # Rebuild server
    echo "Rebuilding server with Ubuntu 24.04..."
    hcloud server rebuild "$SERVER_ID" --image ubuntu-24.04 || {
        echo "❌ Failed to rebuild server"
        return 1
    }
    
    sleep 5
    
    # Attach volume
    echo "Attaching volume..."
    hcloud server attach-volume "$SERVER_ID" --volume "$VOLUME_ID" || {
        echo "❌ Failed to attach volume"
        return 1
    }
    
    sleep 3
    
    # Start server
    echo "Starting server..."
    hcloud server poweron "$SERVER_ID" || true
    sleep 10
    
    # Wait for SSH
    echo "Waiting for SSH..."
    SERVER_IP=$(hcloud server list --output columns=id,name,ipv4 | grep "$SERVER_NAME" | awk '{print $3}' || echo "")
    
    if [ -z "$SERVER_IP" ]; then
        echo "❌ Could not get server IP"
        return 1
    fi
    
    for i in {1..60}; do
        if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$SERVER_IP "echo OK" 2>/dev/null; then
            echo "✅ SSH is ready"
            break
        fi
        sleep 2
    done
    
    echo "✅ $SERVER_NAME rebuilt successfully"
    echo ""
}

# Rebuild MariaDB servers
echo "Step 2: Rebuilding MariaDB servers..."
rebuild_server "maria-01" "50"
rebuild_server "maria-02" "50"
rebuild_server "maria-03" "50"

# Rebuild ProxySQL servers
echo "Step 3: Rebuilding ProxySQL servers..."
rebuild_server "proxysql-01" "20"
rebuild_server "proxysql-02" "20"

echo "=== All servers rebuilt ==="

