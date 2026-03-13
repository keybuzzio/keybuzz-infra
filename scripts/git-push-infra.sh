#!/bin/bash
set -e
cd /opt/keybuzz/keybuzz-infra
git add k8s/keybuzz-api-dev/deployment.yaml
git commit -m "fix: MIME parser base64 truncation + PNG integrity check (v3.5.97)"
git pull --rebase origin main
git push origin main
echo "=== Git push done ==="
