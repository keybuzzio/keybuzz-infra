#!/bin/bash
API="https://api-dev.keybuzz.io"
TENANT="keybuzz-mnqnjna8"

echo "1. Disconnect current..."
curl -s -X POST -H "X-User-Email: ludo.gonthier@gmail.com" -H "X-Tenant-Id: $TENANT" -H "Content-Type: application/json" -d '{}' "$API/shopify/disconnect"
echo ""

echo "2. Get new OAuth URL (managed install)..."
RESULT=$(curl -s -X POST -H "X-User-Email: ludo.gonthier@gmail.com" -H "X-Tenant-Id: $TENANT" -H "Content-Type: application/json" -d '{"shopDomain":"keybuzz-dev.myshopify.com"}' "$API/shopify/connect")
echo "$RESULT"
