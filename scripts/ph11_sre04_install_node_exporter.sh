#!/bin/bash
# PH11-SRE-04: Install node_exporter on all infrastructure VMs
# Run from install-v3

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$SCRIPT_DIR/../ansible"

echo "=============================================="
echo "PH11-SRE-04: Installing node_exporter"
echo "=============================================="
echo ""

# Check Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo "Installing Ansible..."
    apt-get update && apt-get install -y ansible
fi

# Run playbook
echo "Running Ansible playbook..."
cd "$ANSIBLE_DIR"
ansible-playbook -i inventory/hosts_sre04.ini playbooks/sre04_node_exporter.yml -v

echo ""
echo "=============================================="
echo "Verifying node_exporter on all VMs..."
echo "=============================================="

# List of VMs to verify
VMS="10.0.0.11 10.0.0.12 10.0.0.120 10.0.0.121 10.0.0.122 10.0.0.123 10.0.0.124 10.0.0.125 10.0.0.126 10.0.0.127 10.0.0.128 10.0.0.150 10.0.0.151 10.0.0.152 10.0.0.153 10.0.0.160 10.0.0.170 10.0.0.171 10.0.0.172 10.0.0.173 10.0.0.174"

for IP in $VMS; do
    if curl -s --connect-timeout 2 "http://$IP:9100/metrics" > /dev/null 2>&1; then
        echo "✅ $IP - node_exporter OK"
    else
        echo "❌ $IP - node_exporter FAILED"
    fi
done

echo ""
echo "=============================================="
echo "Installation complete!"
echo "=============================================="
