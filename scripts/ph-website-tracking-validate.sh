#!/bin/bash
set -e

echo "=== VALIDATE TRACKING DEV ==="

POD=$(kubectl get pods -n keybuzz-website-dev -l app=keybuzz-website -o jsonpath='{.items[0].metadata.name}')
echo "Pod: $POD"

echo ""
echo "=== Check homepage HTML for GA + Pixel ==="
kubectl exec -n keybuzz-website-dev "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', r => {
  let d = '';
  r.on('data', c => d += c);
  r.on('end', () => {
    console.log('STATUS:', r.statusCode);
    console.log('GA gtag.js:', d.includes('gtag/js'));
    console.log('GA ID:', d.includes('G-R3QQDYEBFG'));
    console.log('Meta fbevents:', d.includes('fbevents.js'));
    console.log('Meta Pixel ID:', d.includes('1234164602194748'));
    console.log('---');
    // Show script tags
    const matches = d.match(/<script[^>]*>([\s\S]*?)<\/script>/gi) || [];
    matches.forEach((m, i) => {
      if (m.includes('gtag') || m.includes('fbq') || m.includes('fbevents') || m.includes('dataLayer')) {
        console.log('SCRIPT ' + i + ':', m.substring(0, 200));
      }
    });
  });
});
"

echo ""
echo "=== Check pricing page for tracking events ==="
kubectl exec -n keybuzz-website-dev "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/pricing', r => {
  let d = '';
  r.on('data', c => d += c);
  r.on('end', () => {
    console.log('STATUS:', r.statusCode);
    console.log('Has trackViewPricing ref:', d.includes('trackViewPricing') || d.includes('view_pricing'));
    console.log('Has gclid forwarding:', d.includes('gclid'));
    console.log('Has fbclid forwarding:', d.includes('fbclid'));
  });
});
"

echo ""
echo "=== External test preview.keybuzz.pro ==="
STATUS=$(curl -sk -o /dev/null -w '%{http_code}' -u 'preview:Kb2026Preview!' https://preview.keybuzz.pro/)
echo "HTTP status: $STATUS"

echo ""
echo "=== Check GA/Pixel in external HTML ==="
BODY=$(curl -sk -u 'preview:Kb2026Preview!' https://preview.keybuzz.pro/)
echo "GA gtag.js: $(echo "$BODY" | grep -c 'gtag/js' || echo 0)"
echo "GA ID: $(echo "$BODY" | grep -c 'G-R3QQDYEBFG' || echo 0)"
echo "Meta fbevents: $(echo "$BODY" | grep -c 'fbevents.js' || echo 0)"
echo "Meta Pixel ID: $(echo "$BODY" | grep -c '1234164602194748' || echo 0)"

echo ""
echo "=== DONE ==="
