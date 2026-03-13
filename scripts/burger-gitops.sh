#!/bin/bash
set -e

DEPLOY="/opt/keybuzz/keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml"

echo "=== Update DEV deployment.yaml ==="
sed -i 's|ghcr.io/keybuzzio/keybuzz-client:v3.5.50-light-theme-default-dev|ghcr.io/keybuzzio/keybuzz-client:v3.5.51-always-burger-menu-dev|' "$DEPLOY"
grep 'image:' "$DEPLOY" | head -1

echo ""
echo "=== Git commit + push ==="
cd /opt/keybuzz/keybuzz-infra
git add k8s/keybuzz-client-dev/deployment.yaml
git commit -m "feat(dev): always burger menu sidebar (v3.5.51)"
git pull --rebase origin main
git push origin main

echo ""
echo "=== Deploy DEV ==="
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.51-always-burger-menu-dev -n keybuzz-client-dev
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-dev --timeout=120s

echo ""
echo "=== Verify ==="
kubectl get deployment keybuzz-client -n keybuzz-client-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
kubectl get pods -n keybuzz-client-dev -l app=keybuzz-client
