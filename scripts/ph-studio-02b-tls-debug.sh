#!/bin/bash
set -euo pipefail

echo "=== Challenge details ==="
kubectl describe challenge -n keybuzz-studio-api-dev 2>/dev/null | tail -30

echo ""
echo "=== ACME solver pod ==="
kubectl get pods -n keybuzz-studio-api-dev | grep solver

echo ""
echo "=== Solver service ==="
kubectl get svc -n keybuzz-studio-api-dev | grep solver

echo ""
echo "=== DNS check from cluster ==="
kubectl run dns-check --namespace=keybuzz-studio-api-dev \
  --image=curlimages/curl --rm -it --restart=Never \
  -- sh -c "nslookup studio-api-dev.keybuzz.io 2>&1 || echo 'nslookup failed'; echo '---'; curl -sI http://studio-api-dev.keybuzz.io/.well-known/acme-challenge/ 2>&1 | head -5" 2>&1 | tail -15

echo ""
echo "=== Test ACME solver directly ==="
SOLVER_SVC=$(kubectl get svc -n keybuzz-studio-api-dev -l "acme.cert-manager.io/http01-solver=true" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$SOLVER_SVC" ]; then
  SOLVER_PORT=$(kubectl get svc "$SOLVER_SVC" -n keybuzz-studio-api-dev -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo "8089")
  echo "Solver service: $SOLVER_SVC port: $SOLVER_PORT"
fi

echo ""
echo "=== Ingress details ==="
kubectl describe ingress keybuzz-studio-api -n keybuzz-studio-api-dev 2>/dev/null | tail -20

echo ""
echo "=== cert-manager logs (last 20 related to studio-api) ==="
kubectl logs -n cert-manager deployment/cert-manager --tail=50 2>/dev/null | grep -i "studio-api" | tail -10 || echo "no cert-manager logs"

echo ""
echo "DONE"
