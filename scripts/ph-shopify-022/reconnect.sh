#!/bin/bash
echo "=== Shopify OAuth Reconnect ==="
RESULT=$(curl -s -w '\nHTTP:%{http_code}' \
  -X POST \
  -H "X-User-Email: ludo.gonthier@gmail.com" \
  -H "X-Tenant-Id: keybuzz-mnqnjna8" \
  -H "Content-Type: application/json" \
  -d '{"shopDomain":"keybuzz-dev.myshopify.com"}' \
  "https://api-dev.keybuzz.io/shopify/connect")
echo "$RESULT"
