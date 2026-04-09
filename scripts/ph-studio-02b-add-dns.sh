#!/bin/bash
set -euo pipefail

# Load Hetzner tokens
source /opt/keybuzz/credentials/hcloud.env 2>/dev/null || true

# Check for DNS-specific token
DNS_TOKEN=""
if [ -f /opt/keybuzz/credentials/hdns.env ]; then
  source /opt/keybuzz/credentials/hdns.env
  DNS_TOKEN="${HETZNER_DNS_TOKEN:-}"
fi

# Check Vault for DNS token
export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=$(cat /root/.vault-cluster-root-token 2>/dev/null || echo "")
VAULT_DNS=$(vault kv get -field=dns_token secret/keybuzz/hetzner 2>/dev/null || echo "")
if [ -n "$VAULT_DNS" ]; then
  DNS_TOKEN="$VAULT_DNS"
fi

# Try hcloud token if no DNS token
if [ -z "$DNS_TOKEN" ]; then
  DNS_TOKEN="${HCLOUD_TOKEN:-}"
  echo "Using HCLOUD_TOKEN for DNS API (may not work)"
fi

echo "DNS Token available: $([ -n \"$DNS_TOKEN\" ] && echo 'yes' || echo 'no')"

echo ""
echo "=== Step 1: Get zone ID for keybuzz.io ==="
ZONES_RESPONSE=$(curl -s -H "Auth-API-Token: ${DNS_TOKEN}" \
  "https://dns.hetzner.com/api/v1/zones?name=keybuzz.io" 2>&1)
echo "$ZONES_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); zones=d.get('zones',[]); print(f'Zones found: {len(zones)}'); [print(f'  id={z[\"id\"]} name={z[\"name\"]}') for z in zones]" 2>/dev/null || echo "API response: $(echo $ZONES_RESPONSE | head -c 200)"

ZONE_ID=$(echo "$ZONES_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); zones=d.get('zones',[]); print(zones[0]['id'] if zones else '')" 2>/dev/null || echo "")

if [ -z "$ZONE_ID" ]; then
  echo ""
  echo "FAIL: Could not get zone ID. The HCLOUD_TOKEN may not work for DNS."
  echo "Trying search for Hetzner DNS token on bastion..."
  
  grep -rl "dns.*token\|DNS_TOKEN\|HETZNER_DNS" /opt/keybuzz/credentials/ /root/ 2>/dev/null | head -5
  find /opt/keybuzz/credentials -type f 2>/dev/null
  
  echo ""
  echo "Checking Hetzner Robot API..."
  curl -s -H "Auth-API-Token: ${DNS_TOKEN}" \
    "https://dns.hetzner.com/api/v1/zones" 2>&1 | head -c 300
  
  exit 1
fi

echo ""
echo "Zone ID: $ZONE_ID"

echo ""
echo "=== Step 2: Check existing records ==="
RECORDS=$(curl -s -H "Auth-API-Token: ${DNS_TOKEN}" \
  "https://dns.hetzner.com/api/v1/records?zone_id=${ZONE_ID}" 2>&1)
echo "$RECORDS" | python3 -c "
import sys, json
d = json.load(sys.stdin)
records = d.get('records', [])
studio_records = [r for r in records if 'studio' in r.get('name','')]
print(f'Total records: {len(records)}')
print(f'Studio records: {len(studio_records)}')
for r in studio_records:
    print(f'  {r[\"type\"]} {r[\"name\"]} -> {r[\"value\"]}')
" 2>/dev/null || echo "Failed to parse"

echo ""
echo "=== Step 3: Add A records for studio-api-dev ==="
# Get the IPs from studio-dev records
IPS=$(echo "$RECORDS" | python3 -c "
import sys, json
d = json.load(sys.stdin)
records = d.get('records', [])
ips = [r['value'] for r in records if r.get('name') == 'studio-dev' and r.get('type') == 'A']
for ip in ips:
    print(ip)
" 2>/dev/null || echo "")

echo "IPs to add: $IPS"

for IP in $IPS; do
  echo "Adding A record: studio-api-dev -> $IP"
  CREATE_RESPONSE=$(curl -s -X POST \
    -H "Auth-API-Token: ${DNS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"value\":\"${IP}\",\"ttl\":300,\"type\":\"A\",\"name\":\"studio-api-dev\",\"zone_id\":\"${ZONE_ID}\"}" \
    "https://dns.hetzner.com/api/v1/records" 2>&1)
  echo "$CREATE_RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); r=d.get('record',{}); print(f'Created: {r.get(\"id\",\"\")} {r.get(\"name\",\"\")} -> {r.get(\"value\",\"\")}')" 2>/dev/null || echo "Response: $(echo $CREATE_RESPONSE | head -c 200)"
done

echo ""
echo "=== Step 4: Verify DNS propagation ==="
sleep 10
echo "Resolving studio-api-dev.keybuzz.io..."
dig +short studio-api-dev.keybuzz.io 2>/dev/null || nslookup studio-api-dev.keybuzz.io 2>/dev/null | tail -3

echo ""
echo "DONE"
