#!/bin/bash
# Quick check of hcloud server statistics
# Used for PH2-01 verification

set -euo pipefail

source /opt/keybuzz/credentials/hcloud.env 2>/dev/null || true
export HCLOUD_TOKEN

TEMP_JSON="/tmp/servers-ph2-check.json"
hcloud server list --output json > "${TEMP_JSON}"

python3 << 'PYEOF'
import json

with open('/tmp/servers-ph2-check.json') as f:
    servers = json.load(f)
    
total = len(servers)
rebuildable = [s for s in servers if s['name'] not in ['install-01', 'install-v3']]
running_rebuildable = [s for s in rebuildable if s['status'] == 'running']
bastions = [s for s in servers if s['name'] in ['install-01', 'install-v3']]

print(f'Total servers in Hetzner: {total}')
print(f'Rebuildable servers (excl bastions): {len(rebuildable)}')
print(f'Running rebuildable: {len(running_rebuildable)}')
print(f'Bastions found: {len(bastions)}')
for b in bastions:
    ip = b.get('public_net', {}).get('ipv4', {}).get('ip', 'N/A')
    print(f'  - {b["name"]}: {b["status"]} (IP: {ip})')
PYEOF

