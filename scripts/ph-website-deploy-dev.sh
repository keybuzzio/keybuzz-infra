#!/bin/bash
set -e

echo "=== PH-WEBSITE DEPLOY DEV — GitOps ==="
echo "Date: $(date)"

echo ""
echo "=== 1. Pull latest infra manifest ==="
cd /opt/keybuzz/keybuzz-infra
git pull origin main --ff-only
echo ""

echo "=== 2. Verify manifest image tag ==="
grep "image:" k8s/website-dev/deployment.yaml
echo ""

echo "=== 3. Current pods BEFORE ==="
kubectl get pods -n keybuzz-website-dev -o wide
echo ""
echo "Current image:"
kubectl get deploy keybuzz-website -n keybuzz-website-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

echo ""
echo "=== 4. Apply manifest ==="
kubectl apply -f k8s/website-dev/deployment.yaml
echo ""

echo "=== 5. Wait for rollout ==="
kubectl rollout status deployment/keybuzz-website -n keybuzz-website-dev --timeout=120s
echo ""

echo "=== 6. Pods AFTER ==="
kubectl get pods -n keybuzz-website-dev -o wide
echo ""
echo "New image:"
kubectl get deploy keybuzz-website -n keybuzz-website-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

echo ""
echo "=== DEPLOY DEV COMPLETE ==="
