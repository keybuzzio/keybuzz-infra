#!/bin/bash
# Pre-flight check before PH1-09 execution
# Verifies all prerequisites are met

set -euo pipefail

echo "PH1-09 - Pre-flight Check"
echo "======================================"
echo ""

ERRORS=0

# Check 1: Token file exists
echo "1. Checking Hetzner token file..."
if [[ -f /opt/keybuzz/credentials/hcloud.env ]]; then
    echo "   ✓ Token file exists"
    if grep -q "HCLOUD_TOKEN" /opt/keybuzz/credentials/hcloud.env || grep -q "HETZNER_API_TOKEN" /opt/keybuzz/credentials/hcloud.env; then
        if grep -q "HCLOUD_TOKEN" /opt/keybuzz/credentials/hcloud.env; then
            TOKEN_LENGTH=$(grep "HCLOUD_TOKEN" /opt/keybuzz/credentials/hcloud.env | cut -d"'" -f2 | wc -c)
        else
            TOKEN_LENGTH=$(grep "HETZNER_API_TOKEN" /opt/keybuzz/credentials/hcloud.env | cut -d'"' -f2 | wc -c)
        fi
        if [[ ${TOKEN_LENGTH} -gt 10 ]]; then
            echo "   ✓ Token appears to be set (length: $((TOKEN_LENGTH-1)) chars)"
        else
            echo "   ✗ Token appears to be empty or too short"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo "   ✗ Token not found in file"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "   ✗ Token file not found: /opt/keybuzz/credentials/hcloud.env"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 2: hcloud CLI works
echo "2. Checking hcloud CLI..."
if command -v hcloud &> /dev/null; then
    echo "   ✓ hcloud CLI installed"
    source /opt/keybuzz/credentials/hcloud.env 2>/dev/null || true
    export HCLOUD_TOKEN
    if hcloud server list &> /dev/null; then
        echo "   ✓ hcloud connection successful"
        SERVER_COUNT=$(hcloud server list --output json | jq 'length' 2>/dev/null || echo "0")
        echo "   ✓ Found $SERVER_COUNT servers in Hetzner"
    else
        echo "   ✗ hcloud connection failed"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "   ✗ hcloud CLI not found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 3: Ansible installed
echo "3. Checking Ansible..."
if command -v ansible-playbook &> /dev/null; then
    ANSIBLE_VERSION=$(ansible-playbook --version | head -1)
    echo "   ✓ Ansible installed: $ANSIBLE_VERSION"
else
    echo "   ✗ Ansible not installed"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 4: Ansible collections
echo "4. Checking Ansible collections..."
if ansible-galaxy collection list community.general &> /dev/null; then
    echo "   ✓ community.general collection installed"
else
    echo "   ✗ community.general collection not found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 5: Required scripts
echo "5. Checking required scripts..."
SCRIPTS=(
    "scripts/execute-phase1.sh"
    "scripts/setup-hetzner-token.sh"
    "scripts/phase1-report.sh"
    "scripts/rename-postgres-api.py"
    "scripts/generate_inventory.py"
    "scripts/generate_rebuild_order.py"
    "scripts/verify-inventory-rebuildorder.py"
)
ALL_SCRIPTS_OK=true
for script in "${SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        echo "   ✓ $script"
    else
        echo "   ✗ $script MISSING"
        ALL_SCRIPTS_OK=false
        ERRORS=$((ERRORS + 1))
    fi
done
if [[ "$ALL_SCRIPTS_OK" == "true" ]]; then
    echo "   ✓ All required scripts present"
fi
echo ""

# Check 6: Inventory and rebuild_order files
echo "6. Checking inventory files..."
if [[ -f "servers/servers_v3.tsv" ]]; then
    TSV_COUNT=$(tail -n +2 servers/servers_v3.tsv | wc -l)
    echo "   ✓ servers_v3.tsv exists ($TSV_COUNT servers)"
else
    echo "   ✗ servers_v3.tsv not found"
    ERRORS=$((ERRORS + 1))
fi

if [[ -f "servers/rebuild_order_v3.json" ]]; then
    REBUILD_SERVERS=$(jq -r '.metadata.total_servers' servers/rebuild_order_v3.json 2>/dev/null || echo "0")
    echo "   ✓ rebuild_order_v3.json exists ($REBUILD_SERVERS servers to rebuild)"
else
    echo "   ✗ rebuild_order_v3.json not found"
    ERRORS=$((ERRORS + 1))
fi

if [[ -f "ansible/playbooks/reset_hetzner.yml" ]]; then
    echo "   ✓ reset_hetzner.yml exists"
else
    echo "   ✗ reset_hetzner.yml not found"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check 7: Directories
echo "7. Checking directories..."
mkdir -p /opt/keybuzz/logs/phase1
mkdir -p /opt/keybuzz/reports/phase1
if [[ -d "/opt/keybuzz/logs/phase1" ]] && [[ -d "/opt/keybuzz/reports/phase1" ]]; then
    echo "   ✓ Log and report directories exist"
else
    echo "   ✗ Log/report directories missing"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Final summary
echo "======================================"
if [[ ${ERRORS} -eq 0 ]]; then
    echo "✓✓✓ ALL CHECKS PASSED ✓✓✓"
    echo ""
    echo "System is READY for PH1-09 execution"
    echo ""
    echo "To proceed with PH1-09, run:"
    echo "  cd /opt/keybuzz/keybuzz-infra"
    echo "  bash scripts/execute-phase1.sh | tee /opt/keybuzz/logs/phase1/execute-phase1-full.log"
    exit 0
else
    echo "✗✗✗ CHECKS FAILED ✗✗✗"
    echo ""
    echo "Found $ERRORS error(s). Please fix them before proceeding."
    echo ""
    exit 1
fi

