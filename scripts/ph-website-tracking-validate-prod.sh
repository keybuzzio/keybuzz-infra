#!/bin/bash
set -e

echo "=== VALIDATE TRACKING PROD ==="
echo "Date: $(date)"

echo ""
echo "=== 1. Pod status ==="
kubectl get pods -n keybuzz-website-prod -l app=keybuzz-website -o wide

echo ""
echo "=== 2. Pod logs ==="
kubectl logs -n keybuzz-website-prod deployment/keybuzz-website --tail=10

echo ""
echo "=== 3. Check www.keybuzz.pro HTTP ==="
STATUS=$(curl -sk -o /dev/null -w '%{http_code}' https://www.keybuzz.pro/)
echo "HTTP status: $STATUS"

echo ""
echo "=== 4. Check GA + Meta Pixel in PROD HTML ==="
BODY=$(curl -sk https://www.keybuzz.pro/)
echo "GA gtag.js: $(echo "$BODY" | grep -c 'gtag/js' || echo 0)"
echo "GA ID G-R3QQDYEBFG: $(echo "$BODY" | grep -c 'R3QQDYEBFG' || echo 0)"

echo ""
echo "=== 5. Check JS bundles for tracking ==="
POD=$(kubectl get pods -n keybuzz-website-prod -l app=keybuzz-website -o jsonpath='{.items[0].metadata.name}')
echo "Pod: $POD"

echo "-- fbevents in bundles:"
kubectl exec -n keybuzz-website-prod "$POD" -- sh -c "grep -rl 'fbevents' /app/.next/static/ 2>/dev/null | head -3 || echo 'NOT FOUND'"

echo "-- Meta Pixel ID in bundles:"
kubectl exec -n keybuzz-website-prod "$POD" -- sh -c "grep -rl '1234164602194748' /app/.next/static/ 2>/dev/null | head -3 || echo 'NOT FOUND'"

echo "-- GA ID in bundles:"
kubectl exec -n keybuzz-website-prod "$POD" -- sh -c "grep -rl 'R3QQDYEBFG' /app/.next/static/ 2>/dev/null | head -3 || echo 'NOT FOUND'"

echo "-- view_pricing in bundles:"
kubectl exec -n keybuzz-website-prod "$POD" -- sh -c "grep -rl 'view_pricing' /app/.next/static/ 2>/dev/null | head -3 || echo 'NOT FOUND'"

echo "-- gclid in bundles:"
kubectl exec -n keybuzz-website-prod "$POD" -- sh -c "grep -rl 'gclid' /app/.next/static/ 2>/dev/null | head -3 || echo 'NOT FOUND'"

echo "-- contact_submit in bundles:"
kubectl exec -n keybuzz-website-prod "$POD" -- sh -c "grep -rl 'contact_submit' /app/.next/static/ 2>/dev/null | head -3 || echo 'NOT FOUND'"

echo ""
echo "=== 6. No EACCES errors ==="
kubectl logs -n keybuzz-website-prod deployment/keybuzz-website --tail=50 | grep -i 'eacces\|error\|WARN' || echo "No errors found"

echo ""
echo "=== PROD VALIDATION DONE ==="
