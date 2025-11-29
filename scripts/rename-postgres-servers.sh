#!/bin/bash
# Rename PostgreSQL servers in Hetzner Cloud
# db-master-01 → db-postgres-01
# db-slave-01 → db-postgres-02
# db-slave-02 → db-postgres-03

set -euo pipefail

# Load Hetzner token
if [[ -f /opt/keybuzz/credentials/hcloud.env ]]; then
    source /opt/keybuzz/credentials/hcloud.env
    export HETZNER_API_TOKEN
fi

if [[ -z "${HETZNER_API_TOKEN:-}" ]]; then
    echo "ERROR: HETZNER_API_TOKEN not set"
    echo "Run: source /opt/keybuzz/credentials/hcloud.env"
    exit 1
fi

echo "Renaming PostgreSQL servers in Hetzner Cloud..."
echo "================================================"

# Check hcloud is available
if ! command -v hcloud &> /dev/null; then
    echo "ERROR: hcloud CLI not found"
    exit 1
fi

# List current servers
echo ""
echo "Current PostgreSQL servers:"
hcloud server list --selector name=db-master-01,name=db-slave-01,name=db-slave-02 --output columns=id,name,ipv4,status

echo ""
echo "Renaming servers..."

# Rename db-master-01 → db-postgres-01
echo "  db-master-01 → db-postgres-01"
if hcloud server describe db-master-01 &> /dev/null; then
    SERVER_ID=$(hcloud server describe db-master-01 -o json | jq -r '.id')
    if [[ -n "${SERVER_ID}" && "${SERVER_ID}" != "null" ]]; then
        hcloud server update "${SERVER_ID}" --name db-postgres-01
        echo "    ✓ Renamed successfully"
    else
        echo "    ✗ Could not get server ID"
        exit 1
    fi
else
    echo "    ⚠ Server db-master-01 not found (may already be renamed)"
fi

# Rename db-slave-01 → db-postgres-02
echo "  db-slave-01 → db-postgres-02"
if hcloud server describe db-slave-01 &> /dev/null; then
    SERVER_ID=$(hcloud server describe db-slave-01 -o json | jq -r '.id')
    if [[ -n "${SERVER_ID}" && "${SERVER_ID}" != "null" ]]; then
        hcloud server update "${SERVER_ID}" --name db-postgres-02
        echo "    ✓ Renamed successfully"
    else
        echo "    ✗ Could not get server ID"
        exit 1
    fi
else
    echo "    ⚠ Server db-slave-01 not found (may already be renamed)"
fi

# Rename db-slave-02 → db-postgres-03
echo "  db-slave-02 → db-postgres-03"
if hcloud server describe db-slave-02 &> /dev/null; then
    SERVER_ID=$(hcloud server describe db-slave-02 -o json | jq -r '.id')
    if [[ -n "${SERVER_ID}" && "${SERVER_ID}" != "null" ]]; then
        hcloud server update "${SERVER_ID}" --name db-postgres-03
        echo "    ✓ Renamed successfully"
    else
        echo "    ✗ Could not get server ID"
        exit 1
    fi
else
    echo "    ⚠ Server db-slave-02 not found (may already be renamed)"
fi

# Verify renames
echo ""
echo "Verification - PostgreSQL servers:"
hcloud server list --selector name=db-postgres-01,name=db-postgres-02,name=db-postgres-03 --output columns=id,name,ipv4,status

echo ""
echo "================================================"
echo "✓ PostgreSQL server rename complete!"
echo "================================================"

