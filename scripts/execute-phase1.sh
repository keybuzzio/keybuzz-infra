#!/bin/bash
# Complete PHASE 1 execution script for install-v3
# This script:
# 1. Sets up Hetzner token
# 2. Renames PostgreSQL servers
# 3. Launches PHASE 1 rebuild

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "${SCRIPT_DIR}")"

echo "=========================================="
echo "KeyBuzz v3 - PHASE 1 Execution"
echo "=========================================="
echo ""

# Step 1: Setup Hetzner token
echo "Step 1: Setting up Hetzner Cloud token..."
echo "----------------------------------------"
bash "${SCRIPT_DIR}/setup-hetzner-token.sh"
if [[ $? -ne 0 ]]; then
    echo "ERROR: Token setup failed"
    exit 1
fi

# Load token
source /opt/keybuzz/credentials/hcloud.env
export HETZNER_API_TOKEN

# Verify hcloud works
echo ""
echo "Verifying hcloud connection..."
if ! hcloud server list &> /dev/null; then
    echo "ERROR: hcloud connection failed"
    exit 1
fi
echo "✓ hcloud connection verified"
echo ""

# Step 2: Rename PostgreSQL servers
echo "Step 2: Renaming PostgreSQL servers..."
echo "----------------------------------------"
# Use Python script with pagination support
if [[ -f "${SCRIPT_DIR}/rename-postgres-api.py" ]]; then
    python3 "${SCRIPT_DIR}/rename-postgres-api.py"
    if [[ $? -ne 0 ]]; then
        echo "ERROR: PostgreSQL server rename failed"
        exit 1
    fi
else
    echo "ERROR: rename-postgres-api.py not found"
    exit 1
fi
echo ""

# Step 3: Regenerate inventory and rebuild_order
echo "Step 3: Regenerating inventory and rebuild_order..."
echo "----------------------------------------"
cd "${INFRA_DIR}"

# Regenerate inventory
if [[ -f scripts/generate_inventory.py ]]; then
    echo "Regenerating Ansible inventory..."
    python3 scripts/generate_inventory.py > ansible/inventory/hosts.yml
    echo "✓ Inventory regenerated"
else
    echo "ERROR: generate_inventory.py not found"
    exit 1
fi

# Regenerate rebuild_order
if [[ -f scripts/generate_rebuild_order.py ]]; then
    echo "Regenerating rebuild order..."
    python3 scripts/generate_rebuild_order.py
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Failed to generate rebuild_order"
        exit 1
    fi
    echo "✓ Rebuild order regenerated"
else
    echo "ERROR: generate_rebuild_order.py not found"
    exit 1
fi

# Verify inventory and rebuild_order coherence
if [[ -f scripts/verify-inventory-rebuildorder.py ]]; then
    echo "Verifying inventory and rebuild_order coherence..."
    python3 scripts/verify-inventory-rebuildorder.py
    if [[ $? -ne 0 ]]; then
        echo "ERROR: Inventory/rebuild_order verification failed"
        exit 1
    fi
    echo "✓ Verification passed"
fi
echo ""

# Step 4: Launch PHASE 1 rebuild
echo "Step 4: Launching PHASE 1 rebuild..."
echo "----------------------------------------"
echo "This will rebuild 47 servers in 10 batches"
echo "Press Ctrl+C within 5 seconds to cancel..."
sleep 5

echo ""
echo "Starting rebuild playbook..."
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/reset_hetzner.yml

REBUILD_EXIT_CODE=$?

echo ""
echo "=========================================="
if [[ ${REBUILD_EXIT_CODE} -eq 0 ]]; then
    echo "✓ PHASE 1 rebuild completed successfully!"
else
    echo "⚠ PHASE 1 rebuild completed with errors (exit code: ${REBUILD_EXIT_CODE})"
fi
echo "=========================================="
echo ""

# Generate report
echo "Generating report..."
bash "${SCRIPT_DIR}/phase1-report.sh"

echo ""
echo "=========================================="
echo "PHASE 1 execution complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Review the report above"
echo "  2. Verify all servers are running"
echo "  3. Proceed to PHASE 2 (SSH mesh deployment) when ready"
echo ""

