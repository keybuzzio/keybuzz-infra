#!/bin/bash
# Generate PHASE 1 rebuild report
# This script analyzes the rebuild results and generates detailed reports

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "${SCRIPT_DIR}")"
REPORT_DIR="/opt/keybuzz/reports/phase1"
LOG_DIR="/opt/keybuzz/logs/phase1"

# Create report directory
mkdir -p "${REPORT_DIR}"

echo "PHASE 1 - Rebuild Report Generation"
echo "===================================="
echo ""

# Load Hetzner token if available
if [[ -f /opt/keybuzz/credentials/hcloud.env ]]; then
    source /opt/keybuzz/credentials/hcloud.env
    export HETZNER_API_TOKEN
fi

# Function to get all servers with pagination
get_all_servers_json() {
    if command -v hcloud &> /dev/null && [[ -n "${HETZNER_API_TOKEN:-}" ]]; then
        # Use hcloud if available
        hcloud server list --output json
    else
        # Fallback to Python script
        python3 << 'PYEOF'
import os
import requests
import json

token = os.environ.get('HETZNER_API_TOKEN')
if not token:
    env_file = '/opt/keybuzz/credentials/hcloud.env'
    if os.path.exists(env_file):
        with open(env_file, 'r') as f:
            for line in f:
                if 'HETZNER_API_TOKEN=' in line:
                    token = line.split('"')[1]
                    break

if not token:
    print('[]')
    exit(0)

headers = {'Authorization': f'Bearer {token}'}
url = 'https://api.hetzner.cloud/v1/servers'

all_servers = []
page = 1
per_page = 50

while True:
    response = requests.get(url, headers=headers, params={'page': page, 'per_page': per_page})
    response.raise_for_status()
    data = response.json()
    servers = data.get('servers', [])
    if not servers:
        break
    all_servers.extend(servers)
    page += 1
    if page > 10:
        break

print(json.dumps(all_servers))
PYEOF
    fi
}

# Get server data
if command -v hcloud &> /dev/null && [[ -n "${HETZNER_API_TOKEN:-}" ]]; then
    echo "Collecting server status from Hetzner Cloud..."
    ALL_SERVERS_JSON=$(get_all_servers_json)
    
    # Count servers (excluding bastions)
    TOTAL_SERVERS=$(echo "${ALL_SERVERS_JSON}" | jq '[.[] | select(.name != "install-01" and .name != "install-v3")] | length')
    RUNNING_SERVERS=$(echo "${ALL_SERVERS_JSON}" | jq '[.[] | select(.name != "install-01" and .name != "install-v3" and .status == "running")] | length')
    
    echo "Total servers (excluding bastions): ${TOTAL_SERVERS}"
    echo "Running servers: ${RUNNING_SERVERS}"
    echo ""
    
    # Generate JSON report
    REPORT_JSON="${REPORT_DIR}/phase1-final.json"
    echo "${ALL_SERVERS_JSON}" | jq '{
        timestamp: now | todateiso8601,
        summary: {
            total_servers: [.[] | select(.name != "install-01" and .name != "install-v3")] | length,
            running_servers: [.[] | select(.name != "install-01" and .name != "install-v3" and .status == "running")] | length,
            expected_rebuild: 47,
            bastions: {
                install_01: [.[] | select(.name == "install-01")] | first // null,
                install_v3: [.[] | select(.name == "install-v3")] | first // null
            }
        },
        servers: [.[] | select(.name != "install-01" and .name != "install-v3")] | map({
            name: .name,
            id: .id,
            public_ip: .public_net.ipv4.ip,
            status: .status,
            created: .created,
            server_type: .server_type.name
        })],
        postgres_servers: [.[] | select(.name | startswith("db-postgres"))] | map({
            name: .name,
            id: .id,
            public_ip: .public_net.ipv4.ip,
            status: .status
        })
    }' > "${REPORT_JSON}"
    
    echo "✓ JSON report generated: ${REPORT_JSON}"
    
    # Generate Markdown report
    REPORT_MD="${REPORT_DIR}/phase1-final.md"
    cat > "${REPORT_MD}" << EOF
# PHASE 1 - Rebuild Report

**Generated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Summary

- **Total servers to rebuild:** 47
- **Total servers rebuilt:** ${TOTAL_SERVERS}
- **Running servers:** ${RUNNING_SERVERS}
- **Success rate:** $(echo "scale=1; ${RUNNING_SERVERS} * 100 / 47" | bc)%

## Server Status

### PostgreSQL Servers

EOF
    
    # Add PostgreSQL servers
    echo "${ALL_SERVERS_JSON}" | jq -r '[.[] | select(.name | startswith("db-postgres"))] | .[] | "- **\(.name)**: \(.status) (IP: \(.public_net.ipv4.ip))"' >> "${REPORT_MD}"
    
    cat >> "${REPORT_MD}" << EOF

### Bastion Status (Should be unchanged)

EOF
    
    # Add bastion status
    INSTALL01_STATUS=$(echo "${ALL_SERVERS_JSON}" | jq -r '[.[] | select(.name == "install-01")] | first | if . then "\(.status) (IP: \(.public_net.ipv4.ip))" else "not found" end')
    INSTALLV3_STATUS=$(echo "${ALL_SERVERS_JSON}" | jq -r '[.[] | select(.name == "install-v3")] | first | if . then "\(.status) (IP: \(.public_net.ipv4.ip))" else "not found" end')
    
    echo "- **install-01**: ${INSTALL01_STATUS} ✓" >> "${REPORT_MD}"
    echo "- **install-v3**: ${INSTALLV3_STATUS} ✓" >> "${REPORT_MD}"
    
    cat >> "${REPORT_MD}" << EOF

## All Rebuilt Servers

| Server Name | Status | Public IP | Server Type |
|-------------|--------|-----------|-------------|
EOF
    
    # Add all rebuilt servers
    echo "${ALL_SERVERS_JSON}" | jq -r '[.[] | select(.name != "install-01" and .name != "install-v3")] | sort_by(.name) | .[] | "| \(.name) | \(.status) | \(.public_net.ipv4.ip) | \(.server_type.name) |"' >> "${REPORT_MD}"
    
    cat >> "${REPORT_MD}" << EOF

## Rebuild Order

EOF
    
    # Add rebuild order info
    if [[ -f "${INFRA_DIR}/servers/rebuild_order_v3.json" ]]; then
        TOTAL_BATCHES=$(jq -r '.metadata.total_batches' "${INFRA_DIR}/servers/rebuild_order_v3.json")
        echo "- **Total batches:** ${TOTAL_BATCHES}" >> "${REPORT_MD}"
        echo "- **Batch size:** $(jq -r '.metadata.batch_size' "${INFRA_DIR}/servers/rebuild_order_v3.json")" >> "${REPORT_MD}"
        echo "- **Excluded servers:** $(jq -r '.metadata.excluded_servers | join(", ")' "${INFRA_DIR}/servers/rebuild_order_v3.json")" >> "${REPORT_MD}"
    fi
    
    cat >> "${REPORT_MD}" << EOF

## Logs

Logs are available in: \`${LOG_DIR}/\`

- Batch logs: \`batch-*-complete.log\`
- Playbook logs: Check ansible output

## Next Steps

1. Verify all servers are running
2. Proceed to PHASE 2 (SSH mesh deployment)
3. After PHASE 2, proceed to PHASE 3 (XFS volumes)

---

**Report generated by:** \`phase1-report.sh\`  
**Location:** \`${REPORT_MD}\`
EOF
    
    echo "✓ Markdown report generated: ${REPORT_MD}"
    
else
    echo "⚠ hcloud CLI not available or token not set"
    echo "Cannot generate detailed report"
    
    # Create minimal report
    cat > "${REPORT_DIR}/phase1-final.md" << EOF
# PHASE 1 - Rebuild Report

**Generated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")

⚠ **WARNING:** Cannot generate full report - hcloud CLI or token not available

Please ensure:
1. hcloud CLI is installed
2. HETZNER_API_TOKEN is set in environment or /opt/keybuzz/credentials/hcloud.env

EOF
fi

# Check rebuild_order_v3.json
if [[ -f "${INFRA_DIR}/servers/rebuild_order_v3.json" ]]; then
    echo ""
    echo "Rebuild Order Status:"
    echo "--------------------"
    TOTAL_REBUILD=$(jq -r '.metadata.total_servers' "${INFRA_DIR}/servers/rebuild_order_v3.json")
    TOTAL_BATCHES=$(jq -r '.metadata.total_batches' "${INFRA_DIR}/servers/rebuild_order_v3.json")
    echo "Expected servers to rebuild: ${TOTAL_REBUILD}"
    echo "Expected batches: ${TOTAL_BATCHES}"
    echo ""
fi

echo "===================================="
echo "Report generation complete!"
echo "Reports available in: ${REPORT_DIR}/"
echo "===================================="
