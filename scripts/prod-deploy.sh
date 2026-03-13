#!/bin/bash
cd /opt/keybuzz/keybuzz-infra

# Update PROD deployment.yaml
sed -i 's|ghcr.io/keybuzzio/keybuzz-client:v3.5.81-ph63b-softguard-prod|ghcr.io/keybuzzio/keybuzz-client:v3.5.49-fix-status-tenantid-prod|' k8s/keybuzz-client-prod/deployment.yaml

echo "=== PROD image ==="
grep 'image:' k8s/keybuzz-client-prod/deployment.yaml

# Git commit and push
git add k8s/keybuzz-client-prod/deployment.yaml
git commit -m "fix: pass tenantId to status/sav-status updates - PROD v3.5.49-fix-status-tenantid-prod"
git pull --rebase origin main
git push origin main
