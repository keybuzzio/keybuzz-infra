#!/bin/bash
set -e

DEPLOY="/opt/keybuzz/keybuzz-infra/k8s/keybuzz-client-prod/deployment.yaml"

echo "=== Update PROD deployment.yaml ==="
sed -i 's|ghcr.io/keybuzzio/keybuzz-client:v3.5.49-fix-status-tenantid-prod|ghcr.io/keybuzzio/keybuzz-client:v3.5.50-light-theme-default-prod|' "$DEPLOY"
grep 'image:' "$DEPLOY" | head -1

echo ""
echo "=== Git commit + push ==="
cd /opt/keybuzz/keybuzz-infra
git add k8s/keybuzz-client-prod/deployment.yaml
git commit -m "feat(prod): default theme light mode (v3.5.50) - aligned with DEV"
git pull --rebase origin main
git push origin main

echo ""
echo "=== Deploy PROD ==="
kubectl set image deploy/keybuzz-client keybuzz-client=ghcr.io/keybuzzio/keybuzz-client:v3.5.50-light-theme-default-prod -n keybuzz-client-prod
kubectl rollout status deployment/keybuzz-client -n keybuzz-client-prod --timeout=120s

echo ""
echo "=== Verify PROD ==="
kubectl get deployment keybuzz-client -n keybuzz-client-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
kubectl get pods -n keybuzz-client-prod -l app=keybuzz-client -o wide

echo ""
echo "=== DEV/PROD alignment ==="
echo "DEV Client:"
kubectl get deployment keybuzz-client -n keybuzz-client-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
echo "PROD Client:"
kubectl get deployment keybuzz-client -n keybuzz-client-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
echo "DEV API:"
kubectl get deployment keybuzz-api -n keybuzz-api-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
echo "PROD API:"
kubectl get deployment keybuzz-api -n keybuzz-api-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
echo "DEV Outbound:"
kubectl get deployment keybuzz-outbound-worker -n keybuzz-api-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
echo "PROD Outbound:"
kubectl get deployment keybuzz-outbound-worker -n keybuzz-api-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
echo "DEV Backend:"
kubectl get deployment keybuzz-backend -n keybuzz-backend-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
echo "PROD Backend:"
kubectl get deployment keybuzz-backend -n keybuzz-backend-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
