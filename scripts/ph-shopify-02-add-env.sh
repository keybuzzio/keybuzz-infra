#!/bin/bash
# Add Shopify env vars to API DEV deployment
set -e

echo "=== Adding Shopify env vars ==="

# Patch the deployment to add env vars
kubectl set env deployment/keybuzz-api -n keybuzz-api-dev \
  SHOPIFY_CLIENT_ID="" \
  SHOPIFY_CLIENT_SECRET="" \
  SHOPIFY_ENCRYPTION_KEY="0c332271a130226ffdc5a0a2f9092474e92aeff6ed584814dfa998ac414880fc" \
  SHOPIFY_REDIRECT_URI="https://api-dev.keybuzz.io/shopify/callback" \
  SHOPIFY_CLIENT_REDIRECT_URL="https://client-dev.keybuzz.io/channels"

echo "=== Env vars added ==="
kubectl get deployment keybuzz-api -n keybuzz-api-dev -o jsonpath='{range .spec.template.spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}' | grep -i shopify
