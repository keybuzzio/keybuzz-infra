#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=$(cat /root/.vault-cluster-root-token 2>/dev/null || echo "")

echo "=== Search Vault for Hetzner DNS token ==="
for p in "secret/keybuzz/hetzner" "secret/keybuzz/infra/hetzner" "secret/keybuzz/dns" "secret/hetzner" "secret/keybuzz/infra/dns"; do
  R=$(vault kv get -format=json "$p" 2>/dev/null || echo "")
  if [ -n "$R" ]; then
    echo "Found: $p"
    echo "$R" | jq '.data.data | keys[]'
  fi
done

echo ""
echo "=== Search bastion for Hetzner token ==="
grep -rl "hetzner\|HETZNER\|dns_token\|DNS_TOKEN" /opt/keybuzz/keybuzz-infra/ 2>/dev/null | head -10

echo ""
echo "=== Check environment for Hetzner ==="
grep -i "HETZNER\|dns_api" /root/.bashrc /root/.bash_profile /root/.profile 2>/dev/null || echo "none"

echo ""
echo "=== Check cert-manager issuer config ==="
kubectl get clusterissuer letsencrypt-prod -o yaml 2>/dev/null | head -30

echo ""
echo "=== Check scripts for DNS setup patterns ==="
grep -rl "hetzner.*dns\|dns.*hetzner\|dns.*api" /opt/keybuzz/keybuzz-infra/scripts/ 2>/dev/null | head -5

echo ""
echo "=== Check ansible for hetzner DNS ==="
grep -rl "hetzner\|dns_token" /opt/keybuzz/keybuzz-infra/ansible/ 2>/dev/null | head -5

echo ""
echo "DONE"
