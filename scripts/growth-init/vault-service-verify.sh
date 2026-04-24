#!/bin/bash
set -e

echo "--- Main API DEV: Vault env vars ---"
kubectl exec -n keybuzz-api-dev deploy/keybuzz-api -- printenv VAULT_ADDR 2>/dev/null || echo "MISSING"
kubectl exec -n keybuzz-api-dev deploy/keybuzz-api -- sh -c 'echo "VAULT_TOKEN: ${VAULT_TOKEN:0:10}..."' 2>/dev/null || echo "MISSING"

echo ""
echo "--- Main API PROD: Vault env vars ---"
kubectl exec -n keybuzz-api-prod deploy/keybuzz-api -- printenv VAULT_ADDR 2>/dev/null || echo "MISSING"
kubectl exec -n keybuzz-api-prod deploy/keybuzz-api -- sh -c 'echo "VAULT_TOKEN: ${VAULT_TOKEN:0:10}..."' 2>/dev/null || echo "MISSING"

echo ""
echo "--- Backend PROD: Vault env vars ---"
kubectl exec -n keybuzz-backend-prod deploy/keybuzz-backend -- printenv VAULT_ADDR 2>/dev/null || echo "MISSING"
kubectl exec -n keybuzz-backend-prod deploy/keybuzz-backend -- sh -c 'echo "VAULT_TOKEN: ${VAULT_TOKEN:0:10}..."' 2>/dev/null || echo "MISSING"

echo ""
echo "--- Studio API DEV: Vault env vars (should be MISSING) ---"
kubectl exec -n keybuzz-studio-api-dev deploy/keybuzz-studio-api -- printenv VAULT_ADDR 2>/dev/null || echo "VAULT_ADDR: ABSENT (expected)"
kubectl exec -n keybuzz-studio-api-dev deploy/keybuzz-studio-api -- printenv VAULT_TOKEN 2>/dev/null || echo "VAULT_TOKEN: ABSENT (expected)"

echo ""
echo "--- Studio API PROD: Vault env vars (should be MISSING) ---"
kubectl exec -n keybuzz-studio-api-prod deploy/keybuzz-studio-api -- printenv VAULT_ADDR 2>/dev/null || echo "VAULT_ADDR: ABSENT (expected)"
kubectl exec -n keybuzz-studio-api-prod deploy/keybuzz-studio-api -- printenv VAULT_TOKEN 2>/dev/null || echo "VAULT_TOKEN: ABSENT (expected)"

echo ""
echo "--- Website PROD: Vault env vars (should be MISSING) ---"
kubectl exec -n keybuzz-website-prod deploy/keybuzz-website -- printenv VAULT_ADDR 2>/dev/null || echo "VAULT_ADDR: ABSENT (expected)"
kubectl exec -n keybuzz-website-prod deploy/keybuzz-website -- printenv VAULT_TOKEN 2>/dev/null || echo "VAULT_TOKEN: ABSENT (expected)"

echo ""
echo "=== VERIFICATION DONE ==="
