#!/bin/bash
# PH8-03 - Manual HAProxy MariaDB deployment
set -e

cd /opt/keybuzz/keybuzz-infra

echo "[INFO] =========================================="
echo "[INFO] Manual HAProxy MariaDB Deployment"
echo "[INFO] =========================================="
echo ""

HAPROXY_CONFIG="# MariaDB Galera Cluster - Port 3306
listen mariadb
    mode tcp
    bind *:3306
    balance roundrobin
    option tcp-check
    tcp-check connect port 3306
    timeout client  1m
    timeout server  1m
    timeout connect 5s
    server maria-01 10.0.0.170:3306 check inter 2000 fall 2 rise 2
    server maria-02 10.0.0.171:3306 check inter 2000 fall 2 rise 2
    server maria-03 10.0.0.172:3306 check inter 2000 fall 2 rise 2"

for haproxy_ip in 10.0.0.11 10.0.0.12; do
    echo "[INFO] === Deploying HAProxy on $haproxy_ip ==="
    ssh root@$haproxy_ip bash <<DEPLOY_SCRIPT
    set -e
    
    # Install HAProxy if not installed
    if ! command -v haproxy &> /dev/null; then
        echo "  Installing HAProxy..."
        apt-get update
        apt-get install -y haproxy
    fi
    
    # Add MariaDB configuration to haproxy.cfg
    echo "  Adding MariaDB configuration..."
    if ! grep -q "ANSIBLE MANAGED BLOCK FOR MARIADB GALERA HA" /etc/haproxy/haproxy.cfg 2>/dev/null; then
        echo "" >> /etc/haproxy/haproxy.cfg
        echo "# ANSIBLE MANAGED BLOCK FOR MARIADB GALERA HA" >> /etc/haproxy/haproxy.cfg
        echo "$HAPROXY_CONFIG" >> /etc/haproxy/haproxy.cfg
    else
        echo "  Configuration already exists"
    fi
    
    # Validate configuration
    echo "  Validating HAProxy configuration..."
    haproxy -c -f /etc/haproxy/haproxy.cfg
    
    # Restart HAProxy
    echo "  Restarting HAProxy..."
    systemctl restart haproxy
    systemctl enable haproxy
    
    # Wait for HAProxy to start
    sleep 3
    
    # Check status
    if systemctl is-active --quiet haproxy; then
        echo "  ✅ HAProxy is running"
    else
        echo "  ❌ HAProxy failed to start"
        systemctl status haproxy --no-pager | head -10
        exit 1
    fi
    
    # Verify port 3306 is listening
    if ss -ntlp | grep -q 3306; then
        echo "  ✅ Port 3306 is listening"
        ss -ntlp | grep 3306
    else
        echo "  ⚠️  Port 3306 not listening"
    fi
DEPLOY_SCRIPT
    echo ""
done

echo "[INFO] =========================================="
echo "[INFO] ✅ HAProxy deployment complete"
echo "[INFO] =========================================="

