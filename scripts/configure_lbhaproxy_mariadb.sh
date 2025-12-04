#!/bin/bash
# PH8-03 - Configure Hetzner Load Balancer for MariaDB (10.0.0.10:3306)
set -e

cd /opt/keybuzz/keybuzz-infra

LB_NAME="lb-haproxy"
LB_PORT="3306"
TARGET_PORT="3306"
PROTOCOL="tcp"

echo "[INFO] =========================================="
echo "[INFO] Configuring Hetzner LB for MariaDB"
echo "[INFO] =========================================="
echo "[INFO] LB Name: ${LB_NAME}"
echo "[INFO] Listen Port: ${LB_PORT}"
echo "[INFO] Target Port: ${TARGET_PORT}"
echo "[INFO] Protocol: ${PROTOCOL}"
echo ""

# Check if hcloud is available
if ! command -v hcloud &> /dev/null; then
    echo "[ERROR] hcloud CLI not found. Please install it first."
    exit 1
fi

# Check if HCLOUD_TOKEN is set
if [ -z "$HCLOUD_TOKEN" ]; then
    echo "[WARN] HCLOUD_TOKEN not set. Trying to load from /opt/keybuzz/credentials/hcloud.env"
    if [ -f /opt/keybuzz/credentials/hcloud.env ]; then
        source /opt/keybuzz/credentials/hcloud.env
    else
        echo "[ERROR] HCLOUD_TOKEN not found. Please set it or create /opt/keybuzz/credentials/hcloud.env"
        exit 1
    fi
fi

# Add service if it doesn't exist
echo "[INFO] Adding service ${LB_PORT}..."
hcloud load-balancer add-service ${LB_NAME} \
    --listen-port ${LB_PORT} \
    --destination-port ${TARGET_PORT} \
    --protocol ${PROTOCOL} 2>&1 || echo "[WARN] Service may already exist"

# Get HAProxy server IPs
HAPROXY_01_IP="10.0.0.11"
HAPROXY_02_IP="10.0.0.12"

echo ""
echo "[INFO] Adding targets..."
echo "[INFO]   haproxy-01: ${HAPROXY_01_IP}"
hcloud load-balancer add-target ${LB_NAME} \
    --type server \
    --server haproxy-01 2>&1 || echo "[WARN] Target may already exist"

echo "[INFO]   haproxy-02: ${HAPROXY_02_IP}"
hcloud load-balancer add-target ${LB_NAME} \
    --type server \
    --server haproxy-02 2>&1 || echo "[WARN] Target may already exist"

echo ""
echo "[INFO] Verifying LB configuration..."
hcloud load-balancer describe ${LB_NAME} --output json | jq -r '.services[] | select(.listen_port == '${LB_PORT}') | "Service: \(.listen_port) -> \(.destination_port) (\(.protocol))"'

echo ""
echo "[INFO] ✅ LB configuration complete!"
echo "[INFO] MariaDB endpoint: mysql://root:<pwd>@${LB_NAME}:${LB_PORT}/<db>"
echo ""

