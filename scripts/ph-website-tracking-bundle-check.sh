#!/bin/bash
set -e

POD=$(kubectl get pods -n keybuzz-website-dev -l app=keybuzz-website -o jsonpath='{.items[0].metadata.name}')
echo "Pod: $POD"

echo "=== Meta Pixel in bundles ==="
kubectl exec -n keybuzz-website-dev "$POD" -- sh -c "find /app/.next/static -name '*.js' | head -20"

echo ""
echo "=== Search for fbevents in all JS ==="
kubectl exec -n keybuzz-website-dev "$POD" -- sh -c "grep -rl 'fbevents' /app/.next/static/ 2>/dev/null || echo 'NOT FOUND'"

echo ""
echo "=== Search for Meta Pixel ID in all JS ==="
kubectl exec -n keybuzz-website-dev "$POD" -- sh -c "grep -rl '1234164602194748' /app/.next/static/ 2>/dev/null || echo 'NOT FOUND'"

echo ""
echo "=== Search for GA ID in all JS ==="
kubectl exec -n keybuzz-website-dev "$POD" -- sh -c "grep -rl 'R3QQDYEBFG' /app/.next/static/ 2>/dev/null || echo 'NOT FOUND'"

echo ""
echo "=== Search for trackViewPricing in all JS ==="
kubectl exec -n keybuzz-website-dev "$POD" -- sh -c "grep -rl 'view_pricing\|trackViewPricing' /app/.next/static/ 2>/dev/null || echo 'NOT FOUND'"

echo ""
echo "=== Search for gclid in all JS ==="
kubectl exec -n keybuzz-website-dev "$POD" -- sh -c "grep -rl 'gclid' /app/.next/static/ 2>/dev/null || echo 'NOT FOUND'"

echo ""
echo "=== Check env vars baked ==="
kubectl exec -n keybuzz-website-dev "$POD" -- sh -c "env | grep -E 'GA_ID|META_PIXEL' || echo 'ENV NOT FOUND'"

echo ""
echo "=== Full HTML homepage - check for script tags ==="
kubectl exec -n keybuzz-website-dev "$POD" -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', r => {
  let d = '';
  r.on('data', c => d += c);
  r.on('end', () => {
    // Extract all script tags
    const scripts = d.match(/<script[^>]*>[\\s\\S]*?<\\/script>/gi) || [];
    console.log('Total script tags:', scripts.length);
    scripts.forEach((s, i) => {
      if (s.includes('gtag') || s.includes('fbq') || s.includes('fbevents') || s.includes('dataLayer') || s.includes('googletagmanager') || s.includes('facebook')) {
        console.log('');
        console.log('TRACKING SCRIPT ' + i + ':');
        console.log(s.substring(0, 500));
      }
    });
  });
});
"
