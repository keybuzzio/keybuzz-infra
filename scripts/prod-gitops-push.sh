#!/bin/bash
set -e

echo "=== Update PROD deployment.yaml ==="
sed -i 's|ghcr.io/keybuzzio/keybuzz-api:v3.5.96-ph85-ops-action-center-prod|ghcr.io/keybuzzio/keybuzz-api:v3.5.97-fix-mime-truncation-prod|' /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml
grep 'image:' /opt/keybuzz/keybuzz-infra/k8s/keybuzz-api-prod/deployment.yaml

echo ""
echo "=== Git commit + push ==="
cd /opt/keybuzz/keybuzz-infra
git add k8s/keybuzz-api-prod/deployment.yaml
git commit -m "fix(prod): MIME parser base64 truncation + PNG integrity check (v3.5.97)"
git pull --rebase origin main
git push origin main
echo "=== Done ==="
