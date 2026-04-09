#!/bin/bash
set -euo pipefail

sleep 30

echo "=== PODS ==="
kubectl get pods -n keybuzz-studio-dev -o wide
echo ""
kubectl get pods -n keybuzz-studio-api-dev -o wide

echo ""
echo "=== SERVICES ==="
kubectl get svc -n keybuzz-studio-dev
kubectl get svc -n keybuzz-studio-api-dev

echo ""
echo "=== INGRESS ==="
kubectl get ingress -n keybuzz-studio-dev
kubectl get ingress -n keybuzz-studio-api-dev

echo ""
echo "=== HEALTH CHECK ==="
API_POD=$(kubectl get pods -n keybuzz-studio-api-dev -l app=keybuzz-studio-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$API_POD" ]; then
  echo "API Pod: $API_POD"
  kubectl exec -n keybuzz-studio-api-dev "$API_POD" -- wget -qO- http://localhost:4010/health 2>/dev/null && echo "" || echo "Health check failed"
else
  echo "No API pod found"
fi

echo ""
echo "=== LOGS FRONTEND ==="
kubectl logs -n keybuzz-studio-dev deployment/keybuzz-studio --tail=15 2>&1 || true

echo ""
echo "=== LOGS API ==="
kubectl logs -n keybuzz-studio-api-dev deployment/keybuzz-studio-api --tail=15 2>&1 || true

echo ""
echo "=== CERTIFICATES ==="
kubectl get certificate -n keybuzz-studio-dev 2>&1 || true
kubectl get certificate -n keybuzz-studio-api-dev 2>&1 || true
