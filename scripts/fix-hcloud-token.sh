#!/bin/bash
# Fix hcloud.env to use HCLOUD_TOKEN instead of HETZNER_API_TOKEN

set -euo pipefail

ENV_FILE="/opt/keybuzz/credentials/hcloud.env"

echo "Fixing hcloud.env to use HCLOUD_TOKEN..."
echo "========================================"

if [[ ! -f "${ENV_FILE}" ]]; then
    echo "ERROR: ${ENV_FILE} not found"
    exit 1
fi

# Extract token (support both old and new format)
TOKEN=""
if grep -q "HETZNER_API_TOKEN" "${ENV_FILE}"; then
    TOKEN=$(grep "HETZNER_API_TOKEN" "${ENV_FILE}" | sed 's/.*"\([^"]*\)".*/\1/')
elif grep -q "HCLOUD_TOKEN" "${ENV_FILE}"; then
    TOKEN=$(grep "HCLOUD_TOKEN" "${ENV_FILE}" | sed "s/.*'\([^']*\)'.*/\1/")
fi

if [[ -z "${TOKEN}" ]]; then
    echo "ERROR: Could not extract token from ${ENV_FILE}"
    exit 1
fi

echo "Token extracted (length: ${#TOKEN} chars)"

# Create new file with HCLOUD_TOKEN
cat > "${ENV_FILE}" <<EOF
export HCLOUD_TOKEN='${TOKEN}'
EOF

chmod 600 "${ENV_FILE}"
echo "✓ ${ENV_FILE} updated to use HCLOUD_TOKEN"

# Test
source "${ENV_FILE}"
export HCLOUD_TOKEN

if hcloud server list &> /dev/null; then
    echo "✓ hcloud connection successful!"
    hcloud server list --output columns=id,name,status | head -5
else
    echo "✗ hcloud connection failed"
    exit 1
fi

