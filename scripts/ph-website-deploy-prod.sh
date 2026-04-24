#!/bin/bash
set -e

echo "=== PH-WEBSITE DEPLOY PROD — GitOps ==="
echo "Date: $(date)"

echo ""
echo "=== 1. Pull latest infra manifest ==="
cd /opt/keybuzz/keybuzz-infra
git pull origin main --ff-only
echo ""

echo "=== 2. Verify manifest image tag ==="
grep "image:" k8s/website-prod/deployment.yaml
echo ""

echo "=== 3. Current pods BEFORE ==="
kubectl get pods -n keybuzz-website-prod -o wide
echo ""
echo "Current image:"
kubectl get deploy keybuzz-website -n keybuzz-website-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

echo ""
echo "=== 4. SCOPE CHECK — verify only website-prod is affected ==="
git diff --stat HEAD~1 | head -10
echo ""

echo "=== 5. Apply manifest ==="
kubectl apply -f k8s/website-prod/deployment.yaml
echo ""

echo "=== 6. Wait for rollout ==="
kubectl rollout status deployment/keybuzz-website -n keybuzz-website-prod --timeout=120s
echo ""

echo "=== 7. Pods AFTER ==="
kubectl get pods -n keybuzz-website-prod -o wide
echo ""
echo "New image:"
kubectl get deploy keybuzz-website -n keybuzz-website-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

echo ""
echo "=== DEPLOY PROD COMPLETE ==="
