#!/bin/bash
set -e

echo "=== PH-WEBSITE-SOCIALS DEPLOY DEV ==="
echo "Date: $(date)"

cd /opt/keybuzz/keybuzz-infra
git pull origin main --ff-only

echo ""
echo "=== Manifest image ==="
grep "image:" k8s/website-dev/deployment.yaml

echo ""
echo "=== Apply ==="
kubectl apply -f k8s/website-dev/deployment.yaml

echo ""
echo "=== Rollout ==="
kubectl rollout status deployment/keybuzz-website -n keybuzz-website-dev --timeout=120s

echo ""
echo "=== Pods ==="
kubectl get pods -n keybuzz-website-dev -o wide

echo ""
echo "=== New image ==="
kubectl get deploy keybuzz-website -n keybuzz-website-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

echo ""
echo "=== DEPLOY DEV DONE ==="
