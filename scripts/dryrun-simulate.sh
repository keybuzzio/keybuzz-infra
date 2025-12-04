#!/bin/bash
# Simulate dry-run execution of reset_hetzner.yml
# This script shows what would be done without executing Ansible

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "${SCRIPT_DIR}")"
REBUILD_JSON="${INFRA_DIR}/servers/rebuild_order_v3.json"

echo "PH1-08 - Dry-run Simulation"
echo "======================================"
echo ""

if [[ ! -f "${REBUILD_JSON}" ]]; then
    echo "ERROR: ${REBUILD_JSON} not found"
    exit 1
fi

# Parse rebuild_order_v3.json
TOTAL_SERVERS=$(jq -r '.metadata.total_servers' "${REBUILD_JSON}")
TOTAL_BATCHES=$(jq -r '.metadata.total_batches' "${REBUILD_JSON}")
BATCH_SIZE=$(jq -r '.metadata.batch_size' "${REBUILD_JSON}")
EXCLUDED=$(jq -r '.metadata.excluded_servers | join(", ")' "${REBUILD_JSON}")

echo "Configuration:"
echo "  Total servers to rebuild: ${TOTAL_SERVERS}"
echo "  Total batches: ${TOTAL_BATCHES}"
echo "  Batch size: ${BATCH_SIZE}"
echo "  Excluded servers: ${EXCLUDED}"
echo ""

echo "======================================"
echo "DRY-RUN SIMULATION"
echo "======================================"
echo ""
echo "In DRY-RUN mode, the following actions would be SIMULATED:"
echo ""

# Process each batch
for batch_num in $(seq 1 ${TOTAL_BATCHES}); do
    echo "──────────────────────────────────────"
    echo "BATCH ${batch_num}"
    echo "──────────────────────────────────────"
    
    # Get servers in this batch
    SERVERS=$(jq -r ".batches[] | select(.batch_number == ${batch_num}) | .servers | join(\", \")" "${REBUILD_JSON}")
    
    echo "Servers: ${SERVERS}"
    echo ""
    echo "[DRY-RUN] Would perform the following actions:"
    echo ""
    
    echo "1. Get server info (5 servers in parallel)"
    echo "   - Read server details from Hetzner API"
    echo "   - Identify volumes attached to each server"
    echo ""
    
    echo "2. Build volumes list"
    echo "   - Collect all volumes for this batch"
    echo ""
    
    echo "3. [DRY-RUN] Would detach volumes"
    echo "   - Detach volumes from servers (parallel, throttle: 10)"
    echo "   - Volumes would be detached but NOT deleted yet"
    echo ""
    
    echo "4. Wait 5 seconds (volume detachment propagation)"
    echo ""
    
    echo "5. [DRY-RUN] Would delete volumes"
    echo "   - Delete detached volumes (parallel, throttle: 10)"
    echo "   - WARNING: This is IRREVERSIBLE"
    echo ""
    
    echo "6. [DRY-RUN] Would rebuild servers"
    echo "   - Rebuild all servers in batch with Ubuntu 24.04 (parallel, throttle: 10)"
    echo "   - This will WIPE all data and reinstall OS"
    echo ""
    
    echo "7. [DRY-RUN] Would wait for servers to be 'running'"
    echo "   - Poll server status until all are 'running' (max 10 minutes per server)"
    echo "   - Parallel polling (throttle: 10)"
    echo ""
    
    echo "8. [DRY-RUN] Would wait for SSH port 22"
    echo "   - Check that SSH port 22 is open on all public IPs (max 5 minutes per server)"
    echo "   - Parallel check (throttle: 10)"
    echo ""
    
    echo "9. Write batch completion log"
    echo "   - Log file: /opt/keybuzz/logs/phase1/batch-${batch_num}-complete.log"
    echo ""
    
    echo ""
done

echo "======================================"
echo "SUMMARY"
echo "======================================"
echo ""
echo "In DRY-RUN mode:"
echo "  ✓ All information gathering would be executed"
echo "  ✓ All destructive actions would be SKIPPED"
echo "  ✓ Debug messages would show what would be done"
echo "  ✓ No volumes would be detached"
echo "  ✓ No volumes would be deleted"
echo "  ✓ No servers would be rebuilt"
echo ""
echo "In REAL mode (PH1-09):"
echo "  ⚠ All above actions would be EXECUTED"
echo "  ⚠ Volumes would be PERMANENTLY DELETED"
echo "  ⚠ Servers would be REBUILT (data loss)"
echo ""
echo "======================================"
echo "Ready for real execution (PH1-09)?"
echo "======================================"

