#!/bin/bash
# PH11-SRE-06: Install DEV Endpoint Checker on monitor-01
# Run from install-v3

set -euo pipefail

MONITOR_IP="10.0.0.152"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKER_SCRIPT="$SCRIPT_DIR/ph11_sre06_check_endpoints_dev.sh"

echo "=============================================="
echo "PH11-SRE-06: Installing Endpoint Checker"
echo "Target: monitor-01 ($MONITOR_IP)"
echo "=============================================="
echo ""

# Check source script exists
if [ ! -f "$CHECKER_SCRIPT" ]; then
    echo "ERROR: Checker script not found: $CHECKER_SCRIPT"
    exit 1
fi

# Test connectivity
echo "=== Testing connectivity ==="
if ! ssh -o ConnectTimeout=5 root@$MONITOR_IP 'echo OK' > /dev/null 2>&1; then
    echo "ERROR: Cannot connect to monitor-01"
    exit 1
fi
echo "✅ Connection OK"
echo ""

# Create directories on monitor-01
echo "=== Creating directories ==="
ssh root@$MONITOR_IP 'mkdir -p /opt/keybuzz/sre/endpoints-checker /opt/keybuzz/logs/sre/endpoints'
echo "✅ Directories created"
echo ""

# Copy checker script
echo "=== Copying checker script ==="
scp "$CHECKER_SCRIPT" root@$MONITOR_IP:/opt/keybuzz/sre/endpoints-checker/check_endpoints.sh
ssh root@$MONITOR_IP 'chmod +x /opt/keybuzz/sre/endpoints-checker/check_endpoints.sh'
echo "✅ Script copied"
echo ""

# Create systemd service
echo "=== Creating systemd service ==="
ssh root@$MONITOR_IP 'cat > /etc/systemd/system/keybuzz-endpoints-checker.service << EOF
[Unit]
Description=KeyBuzz DEV Endpoints Checker
Documentation=https://github.com/keybuzzio/keybuzz-infra
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/opt/keybuzz/sre/endpoints-checker/check_endpoints.sh /opt/keybuzz/logs/sre/endpoints
WorkingDirectory=/opt/keybuzz/sre/endpoints-checker
StandardOutput=journal
StandardError=journal
# Don'"'"'t fail the service if endpoints are down
SuccessExitStatus=0 1

[Install]
WantedBy=multi-user.target
EOF'
echo "✅ Service file created"
echo ""

# Create systemd timer
echo "=== Creating systemd timer ==="
ssh root@$MONITOR_IP 'cat > /etc/systemd/system/keybuzz-endpoints-checker.timer << EOF
[Unit]
Description=KeyBuzz DEV Endpoints Checker Timer
Documentation=https://github.com/keybuzzio/keybuzz-infra

[Timer]
OnBootSec=1min
OnUnitActiveSec=60s
Unit=keybuzz-endpoints-checker.service

[Install]
WantedBy=timers.target
EOF'
echo "✅ Timer file created"
echo ""

# Create logrotate config
echo "=== Creating logrotate config ==="
ssh root@$MONITOR_IP 'cat > /etc/logrotate.d/keybuzz-endpoints-checker << EOF
/opt/keybuzz/logs/sre/endpoints/*.json {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 root root
}
EOF'
echo "✅ Logrotate configured"
echo ""

# Enable and start timer
echo "=== Enabling and starting timer ==="
ssh root@$MONITOR_IP 'systemctl daemon-reload && systemctl enable keybuzz-endpoints-checker.timer && systemctl start keybuzz-endpoints-checker.timer'
echo "✅ Timer enabled and started"
echo ""

# Run initial check
echo "=== Running initial check ==="
ssh root@$MONITOR_IP 'systemctl start keybuzz-endpoints-checker.service'
sleep 3
ssh root@$MONITOR_IP 'cat /opt/keybuzz/logs/sre/endpoints/check_*.json 2>/dev/null | tail -1 | python3 -m json.tool 2>/dev/null || echo "Waiting for first run..."'
echo ""

# Verify
echo "=== Verification ==="
ssh root@$MONITOR_IP 'systemctl status keybuzz-endpoints-checker.timer --no-pager'
echo ""

echo "=============================================="
echo "Installation complete!"
echo ""
echo "Useful commands:"
echo "  # Check timer status"
echo "  ssh root@$MONITOR_IP 'systemctl status keybuzz-endpoints-checker.timer'"
echo ""
echo "  # View latest check"
echo "  ssh root@$MONITOR_IP 'ls -lt /opt/keybuzz/logs/sre/endpoints/ | head -5'"
echo ""
echo "  # Manual run"
echo "  ssh root@$MONITOR_IP 'systemctl start keybuzz-endpoints-checker.service'"
echo "=============================================="
