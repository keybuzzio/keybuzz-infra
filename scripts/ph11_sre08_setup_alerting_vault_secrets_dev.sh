#!/bin/bash
# PH11-SRE-08: Setup Vault secrets for alerting (DEV)
# Idempotent - can be re-run safely

set -euo pipefail

echo "=== Creating Vault secrets for alerting ==="

# Create Slack secret with placeholders
ssh root@10.0.0.150 'export VAULT_ADDR=https://127.0.0.1:8200; export VAULT_SKIP_VERIFY=true; vault kv put secret/keybuzz/observability/slack/dev webhook_url="CHANGE_ME" channel="#alerts-dev"'

# Create SMTP secret using internal relay
ssh root@10.0.0.150 'export VAULT_ADDR=https://127.0.0.1:8200; export VAULT_SKIP_VERIFY=true; vault kv put secret/keybuzz/observability/smtp/dev host="10.0.0.160" port="25" username="" password="" from="alerts@keybuzz.io" to_default="sre@keybuzz.io" require_tls="false"'

echo "=== Verifying ==="
ssh root@10.0.0.150 'export VAULT_ADDR=https://127.0.0.1:8200; export VAULT_SKIP_VERIFY=true; vault kv list secret/keybuzz/observability/'

echo "=== DONE ==="