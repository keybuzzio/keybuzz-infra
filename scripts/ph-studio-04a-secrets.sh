#!/bin/bash
set -euo pipefail

export VAULT_ADDR=http://10.0.0.150:8200
export VAULT_TOKEN=VAULT_TOKEN_REDACTED

BS_DEV=$(openssl rand -hex 32)
BS_PROD=$(openssl rand -hex 32)

echo "--- Creating DEV auth secrets ---"
vault kv put secret/keybuzz/dev/studio-auth \
  bootstrap_secret="$BS_DEV" \
  smtp_from="KeyBuzz Studio <studio@keybuzz.io>"
echo "DEV: bootstrap_secret created (${#BS_DEV} chars)"

echo "--- Creating PROD auth secrets ---"
vault kv put secret/keybuzz/prod/studio-auth \
  bootstrap_secret="$BS_PROD" \
  smtp_from="KeyBuzz Studio <studio@keybuzz.io>"
echo "PROD: bootstrap_secret created (${#BS_PROD} chars)"

echo "--- Reading back DEV ---"
vault kv get -field=bootstrap_secret secret/keybuzz/dev/studio-auth | head -c 8
echo "...***redacted***"

echo "--- Reading SMTP config from existing infra ---"
vault kv get secret/keybuzz/ses 2>/dev/null && echo "SES secret found" || echo "SES secret not found"

echo "=== SECRETS DONE ==="
