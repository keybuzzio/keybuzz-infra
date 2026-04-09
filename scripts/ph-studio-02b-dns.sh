#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=$(cat /root/.vault-cluster-root-token 2>/dev/null || echo "")

echo "=== Check external-dns in K8s ==="
kubectl get deployment -A 2>/dev/null | grep -i "external-dns\|cloudflare\|dns" || echo "No external-dns controller"

echo ""
echo "=== Check for Cloudflare API key in Vault ==="
for p in "secret/keybuzz/cloudflare" "secret/keybuzz/infra/cloudflare" "secret/keybuzz/dns" "secret/cloudflare"; do
  R=$(vault kv get -format=json "$p" 2>/dev/null || echo "")
  if [ -n "$R" ]; then
    echo "Found: $p"
    echo "$R" | jq '.data.data | keys[]'
  fi
done

echo ""
echo "=== Check for Cloudflare in K8s secrets ==="
kubectl get secrets -A 2>/dev/null | grep -i cloudflare || echo "No cloudflare secrets in K8s"

echo ""
echo "=== DNS resolution comparison ==="
echo "studio-dev.keybuzz.io:"
dig +short studio-dev.keybuzz.io 2>/dev/null || nslookup studio-dev.keybuzz.io 2>/dev/null | tail -3

echo ""
echo "studio-api-dev.keybuzz.io:"
dig +short studio-api-dev.keybuzz.io 2>/dev/null || nslookup studio-api-dev.keybuzz.io 2>/dev/null | tail -3

echo ""
echo "keybuzz.io nameservers:"
dig NS keybuzz.io +short 2>/dev/null || echo "dig not available"

echo ""
echo "=== Check existing DNS records for keybuzz.io ==="
dig A studio-dev.keybuzz.io +short 2>/dev/null
dig A studio-api-dev.keybuzz.io +short 2>/dev/null
dig A client-dev.keybuzz.io +short 2>/dev/null
dig A backend-dev.keybuzz.io +short 2>/dev/null

echo ""
echo "=== Check if there's a Cloudflare token in env ==="
env | grep -i CLOUDFLARE 2>/dev/null || echo "No CF env vars"
cat /root/.cloudflare* 2>/dev/null || echo "No cloudflare config"

echo ""
echo "DONE"
