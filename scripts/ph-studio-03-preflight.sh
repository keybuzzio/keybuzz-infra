#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "  PH-STUDIO-03 — PREFLIGHT DEV"
echo "=========================================="

echo ""
echo "=== 1. Pods DEV ==="
kubectl get pods -n keybuzz-studio-dev
echo ""
kubectl get pods -n keybuzz-studio-api-dev | grep -v solver

echo ""
echo "=== 2. Health ==="
kubectl run pf-health --namespace=keybuzz-studio-api-dev \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -s http://keybuzz-studio-api.keybuzz-studio-api-dev.svc.cluster.local:80/health 2>&1 | tail -3

echo ""
echo "=== 3. Ready ==="
kubectl run pf-ready --namespace=keybuzz-studio-api-dev \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -s http://keybuzz-studio-api.keybuzz-studio-api-dev.svc.cluster.local:80/ready 2>&1 | tail -3

echo ""
echo "=== 4. HTTPS Frontend ==="
kubectl run pf-fe --namespace=keybuzz-studio-dev \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -sI --max-time 10 https://studio-dev.keybuzz.io 2>&1 | grep -E "^HTTP|content-type" | head -3

echo ""
echo "=== 5. Images actuelles ==="
kubectl get deployment keybuzz-studio -n keybuzz-studio-dev -o jsonpath='{.spec.template.spec.containers[0].image}'; echo ""
kubectl get deployment keybuzz-studio-api -n keybuzz-studio-api-dev -o jsonpath='{.spec.template.spec.containers[0].image}'; echo ""

echo ""
echo "=== 6. Restarts ==="
kubectl get pods -n keybuzz-studio-dev -o jsonpath='{range .items[*]}{.metadata.name}{" restarts="}{range .status.containerStatuses[*]}{.restartCount}{end}{"\n"}{end}'
kubectl get pods -n keybuzz-studio-api-dev -o jsonpath='{range .items[*]}{.metadata.name}{" restarts="}{range .status.containerStatuses[*]}{.restartCount}{end}{"\n"}{end}' | grep -v solver

echo ""
echo "=== 7. Docker images on bastion ==="
docker images | grep keybuzz-studio

echo ""
echo "=== 8. GHCR login check ==="
docker pull ghcr.io/keybuzzio/keybuzz-studio:v0.1.0-dev 2>&1 | tail -2

echo ""
echo "=== 9. DNS PROD check ==="
dig +short studio.keybuzz.io 2>/dev/null || echo "(no record)"
echo ""
dig +short studio-api.keybuzz.io 2>/dev/null || echo "(no record)"

echo ""
echo "=== 10. Existing PROD namespaces? ==="
kubectl get namespace | grep studio-prod || echo "No PROD namespaces yet"

echo ""
echo "=========================================="
echo "  PREFLIGHT COMPLETE"
echo "=========================================="
