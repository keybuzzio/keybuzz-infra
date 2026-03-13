#!/bin/bash
set -e

echo "=== Update deployment.yaml ==="
DEPLOY="/opt/keybuzz/keybuzz-infra/k8s/keybuzz-client-dev/deployment.yaml"
CURRENT=$(grep 'image:' "$DEPLOY" | head -1 | xargs)
echo "Current: $CURRENT"

sed -i 's|ghcr.io/keybuzzio/keybuzz-client:v3.5.49-fix-status-tenantid-dev|ghcr.io/keybuzzio/keybuzz-client:v3.5.50-light-theme-default-dev|' "$DEPLOY"
NEW=$(grep 'image:' "$DEPLOY" | head -1 | xargs)
echo "New: $NEW"

echo ""
echo "=== Git commit + push ==="
cd /opt/keybuzz/keybuzz-infra
git add k8s/keybuzz-client-dev/deployment.yaml
git commit -m "feat(dev): default theme light mode (v3.5.50)"
git pull --rebase origin main
git push origin main
echo "=== Done ==="
