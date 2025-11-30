#!/bin/bash
# Fix hcloud CLI configuration
# Reads token from hcloud.env and updates cli.toml

set -euo pipefail

ENV_FILE="/opt/keybuzz/credentials/hcloud.env"
HCLOUD_CONFIG="${HOME}/.config/hcloud/cli.toml"

if [[ ! -f "${ENV_FILE}" ]]; then
    echo "ERROR: ${ENV_FILE} not found"
    exit 1
fi

# Source the env file and extract token
source "${ENV_FILE}"

if [[ -z "${HETZNER_API_TOKEN:-}" ]]; then
    echo "ERROR: HETZNER_API_TOKEN not found in ${ENV_FILE}"
    exit 1
fi

# Create/update cli.toml
mkdir -p "$(dirname "${HCLOUD_CONFIG}")"
cat > "${HCLOUD_CONFIG}" <<EOF
token = "${HETZNER_API_TOKEN}"
context = "keybuzz-v3"
EOF

chmod 600 "${HCLOUD_CONFIG}"
echo "✓ hcloud config updated"

# Test hcloud
if hcloud server list &> /dev/null; then
    echo "✓ hcloud connection successful"
    hcloud server list --output columns=id,name,ipv4,status | head -5
else
    echo "⚠ hcloud test failed"
    exit 1
fi

