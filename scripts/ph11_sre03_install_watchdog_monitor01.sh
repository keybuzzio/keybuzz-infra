#!/bin/bash
#
# PH11-SRE-03: Install KeyBuzz Watchdog on monitor-01
# ===================================================
# This script is idempotent - safe to run multiple times.
# Run from install-v3: bash /opt/keybuzz/keybuzz-infra/scripts/ph11_sre03_install_watchdog_monitor01.sh
#

set -e

MONITOR_IP="10.0.0.152"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRE_WATCHDOG_DIR="$SCRIPT_DIR/../sre/watchdog"

echo "=============================================="
echo "PH11-SRE-03: Installing KeyBuzz Watchdog"
echo "Target: monitor-01 ($MONITOR_IP)"
echo "=============================================="
echo ""

# Check if we can reach monitor-01
echo "=== Checking connectivity to monitor-01 ==="
if ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$MONITOR_IP 'exit' 2>/dev/null; then
    echo "ERROR: Cannot connect to monitor-01 ($MONITOR_IP)"
    exit 1
fi
echo "OK"
echo ""

# Check for SRE watchdog files
echo "=== Checking source files ==="
if [ ! -d "$SRE_WATCHDOG_DIR" ]; then
    echo "ERROR: SRE watchdog directory not found: $SRE_WATCHDOG_DIR"
    echo "Expected structure:"
    echo "  keybuzz-infra/"
    echo "    sre/"
    echo "      watchdog/"
    echo "        watchdog.py"
    echo "        config.yaml"
    echo "        keybuzz-watchdog.service"
    echo "        keybuzz-watchdog.timer"
    echo "        keybuzz-watchdog-logrotate"
    exit 1
fi

for file in watchdog.py config.yaml keybuzz-watchdog.service keybuzz-watchdog.timer keybuzz-watchdog-logrotate; do
    if [ ! -f "$SRE_WATCHDOG_DIR/$file" ]; then
        echo "ERROR: Missing file: $SRE_WATCHDOG_DIR/$file"
        exit 1
    fi
done
echo "All source files present"
echo ""

# Install prerequisites on monitor-01
echo "=== Installing prerequisites on monitor-01 ==="
ssh -o StrictHostKeyChecking=no root@$MONITOR_IP << 'REMOTE_SCRIPT'
set -e

# Install kubectl if not present
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
fi
kubectl version --client

# Install hcloud if not present
if ! command -v hcloud &> /dev/null; then
    echo "Installing hcloud CLI..."
    curl -L -o /tmp/hcloud.tar.gz https://github.com/hetznercloud/cli/releases/download/v1.43.0/hcloud-linux-amd64.tar.gz
    tar -xzf /tmp/hcloud.tar.gz -C /tmp
    mv /tmp/hcloud /usr/local/bin/
    rm /tmp/hcloud.tar.gz
fi
hcloud version

# Create directories
mkdir -p /opt/keybuzz/sre/watchdog
mkdir -p /opt/keybuzz/logs/sre/watchdog
mkdir -p /opt/keybuzz/state/sre
mkdir -p /opt/keybuzz/credentials
chmod 700 /opt/keybuzz/credentials

# Ensure kubeconfig exists
if [ ! -f /root/.kube/config ]; then
    echo "WARNING: kubeconfig not found at /root/.kube/config"
    echo "Will attempt to copy from install-v3 in next step"
fi

echo "Prerequisites OK"
REMOTE_SCRIPT
echo ""

# Copy kubeconfig if missing
echo "=== Ensuring kubeconfig exists ==="
KUBECONFIG_EXISTS=$(ssh -o StrictHostKeyChecking=no root@$MONITOR_IP 'test -f /root/.kube/config && echo "yes" || echo "no"')
if [ "$KUBECONFIG_EXISTS" = "no" ]; then
    echo "Copying kubeconfig to monitor-01..."
    ssh -o StrictHostKeyChecking=no root@$MONITOR_IP 'mkdir -p /root/.kube'
    scp /root/.kube/config root@$MONITOR_IP:/root/.kube/config
    echo "kubeconfig copied"
else
    echo "kubeconfig already present"
fi
ssh -o StrictHostKeyChecking=no root@$MONITOR_IP 'kubectl get nodes --no-headers | wc -l' || {
    echo "ERROR: kubectl test failed"
    exit 1
}
echo "kubectl working"
echo ""

# Check for Hetzner token
echo "=== Checking Hetzner token ==="
TOKEN_EXISTS=$(ssh -o StrictHostKeyChecking=no root@$MONITOR_IP 'test -f /opt/keybuzz/credentials/hcloud.env && grep -q HCLOUD_TOKEN /opt/keybuzz/credentials/hcloud.env && echo "yes" || echo "no"')
if [ "$TOKEN_EXISTS" = "no" ]; then
    echo "WARNING: Hetzner token not found on monitor-01"
    
    # Try to copy from install-v3 if exists
    if [ -f /opt/keybuzz/credentials/hcloud.env ]; then
        echo "Found token on install-v3, copying..."
        scp /opt/keybuzz/credentials/hcloud.env root@$MONITOR_IP:/opt/keybuzz/credentials/
        ssh -o StrictHostKeyChecking=no root@$MONITOR_IP 'chmod 600 /opt/keybuzz/credentials/hcloud.env'
        echo "Token copied"
    else
        echo ""
        echo "Please create /opt/keybuzz/credentials/hcloud.env on monitor-01 with:"
        echo "  export HCLOUD_TOKEN=<your-hetzner-api-token>"
        echo ""
        echo "ERROR: No Hetzner token available. Installation aborted."
        exit 1
    fi
else
    echo "Hetzner token already present"
fi

# Test hcloud
ssh -o StrictHostKeyChecking=no root@$MONITOR_IP 'source /opt/keybuzz/credentials/hcloud.env && hcloud server list --output columns=name,status | head -3' || {
    echo "ERROR: hcloud test failed"
    exit 1
}
echo "hcloud working"
echo ""

# Copy watchdog files
echo "=== Copying watchdog files ==="
scp "$SRE_WATCHDOG_DIR/watchdog.py" root@$MONITOR_IP:/opt/keybuzz/sre/watchdog/
scp "$SRE_WATCHDOG_DIR/config.yaml" root@$MONITOR_IP:/opt/keybuzz/sre/watchdog/
scp "$SRE_WATCHDOG_DIR/keybuzz-watchdog.service" root@$MONITOR_IP:/etc/systemd/system/
scp "$SRE_WATCHDOG_DIR/keybuzz-watchdog.timer" root@$MONITOR_IP:/etc/systemd/system/
scp "$SRE_WATCHDOG_DIR/keybuzz-watchdog-logrotate" root@$MONITOR_IP:/etc/logrotate.d/keybuzz-watchdog
echo "Files copied"
echo ""

# Set permissions and enable service
echo "=== Configuring systemd ==="
ssh -o StrictHostKeyChecking=no root@$MONITOR_IP << 'REMOTE_SCRIPT'
set -e

chmod +x /opt/keybuzz/sre/watchdog/watchdog.py
chmod 644 /etc/systemd/system/keybuzz-watchdog.service
chmod 644 /etc/systemd/system/keybuzz-watchdog.timer
chmod 644 /etc/logrotate.d/keybuzz-watchdog

# Reload systemd
systemctl daemon-reload

# Enable timer (but don't start yet)
systemctl enable keybuzz-watchdog.timer

echo "Systemd configured"
REMOTE_SCRIPT
echo ""

# Test run (single execution, not timer)
echo "=== Running single test execution ==="
ssh -o StrictHostKeyChecking=no root@$MONITOR_IP 'python3 /opt/keybuzz/sre/watchdog/watchdog.py' || true
echo ""

# Show status
echo "=== Final status ==="
ssh -o StrictHostKeyChecking=no root@$MONITOR_IP << 'REMOTE_SCRIPT'
echo "Files installed:"
ls -la /opt/keybuzz/sre/watchdog/
echo ""
echo "Systemd units:"
systemctl list-unit-files | grep keybuzz-watchdog || echo "Units not found"
echo ""
echo "Last status:"
cat /opt/keybuzz/logs/sre/watchdog/watchdog_last_status.json 2>/dev/null | python3 -m json.tool || echo "No status yet"
REMOTE_SCRIPT
echo ""

echo "=============================================="
echo "Installation complete!"
echo ""
echo "To start the watchdog timer:"
echo "  ssh root@$MONITOR_IP 'systemctl start keybuzz-watchdog.timer'"
echo ""
echo "To check timer status:"
echo "  ssh root@$MONITOR_IP 'systemctl status keybuzz-watchdog.timer'"
echo ""
echo "To run manually:"
echo "  ssh root@$MONITOR_IP 'systemctl start keybuzz-watchdog.service'"
echo ""
echo "To view logs:"
echo "  ssh root@$MONITOR_IP 'tail -f /opt/keybuzz/logs/sre/watchdog/watchdog_*.jsonl'"
echo ""
echo "To view last status:"
echo "  ssh root@$MONITOR_IP 'cat /opt/keybuzz/logs/sre/watchdog/watchdog_last_status.json'"
echo "=============================================="
