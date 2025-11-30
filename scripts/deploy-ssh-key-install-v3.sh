#!/bin/bash
# Deploy SSH key to install-v3
# This script adds the SSH public key to authorized_keys on install-v3
# Usage: Execute this script ON install-v3 server (after manual first connection)

set -euo pipefail

SSH_PUBLIC_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCbFlqZbjFvL3e9BzjJHZwbrnaKRDInjWMjRDewf4TAU0BjhU9dnmU48G/Zh965QzXNfeMjDTDS6kGe6fSaPGW/ORriZRJ1eZ6LWwQy0SSNTQ9upjul1b8ffjs6kN+sinVYUr4wwCaupTD7a/1dhJ+BOYKqHPJLm2JWhPnNTZj1wLwaUS91Rh2L3HiWELCSn0Nffe3if4ZKuZhcJcEChKDwTeVq5LwOgmDWV5XlRNWVH7QvOzFDSxuBy+lQQ7A8ICydUrTVrHN2foy9bviuB2OYKnTldC5YD8dXGYKRc2kiob1Vr+GvaRj4ywGANQsOdz3zZFz9cByHnxDeHilyLAI4s2aqwLSYLxYiiF6WmDVbihnjUCI+TGabWtRs2UpTtekONcqS5LoY09F34VHMXsF6oYhjRoL8ENDBNSfRkATRiiOCsJYYE3xyBaz5H1opuxscphkT5xgVi7UvmNS5oc1V8kXY8OGPih6q6g43CvGRy/VE5uxUfVqHGuwRe3KcpPOakYj36x3XKywlqVwDD4wVuu0FW9XljuZKeW8X3B3sKMu1vdh1sRBtzwEfeDc46Xe3chNqCPGPU1EmXj/hllont6i7duh7msJyuR33Y8a9IIfNVhgtEpZ0PhQQ6wkGG5iqn9WH5SG/PitJ7wuxAOBkzAFBt2t+PBXpIKRnOwn1vw== install-v3-keybuzz-v3"

SSH_DIR="/root/.ssh"
AUTHORIZED_KEYS="${SSH_DIR}/authorized_keys"

echo "Deploying SSH key to install-v3..."
echo "===================================="

# Create .ssh directory if it doesn't exist
mkdir -p "${SSH_DIR}"
chmod 700 "${SSH_DIR}"

# Check if key already exists
if grep -q "install-v3-keybuzz-v3" "${AUTHORIZED_KEYS}" 2>/dev/null; then
    echo "✓ SSH key already exists in authorized_keys"
else
    # Add key to authorized_keys
    echo "${SSH_PUBLIC_KEY}" >> "${AUTHORIZED_KEYS}"
    echo "✓ SSH key added to authorized_keys"
fi

# Set correct permissions
chmod 600 "${AUTHORIZED_KEYS}"
echo "✓ Permissions set correctly"

echo ""
echo "===================================="
echo "✓ SSH key deployment complete!"
echo ""
echo "You can now connect from local machine with:"
echo "  ssh -i ~/.ssh/id_rsa_keybuzz_v3 root@46.62.171.61"
echo "===================================="

