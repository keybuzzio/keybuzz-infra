#!/bin/bash
set -e
echo "=== Test Shopify scopes post-TOML deploy ==="

API="https://api-dev.keybuzz.io"
TENANT="keybuzz-mnqnjna8"

echo ""
echo "1. Test /shopify/status..."
STATUS=$(curl -sf -H "X-User-Email: ludo.gonthier@gmail.com" -H "X-Tenant-Id: $TENANT" "$API/shopify/status" 2>&1 || echo "FAIL")
echo "   Status: $STATUS"

echo ""
echo "2. Test /shopify/orders/sync (triggers GraphQL order fetch)..."
SYNC=$(curl -sf -X POST -H "X-User-Email: ludo.gonthier@gmail.com" -H "X-Tenant-Id: $TENANT" -H "Content-Type: application/json" "$API/shopify/orders/sync" 2>&1 || echo "FAIL")
echo "   Sync: $SYNC"

echo ""
echo "3. Test /shopify/orders/list..."
LIST=$(curl -sf -H "X-User-Email: ludo.gonthier@gmail.com" -H "X-Tenant-Id: $TENANT" "$API/shopify/orders/list" 2>&1 || echo "FAIL")
echo "   Orders: $LIST"

echo ""
echo "4. Check API pod logs for Shopify..."
POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}')
echo "   Last 20 Shopify log lines:"
kubectl logs -n keybuzz-api-dev "$POD" --tail=50 2>/dev/null | grep -i shopify | tail -20

echo ""
echo "=== Done ==="
