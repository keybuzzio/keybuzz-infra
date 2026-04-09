#!/bin/bash
# Test remaining items
POD_CLIENT=$(kubectl get pods -n keybuzz-client-dev -l app=keybuzz-client --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
POD_API=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')

echo "Client pod: $POD_CLIENT"
echo "API pod: $POD_API"

echo ""
echo "--- Channels Registry BFF ---"
REGISTRY=$(kubectl exec -n keybuzz-client-dev "$POD_CLIENT" -- curl -s 'http://127.0.0.1:3000/api/channels/registry' 2>/dev/null)
if echo "$REGISTRY" | grep -q 'shopify'; then
  echo "  OK: Shopify in client registry"
else
  echo "  Result: $REGISTRY"
fi

echo ""
echo "--- Env vars ---"
kubectl exec -n keybuzz-api-dev "$POD_API" -- env 2>/dev/null | grep SHOPIFY

echo ""
echo "--- PROD non-regression ---"
POD_PROD=$(kubectl get pods -n keybuzz-api-prod -l app=keybuzz-api --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
echo "PROD pod: $POD_PROD"
PROD_HEALTH=$(kubectl exec -n keybuzz-api-prod "$POD_PROD" -- curl -s http://127.0.0.1:3001/health 2>/dev/null)
echo "PROD health: $PROD_HEALTH"
PROD_IMG=$(kubectl get deployment keybuzz-api -n keybuzz-api-prod -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
echo "PROD image: $PROD_IMG"
