#!/bin/bash
set -e

echo "=== PH-T6.1 VALIDATION PROD ==="
echo "Date: $(date)"

echo ""
echo "=== 1. Pod status ==="
kubectl get pods -n keybuzz-website-prod -l app=keybuzz-website -o wide

echo ""
echo "=== 2. Logs ==="
kubectl logs -n keybuzz-website-prod deployment/keybuzz-website --tail=10

POD=$(kubectl get pods -n keybuzz-website-prod -l app=keybuzz-website -o jsonpath='{.items[0].metadata.name}')

echo ""
echo "=== 3. HTTP www.keybuzz.pro ==="
STATUS=$(curl -sk -o /dev/null -w '%{http_code}' https://www.keybuzz.pro/)
echo "HTTP: $STATUS"

echo ""
echo "=== 4. t.keybuzz.pro in PROD HTML ==="
BODY=$(curl -sk https://www.keybuzz.pro/)
echo "Has t.keybuzz.pro: $(echo "$BODY" | grep -c 't.keybuzz.pro' || echo 0)"
echo "Has GA4 ID: $(echo "$BODY" | grep -c 'R3QQDYEBFG' || echo 0)"

echo ""
echo "=== 5. Bundles check ==="
echo "-- t.keybuzz.pro:"
kubectl exec -n keybuzz-website-prod "$POD" -- sh -c "grep -rl 't.keybuzz.pro' /app/.next/static/ 2>/dev/null | head -3 || echo 'NOT FOUND'"
echo "-- server_container_url:"
kubectl exec -n keybuzz-website-prod "$POD" -- sh -c "grep -rl 'server_container_url' /app/.next/static/ 2>/dev/null | head -3 || echo 'NOT FOUND'"
echo "-- GA4 ID:"
kubectl exec -n keybuzz-website-prod "$POD" -- sh -c "grep -rl 'R3QQDYEBFG' /app/.next/static/ 2>/dev/null | head -3 || echo 'NOT FOUND'"
echo "-- Meta Pixel:"
kubectl exec -n keybuzz-website-prod "$POD" -- sh -c "grep -rl 'fbevents.js' /app/.next/static/ 2>/dev/null | head -3 || echo 'NOT FOUND'"
echo "-- Meta Pixel ID:"
kubectl exec -n keybuzz-website-prod "$POD" -- sh -c "grep -rl '1234164602194748' /app/.next/static/ 2>/dev/null | head -3 || echo 'NOT FOUND'"
echo "-- view_pricing:"
kubectl exec -n keybuzz-website-prod "$POD" -- sh -c "grep -rl 'view_pricing' /app/.next/static/ 2>/dev/null | head -3 || echo 'NOT FOUND'"
echo "-- gclid:"
kubectl exec -n keybuzz-website-prod "$POD" -- sh -c "grep -rl 'gclid' /app/.next/static/ 2>/dev/null | head -3 || echo 'NOT FOUND'"
echo "-- contact_submit:"
kubectl exec -n keybuzz-website-prod "$POD" -- sh -c "grep -rl 'contact_submit' /app/.next/static/ 2>/dev/null | head -3 || echo 'NOT FOUND'"

echo ""
echo "=== 6. t.keybuzz.pro reachable ==="
T_STATUS=$(curl -sk -o /dev/null -w '%{http_code}' "https://t.keybuzz.pro/gtag/js?id=G-R3QQDYEBFG" 2>/dev/null)
echo "t.keybuzz.pro/gtag/js: $T_STATUS"

echo ""
echo "=== 7. No errors ==="
kubectl logs -n keybuzz-website-prod deployment/keybuzz-website --tail=50 | grep -i 'eacces\|error\|WARN' || echo "No errors"

echo ""
echo "=== PROD VALIDATION DONE ==="
