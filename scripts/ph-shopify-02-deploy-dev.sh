#!/bin/bash
set -e
echo "=== Deploying API + Client DEV ==="

kubectl set image deploy/keybuzz-api keybuzz-api=ghcr.io/keybuzzio/keybuzz-api:v3.5.226-ph-shopify-02-dev -n keybuzz-api-dev
echo "API image set"

kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.226-ph-shopify-02-dev -n keybuzz-client-dev
echo "Client image set"

kubectl rollout status deployment/keybuzz-api -n keybuzz-api-dev --timeout=120s
echo "API rollout complete"

kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev --timeout=120s
echo "Client rollout complete"

echo ""
echo "=== Verifying ==="
kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api -o wide
kubectl get pods -n keybuzz-client-dev -l app=keybuzz-client -o wide

echo ""
echo "=== DEV DEPLOYMENT COMPLETE ==="
