#!/bin/bash
set -e

NS=keybuzz-studio-api-prod
REGISTRY=ghcr.io/keybuzzio

echo "=== G1: Tag hotfix for PROD ==="
docker tag ghcr.io/keybuzzio/keybuzz-studio-api:v0.8.1-dev ghcr.io/keybuzzio/keybuzz-studio-api:v0.8.1-prod
docker push ghcr.io/keybuzzio/keybuzz-studio-api:v0.8.1-prod
echo "Image pushed: v0.8.1-prod"

echo ""
echo "=== G2: Update LLM timeout ==="
kubectl patch secret keybuzz-studio-api-llm -n $NS --type=merge -p '{"data":{"LLM_TIMEOUT_MS":"OTAwMDA="}}'
echo "Timeout patched to 90000ms"

echo ""
echo "=== G3: Deploy ==="
kubectl set image deployment/keybuzz-studio-api keybuzz-studio-api=$REGISTRY/keybuzz-studio-api:v0.8.1-prod -n $NS
echo "Waiting for rollout..."
sleep 15
kubectl rollout status deployment/keybuzz-studio-api -n $NS --timeout=60s

echo ""
echo "=== G4: Verify ==="
kubectl get pods -n $NS
echo ""
curl -s --max-time 5 https://studio-api.keybuzz.io/health
echo ""
echo "=== HOTFIX PROMOTION COMPLETE ==="
