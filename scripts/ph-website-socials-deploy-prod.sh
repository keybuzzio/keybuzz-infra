#!/bin/bash
set -e

echo "=== PH-WEBSITE-SOCIALS DEPLOY PROD ==="
echo "Date: $(date)"

cd /opt/keybuzz/keybuzz-infra
git pull origin main --ff-only

echo ""
echo "=== Manifest ==="
grep "image:" k8s/website-prod/deployment.yaml

echo ""
echo "=== Scope check ==="
git diff --stat HEAD~1

echo ""
echo "=== Apply ==="
kubectl apply -f k8s/website-prod/deployment.yaml

echo ""
echo "=== Rollout ==="
kubectl rollout status deployment/keybuzz-website -n keybuzz-website-prod --timeout=120s

echo ""
echo "=== Pods ==="
kubectl get pods -n keybuzz-website-prod -o wide

echo ""
echo "=== Image ==="
kubectl get deploy keybuzz-website -n keybuzz-website-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

echo ""
echo "=== DEPLOY PROD DONE ==="
