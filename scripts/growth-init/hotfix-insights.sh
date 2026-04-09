#!/bin/bash
set -e
NS=keybuzz-studio-api-dev
REGISTRY=registry.keybuzz.io

echo "=== Building API fix ==="
cd /root/V3/keybuzz-studio-api
docker build -t $REGISTRY/keybuzz-studio-api:v0.8.1-dev .
docker push $REGISTRY/keybuzz-studio-api:v0.8.1-dev
echo "Image pushed"

echo "=== Updating deployment ==="
kubectl set image deployment/keybuzz-studio-api keybuzz-studio-api=$REGISTRY/keybuzz-studio-api:v0.8.1-dev -n $NS
kubectl rollout status deployment/keybuzz-studio-api -n $NS --timeout=60s
echo "=== Deployed ==="
