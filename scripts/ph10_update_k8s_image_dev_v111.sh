#!/bin/bash
set -e

LOG_FILE="/opt/keybuzz/logs/ph10-ui/update-images-v111-dev.log"
mkdir -p "$(dirname "$LOG_FILE")"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=========================================="
echo "Update K8s manifest DEV to v1.0.11-dev"
echo "Date: $(date)"
echo "=========================================="

cd /opt/keybuzz/keybuzz-infra

echo ""
echo "1) Backup current manifest..."
cp k8s/keybuzz-admin-dev/deployment.yaml k8s/keybuzz-admin-dev/deployment.yaml.backup

echo "✅ Backup créé"

echo ""
echo "2) Update image in deployment.yaml..."
sed -i 's|image: ghcr.io/keybuzzio/keybuzz-admin:.*|image: ghcr.io/keybuzzio/keybuzz-admin:v1.0.11-dev|' k8s/keybuzz-admin-dev/deployment.yaml

echo "✅ Image updated"

echo ""
echo "3) Verify change..."
grep "image: ghcr.io/keybuzzio/keybuzz-admin" k8s/keybuzz-admin-dev/deployment.yaml | head -1

echo ""
echo "4) Git add, commit, push..."
git add k8s/keybuzz-admin-dev/deployment.yaml

git commit -m "chore: bump keybuzz-admin dev image to v1.0.11-dev

- Update admin-dev deployment to v1.0.11-dev
- Includes PH11-06B.5C UI (onboarding & monitoring)
- Health checks integration
- Demo connection button (DEV mode)"

echo "✅ Commit créé"

git push origin main

COMMIT_SHA=$(git rev-parse HEAD)

echo "✅ Pushed to GitHub"
echo "   SHA: $COMMIT_SHA"

echo ""
echo "=========================================="
echo "✅ UPDATE MANIFEST TERMINÉ"
echo "=========================================="
echo ""
echo "Commit SHA: $COMMIT_SHA"
echo "File: k8s/keybuzz-admin-dev/deployment.yaml"
echo ""
