#!/bin/bash
set -e

echo "=== PH-WEBSITE VALIDATION DEV v2 ==="
echo "Date: $(date)"

POD="keybuzz-website-7887b997c8-lzcd5"
NS="keybuzz-website-dev"

echo ""
echo "=== 1. Pod info ==="
kubectl get pod $POD -n $NS -o wide

echo ""
echo "=== 2. Get basic auth secret ==="
kubectl get secret -n $NS 2>/dev/null | head -10
kubectl get ingress -n $NS -o yaml 2>/dev/null | grep -A2 "auth-" || echo "(no auth annotations)"

echo ""
echo "=== 3. Get pod IP for direct test ==="
POD_IP=$(kubectl get pod $POD -n $NS -o jsonpath='{.status.podIP}')
echo "Pod IP: $POD_IP"

echo ""
echo "=== 4. Test from within cluster via kubectl exec in a debug pod ==="
echo "--- Static file test (icon.png) ---"
kubectl exec -n $NS $POD -- wget -q -O /dev/null --server-response "http://localhost:3000/brand/icon.png" 2>&1 | head -5 || \
  kubectl exec -n $NS $POD -- sh -c "wget -q -S -O /dev/null 'http://localhost:3000/brand/icon.png' 2>&1 | head -5" || echo "wget failed"

echo ""
echo "--- Optimizer test (icon.png via /_next/image) ---"
kubectl exec -n $NS $POD -- wget -q -O /dev/null --server-response 'http://localhost:3000/_next/image?url=%2Fbrand%2Ficon.png&w=96&q=75' 2>&1 | head -10 || echo "wget optimizer failed"

echo ""
echo "--- Optimizer test (ludovic.jpg) ---"
kubectl exec -n $NS $POD -- wget -q -O /dev/null --server-response 'http://localhost:3000/_next/image?url=%2Fimages%2Fludovic.jpg&w=640&q=75' 2>&1 | head -10 || echo "wget optimizer failed"

echo ""
echo "--- Optimizer test (darty.png) ---"
kubectl exec -n $NS $POD -- wget -q -O /dev/null --server-response 'http://localhost:3000/_next/image?url=%2Fbrand%2Fmarketplaces%2Fdarty.png&w=256&q=75' 2>&1 | head -10 || echo "wget optimizer failed"

echo ""
echo "=== 5. Cache directory after requests ==="
kubectl exec -n $NS $POD -- ls -laR /app/.next/cache/ 2>&1 | head -40

echo ""
echo "=== 6. Second request — cache should be HIT ==="
echo "--- icon.png 2nd request ---"
kubectl exec -n $NS $POD -- wget -q -O /dev/null --server-response 'http://localhost:3000/_next/image?url=%2Fbrand%2Ficon.png&w=96&q=75' 2>&1 | grep -i "cache" || echo "(no cache header)"
echo "--- darty.png 2nd request ---"
kubectl exec -n $NS $POD -- wget -q -O /dev/null --server-response 'http://localhost:3000/_next/image?url=%2Fbrand%2Fmarketplaces%2Fdarty.png&w=256&q=75' 2>&1 | grep -i "cache" || echo "(no cache header)"

echo ""
echo "=== 7. Pod logs after all requests ==="
kubectl logs -n $NS $POD --tail=30 2>&1

echo ""
echo "=== VALIDATION COMPLETE ==="
