#!/bin/bash
# PH-SHOPIFY-PROD-APP-SETUP-01 — Create Shopify secrets in PROD namespace
#
# USAGE (on bastion):
#   bash create-prod-secret.sh <CLIENT_ID> <CLIENT_SECRET>
#
# The ENCRYPTION_KEY is auto-generated (32 bytes hex) if not provided as $3.
# This script creates the K8s secret `keybuzz-shopify` in `keybuzz-api-prod`.
#
# IMPORTANT: Run this BEFORE promoting the API image to PROD.

set -euo pipefail

NAMESPACE="keybuzz-api-prod"
SECRET_NAME="keybuzz-shopify"

CLIENT_ID="${1:?Usage: $0 <CLIENT_ID> <CLIENT_SECRET> [ENCRYPTION_KEY]}"
CLIENT_SECRET="${2:?Usage: $0 <CLIENT_ID> <CLIENT_SECRET> [ENCRYPTION_KEY]}"
ENCRYPTION_KEY="${3:-$(openssl rand -hex 32)}"

echo "=== Creating Shopify secret in $NAMESPACE ==="
echo "  Secret name: $SECRET_NAME"
echo "  CLIENT_ID: ${CLIENT_ID:0:8}..."
echo "  CLIENT_SECRET: ***masked***"
echo "  ENCRYPTION_KEY: ${ENCRYPTION_KEY:0:8}... ($(echo -n "$ENCRYPTION_KEY" | wc -c) chars)"

kubectl create secret generic "$SECRET_NAME" \
  --namespace "$NAMESPACE" \
  --from-literal=SHOPIFY_CLIENT_ID="$CLIENT_ID" \
  --from-literal=SHOPIFY_CLIENT_SECRET="$CLIENT_SECRET" \
  --from-literal=SHOPIFY_ENCRYPTION_KEY="$ENCRYPTION_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "=== Verification ==="
kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data}' | python3 -c "
import json, sys
d = json.load(sys.stdin)
for k in d:
    print(f'  {k}: (set)')
"

echo ""
echo "Secret $SECRET_NAME created/updated in $NAMESPACE"
echo "SAVE THE ENCRYPTION_KEY SECURELY: $ENCRYPTION_KEY"
