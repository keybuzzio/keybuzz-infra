#!/bin/bash
set -e
NS=keybuzz-studio-api-dev
kubectl patch secret keybuzz-studio-api-llm -n $NS --type=merge -p '{"data":{"LLM_TIMEOUT_MS":"OTAwMDA="}}'
echo "Secret patched (timeout=90000ms)"
kubectl rollout restart deployment/keybuzz-studio-api -n $NS
echo "Restart triggered, waiting..."
sleep 20
kubectl rollout status deployment/keybuzz-studio-api -n $NS --timeout=60s
echo "Done"
