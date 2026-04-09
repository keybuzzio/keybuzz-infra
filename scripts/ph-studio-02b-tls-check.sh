#!/bin/bash
set -euo pipefail

echo "=== Certificates ==="
kubectl get certificate -A | grep studio

echo ""
echo "=== Challenges ==="
kubectl get challenges -A 2>/dev/null | grep studio || echo "No challenges"

echo ""
echo "=== API cert detail ==="
kubectl describe certificate keybuzz-studio-api-tls -n keybuzz-studio-api-dev 2>/dev/null | grep -E "Status|Message|Reason|Ready|Not After|Not Before|Type" | head -15

echo ""
echo "=== Frontend cert detail ==="
kubectl describe certificate keybuzz-studio-tls -n keybuzz-studio-dev 2>/dev/null | grep -E "Status|Message|Reason|Ready|Not After|Not Before|Type" | head -10

echo ""
echo "=== TLS Secrets ==="
kubectl get secret keybuzz-studio-tls -n keybuzz-studio-dev -o jsonpath='{.type}' 2>/dev/null; echo ""
kubectl get secret keybuzz-studio-api-tls -n keybuzz-studio-api-dev -o jsonpath='{.type}' 2>/dev/null; echo ""

echo ""
echo "=== HTTPS Frontend test ==="
kubectl run curl-tls-final-fe --namespace=keybuzz-studio-dev \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -sI --max-time 10 https://studio-dev.keybuzz.io 2>&1 | grep -E "HTTP|content-type|location" | head -5

echo ""
echo "=== HTTPS API test ==="
kubectl run curl-tls-final-api --namespace=keybuzz-studio-api-dev \
  --image=curlimages/curl --rm -it --restart=Never \
  -- curl -s --max-time 10 https://studio-api-dev.keybuzz.io/health 2>&1 | tail -3

echo ""
echo "=== Orders ==="
kubectl get orders -A 2>/dev/null | grep studio || echo "No orders"

echo ""
echo "DONE"
