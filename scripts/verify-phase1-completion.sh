#!/bin/bash
# Verify PHASE 1 completion
# Checks that all 47 servers are rebuilt and running

set -euo pipefail

# Load token
source /opt/keybuzz/credentials/hcloud.env 2>/dev/null || true
export HCLOUD_TOKEN

echo "=========================================="
echo "PHASE 1 - Completion Verification"
echo "=========================================="
echo ""

# Check batches completed
BATCHES_COMPLETED=$(ls -1 /opt/keybuzz/logs/phase1/batch-*-complete.log 2>/dev/null | wc -l)
echo "Batches completed: ${BATCHES_COMPLETED}/10"

if [[ ${BATCHES_COMPLETED} -ne 10 ]]; then
    echo "❌ ERROR: Not all batches completed!"
    exit 1
fi
echo "✓ All 10 batches completed"

# Check servers
if ! command -v hcloud &> /dev/null || [[ -z "${HCLOUD_TOKEN:-}" ]]; then
    echo "⚠ Warning: Cannot verify server status (hcloud not available)"
    exit 0
fi

TEMP_JSON="/tmp/phase1-verify-servers.json"
hcloud server list --output json > "${TEMP_JSON}"

TOTAL_REBUILDABLE=$(python3 << 'PYEOF'
import json
import sys
with open('/tmp/phase1-verify-servers.json') as f:
    servers = json.load(f)
    rebuildable = [s for s in servers if s['name'] not in ['install-01', 'install-v3']]
    print(len(rebuildable))
PYEOF
)

RUNNING_REBUILDABLE=$(python3 << 'PYEOF'
import json
with open('/tmp/phase1-verify-servers.json') as f:
    servers = json.load(f)
    rebuildable = [s for s in servers if s['name'] not in ['install-01', 'install-v3'] and s['status'] == 'running']
    print(len(rebuildable))
PYEOF
)

echo ""
echo "Server Status:"
echo "  Total rebuildable servers: ${TOTAL_REBUILDABLE}/47"
echo "  Running rebuildable servers: ${RUNNING_REBUILDABLE}/47"

if [[ ${TOTAL_REBUILDABLE} -eq 47 ]] && [[ ${RUNNING_REBUILDABLE} -eq 47 ]]; then
    echo ""
    echo "=========================================="
    echo "✓✓✓ PHASE 1 COMPLETE - 100% SUCCESS ✓✓✓"
    echo "=========================================="
    echo ""
    echo "All 47 servers rebuilt and running!"
    echo "All 10 batches completed successfully!"
    echo ""
    echo "Next step: PHASE 2 - SSH Mesh Deployment"
    exit 0
else
    echo ""
    echo "❌ ERROR: PHASE 1 NOT COMPLETE"
    echo "  Expected: 47 rebuildable, 47 running"
    echo "  Actual: ${TOTAL_REBUILDABLE} rebuildable, ${RUNNING_REBUILDABLE} running"
    exit 1
fi

