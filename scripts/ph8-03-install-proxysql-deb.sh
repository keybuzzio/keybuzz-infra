#!/bin/bash
# PH8-03 - Install ProxySQL via .deb on Ubuntu 24.04
set -e

cd /opt/keybuzz/keybuzz-infra

PROXYSQL_VERSION="2.6.2"
DEB_URL="https://github.com/sysown/proxysql/releases/download/v${PROXYSQL_VERSION}/proxysql_${PROXYSQL_VERSION}-debian11_amd64.deb"

echo "[INFO] =========================================="
echo "[INFO] Installing ProxySQL ${PROXYSQL_VERSION} via .deb"
echo "[INFO] =========================================="
echo ""

for proxysql_ip in 10.0.0.173 10.0.0.174; do
    echo "[INFO] === Installing ProxySQL on $proxysql_ip ==="
    ssh root@$proxysql_ip bash <<INSTALL_SCRIPT
    set -e
    
    # Download ProxySQL .deb
    echo "  Downloading ProxySQL ${PROXYSQL_VERSION}..."
    wget -O /tmp/proxysql.deb "${DEB_URL}" || {
        echo "  ❌ Download failed, trying alternative URL..."
        wget -O /tmp/proxysql.deb "https://github.com/sysown/proxysql/releases/download/v${PROXYSQL_VERSION}/proxysql_${PROXYSQL_VERSION}-ubuntu20_amd64.deb" || {
            echo "  ❌ Alternative download also failed"
            exit 1
        }
    }
    
    # Install ProxySQL
    echo "  Installing ProxySQL..."
    dpkg -i /tmp/proxysql.deb || apt-get install -f -y
    
    # Enable and start ProxySQL
    echo "  Starting ProxySQL..."
    systemctl enable proxysql
    systemctl start proxysql
    
    # Wait for ProxySQL to start
    sleep 5
    
    # Check status
    if systemctl is-active --quiet proxysql; then
        echo "  ✅ ProxySQL is running"
        systemctl status proxysql --no-pager | head -10
    else
        echo "  ❌ ProxySQL failed to start"
        systemctl status proxysql --no-pager | head -20
        exit 1
    fi
INSTALL_SCRIPT
    echo ""
done

echo "[INFO] =========================================="
echo "[INFO] ✅ ProxySQL installation complete"
echo "[INFO] =========================================="

