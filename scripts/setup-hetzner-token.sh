#!/bin/bash
# Setup Hetzner Cloud token on install-v3
# This script configures the Hetzner API token for persistent use

set -euo pipefail

# Check if HETZNER_API_TOKEN is provided
if [[ -z "${HETZNER_API_TOKEN:-}" ]]; then
    echo "[ERROR] HETZNER_API_TOKEN is not set. Export it before running this script." >&2
    echo "Example: export HETZNER_API_TOKEN=\"your-token-here\"" >&2
    exit 1
fi

HETZNER_TOKEN="${HETZNER_API_TOKEN}"
CREDENTIALS_DIR="/opt/keybuzz/credentials"
ENV_FILE="${CREDENTIALS_DIR}/hcloud.env"
HCLOUD_CONFIG_DIR="${HOME}/.config/hcloud"
HCLOUD_CONFIG="${HCLOUD_CONFIG_DIR}/cli.toml"

echo "Setting up Hetzner Cloud token on install-v3..."
echo "================================================"

# 1. Create credentials directory
echo "Creating credentials directory..."
mkdir -p "${CREDENTIALS_DIR}"
chmod 700 "${CREDENTIALS_DIR}"

# 2. Create hcloud.env file
echo "Creating ${ENV_FILE}..."
cat > "${ENV_FILE}" <<EOF
export HETZNER_API_TOKEN="${HETZNER_TOKEN}"
EOF
chmod 600 "${ENV_FILE}"
echo "✓ Token stored in ${ENV_FILE}"

# 3. Configure hcloud CLI
echo "Configuring hcloud CLI..."
mkdir -p "${HCLOUD_CONFIG_DIR}"

# Create or update hcloud config
# Note: hcloud CLI will read token from environment if not in config
if [[ -f "${HCLOUD_CONFIG}" ]]; then
    echo "Updating existing hcloud config..."
    # Remove any existing token line and add empty token (hcloud uses env var)
    sed -i '/^token = /d' "${HCLOUD_CONFIG}" || true
    if ! grep -q "^context" "${HCLOUD_CONFIG}"; then
        echo 'context = "keybuzz-v3"' >> "${HCLOUD_CONFIG}"
    fi
else
    echo "Creating new hcloud config..."
    cat > "${HCLOUD_CONFIG}" <<EOF
token = ""
context = "keybuzz-v3"
EOF
fi

chmod 600 "${HCLOUD_CONFIG}"
echo "✓ hcloud CLI configured"

# 4. Test hcloud connection
echo ""
echo "Testing hcloud connection..."
if command -v hcloud &> /dev/null; then
    if hcloud server list &> /dev/null; then
        echo "✓ hcloud connection successful"
        echo ""
        echo "Sample output:"
        hcloud server list | head -5
    else
        echo "⚠ Warning: hcloud command failed. Check token."
        exit 1
    fi
else
    echo "⚠ Warning: hcloud CLI not installed. Install it with:"
    echo "  curl -fsSL https://github.com/hetznercloud/cli/releases/latest/download/hcloud-linux-amd64.tar.gz | tar -xz -C /usr/local/bin hcloud"
    exit 1
fi

# 5. Add to .bashrc for automatic loading
echo ""
echo "Adding token source to ~/.bashrc..."
if ! grep -q "hcloud.env" ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc <<EOF

# Load Hetzner Cloud token
if [ -f ${ENV_FILE} ]; then
    source ${ENV_FILE}
fi
EOF
    echo "✓ Token auto-loading added to ~/.bashrc"
else
    echo "✓ Token auto-loading already in ~/.bashrc"
fi

echo ""
echo "================================================"
echo "✓ Hetzner Cloud token setup complete!"
echo ""
echo "To use the token in current session:"
echo "  source ${ENV_FILE}"
echo "  export HETZNER_API_TOKEN"
echo ""
echo "Token is stored in:"
echo "  - ${ENV_FILE} (chmod 600)"
echo "  - ${HCLOUD_CONFIG} (chmod 600)"
echo "================================================"

