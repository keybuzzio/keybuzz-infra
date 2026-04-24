#!/bin/bash
set -e

echo "=== PH-T5.4 VALIDATION DEV ==="
echo "Date: $(date)"

echo ""
echo "=== 1. Pod status ==="
kubectl get pods -n keybuzz-website-dev -l app=keybuzz-website -o wide

echo ""
echo "=== 2. Pod logs ==="
kubectl logs -n keybuzz-website-dev deployment/keybuzz-website --tail=10

POD=$(kubectl get pods -n keybuzz-website-dev -l app=keybuzz-website -o jsonpath='{.items[0].metadata.name}')
echo ""
echo "Pod: $POD"

echo ""
echo "=== 3. Check gtag.js source — must be t.keybuzz.pro ==="
kubectl exec -n keybuzz-website-dev "$POD" -- sh -c "grep -rl 't.keybuzz.pro' /app/.next/static/ 2>/dev/null | head -5 || echo 'NOT FOUND'"

echo ""
echo "=== 4. Check server_container_url in bundles ==="
kubectl exec -n keybuzz-website-dev "$POD" -- sh -c "grep -rl 'server_container_url' /app/.next/static/ 2>/dev/null | head -5 || echo 'NOT FOUND'"

echo ""
echo "=== 5. Check fallback googletagmanager still present ==="
kubectl exec -n keybuzz-website-dev "$POD" -- sh -c "grep -rl 'googletagmanager.com' /app/.next/static/ 2>/dev/null | head -5 || echo 'NOT FOUND'"

echo ""
echo "=== 6. Check Meta Pixel unchanged ==="
kubectl exec -n keybuzz-website-dev "$POD" -- sh -c "grep -rl 'fbevents.js' /app/.next/static/ 2>/dev/null | head -5 || echo 'NOT FOUND'"
kubectl exec -n keybuzz-website-dev "$POD" -- sh -c "grep -rl '1234164602194748' /app/.next/static/ 2>/dev/null | head -5 || echo 'NOT FOUND'"

echo ""
echo "=== 7. Check GA4 ID still present ==="
kubectl exec -n keybuzz-website-dev "$POD" -- sh -c "grep -rl 'R3QQDYEBFG' /app/.next/static/ 2>/dev/null | head -5 || echo 'NOT FOUND'"

echo ""
echo "=== 8. Check events still present ==="
kubectl exec -n keybuzz-website-dev "$POD" -- sh -c "grep -rl 'view_pricing' /app/.next/static/ 2>/dev/null | head -3 || echo 'NOT FOUND'"
kubectl exec -n keybuzz-website-dev "$POD" -- sh -c "grep -rl 'contact_submit' /app/.next/static/ 2>/dev/null | head -3 || echo 'NOT FOUND'"
kubectl exec -n keybuzz-website-dev "$POD" -- sh -c "grep -rl 'gclid' /app/.next/static/ 2>/dev/null | head -3 || echo 'NOT FOUND'"

echo ""
echo "=== 9. HTTP test homepage ==="
kubectl exec -n keybuzz-website-dev "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', r => {
  let d = '';
  r.on('data', c => d += c);
  r.on('end', () => {
    console.log('STATUS:', r.statusCode);
    console.log('Has t.keybuzz.pro:', d.includes('t.keybuzz.pro'));
    console.log('Has GA4 ID:', d.includes('R3QQDYEBFG'));
  });
});
"

echo ""
echo "=== 10. External preview test ==="
STATUS=$(curl -sk -o /dev/null -w '%{http_code}' -u 'preview:Kb2026Preview!' https://preview.keybuzz.pro/)
echo "HTTP: $STATUS"

BODY=$(curl -sk -u 'preview:Kb2026Preview!' https://preview.keybuzz.pro/)
echo "Has t.keybuzz.pro: $(echo "$BODY" | grep -c 't.keybuzz.pro' || echo 0)"
echo "Has GA4 ID: $(echo "$BODY" | grep -c 'R3QQDYEBFG' || echo 0)"

echo ""
echo "=== 11. Test t.keybuzz.pro reachable ==="
T_STATUS=$(curl -sk -o /dev/null -w '%{http_code}' "https://t.keybuzz.pro/gtag/js?id=G-R3QQDYEBFG" 2>/dev/null)
echo "t.keybuzz.pro/gtag/js status: $T_STATUS"

echo ""
echo "=== 12. No errors ==="
kubectl logs -n keybuzz-website-dev deployment/keybuzz-website --tail=50 | grep -i 'eacces\|error\|WARN' || echo "No errors"

echo ""
echo "=== VALIDATION DONE ==="
