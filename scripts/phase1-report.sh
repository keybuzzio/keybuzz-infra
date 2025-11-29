#!/bin/bash
# Generate PHASE 1 rebuild report
# This script analyzes the rebuild results and generates a summary

set -euo pipefail

echo "PHASE 1 - Rebuild Report"
echo "========================"
echo ""

# Load Hetzner token if available
if [[ -f /opt/keybuzz/credentials/hcloud.env ]]; then
    source /opt/keybuzz/credentials/hcloud.env
    export HETZNER_API_TOKEN
fi

if command -v hcloud &> /dev/null && [[ -n "${HETZNER_API_TOKEN:-}" ]]; then
    echo "Server Status:"
    echo "--------------"
    
    # Count total servers (excluding bastions)
    TOTAL_SERVERS=$(hcloud server list --output json | jq '[.[] | select(.name != "install-01" and .name != "install-v3")] | length')
    RUNNING_SERVERS=$(hcloud server list --output json | jq '[.[] | select(.name != "install-01" and .name != "install-v3" and .status == "running")] | length')
    
    echo "Total servers (excluding bastions): ${TOTAL_SERVERS}"
    echo "Running servers: ${RUNNING_SERVERS}"
    echo ""
    
    # List PostgreSQL servers
    echo "PostgreSQL Servers:"
    hcloud server list --selector name=db-postgres-01,name=db-postgres-02,name=db-postgres-03 --output columns=id,name,ipv4,status || echo "  (No PostgreSQL servers found)"
    echo ""
    
    # Verify bastions were not touched
    echo "Bastion Status (should be unchanged):"
    if hcloud server describe install-01 &> /dev/null; then
        INSTALL01_STATUS=$(hcloud server describe install-01 -o json | jq -r '.status')
        echo "  install-01: ${INSTALL01_STATUS} ✓"
    else
        echo "  install-01: not found"
    fi
    
    if hcloud server describe install-v3 &> /dev/null; then
        INSTALLV3_STATUS=$(hcloud server describe install-v3 -o json | jq -r '.status')
        echo "  install-v3: ${INSTALLV3_STATUS} ✓"
    else
        echo "  install-v3: not found"
    fi
    echo ""
else
    echo "⚠ hcloud CLI not available or token not set"
    echo "Cannot generate detailed report"
fi

# Check rebuild_order_v3.json
if [[ -f /opt/keybuzz/keybuzz-infra/servers/rebuild_order_v3.json ]]; then
    echo "Rebuild Order:"
    echo "--------------"
    TOTAL_REBUILD=$(jq '.metadata.total_servers' /opt/keybuzz/keybuzz-infra/servers/rebuild_order_v3.json)
    TOTAL_BATCHES=$(jq '.metadata.total_batches' /opt/keybuzz/keybuzz-infra/servers/rebuild_order_v3.json)
    echo "Expected servers to rebuild: ${TOTAL_REBUILD}"
    echo "Expected batches: ${TOTAL_BATCHES}"
    echo ""
fi

echo "========================"
echo "Report generated at: $(date)"
echo "========================"

