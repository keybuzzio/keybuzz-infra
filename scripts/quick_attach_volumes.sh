#!/bin/bash
# Quick attach all volumes - no complex checks
set -e

cd /opt/keybuzz/keybuzz-infra
source /opt/keybuzz/credentials/hcloud.env
export HCLOUD_TOKEN

echo "Attaching all volumes..."
python3 << 'EOF'
import json

with open('servers/volume_diff_v3.json') as f:
    data = json.load(f)

for vol in data['volumes_to_create']:
    vol_name = vol['volume_name']
    hostname = vol['hostname']
    print(f"Attaching {vol_name} to {hostname}...")
EOF

python3 << 'EOF'
import json
import subprocess
import os

with open('servers/volume_diff_v3.json') as f:
    data = json.load(f)

success = 0
for vol in data['volumes_to_create']:
    vol_name = vol['volume_name']
    hostname = vol['hostname']
    try:
        subprocess.run(
            ['hcloud', 'volume', 'attach', '--server', hostname, vol_name],
            check=True,
            env=os.environ,
            capture_output=True
        )
        success += 1
        print(f"✓ {vol_name}")
    except:
        print(f"✗ {vol_name}")

print(f"\nSuccess: {success}/{len(data['volumes_to_create'])}")
EOF

