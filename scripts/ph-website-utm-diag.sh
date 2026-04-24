#!/bin/bash
set -e

echo "=== DIAGNOSTIC CLIENT-SIDE ERROR ==="
echo "Date: $(date)"

POD=$(kubectl get pods -n keybuzz-website-prod -o name --field-selector=status.phase=Running | head -1)
echo "Pod: $POD"

echo ""
echo "=== 1. Test each page for errors ==="
for page in "/" "/pricing" "/contact" "/about" "/features"; do
  CODE=$(kubectl exec -n keybuzz-website-prod "$POD" -- node -e "
    const http = require('http');
    http.get('http://127.0.0.1:3000${page}', r => {
      let d = '';
      r.on('data', c => d += c);
      r.on('end', () => {
        const hasAppError = d.includes('Application error') || d.includes('client-side exception');
        const hasHydrationError = d.includes('Hydration') || d.includes('hydration');
        console.log('HTTP:' + r.statusCode + ' AppError:' + hasAppError + ' Hydration:' + hasHydrationError);
      });
    });
  " 2>&1)
  echo "  ${page}: ${CODE}"
done

echo ""
echo "=== 2. Full PROD logs (all pods) ==="
kubectl logs -n keybuzz-website-prod deployment/keybuzz-website --all-containers --tail=50 2>&1

echo ""
echo "=== 3. Check pricing page for JS errors ==="
kubectl exec -n keybuzz-website-prod "$POD" -- node -e "
  const http = require('http');
  http.get('http://127.0.0.1:3000/pricing', r => {
    let d = '';
    r.on('data', c => d += c);
    r.on('end', () => {
      // Check for error boundary markers
      if (d.includes('application-error') || d.includes('__next-error')) {
        console.log('ERROR MARKER FOUND in HTML');
      }
      // Check script tags for issues
      const scripts = d.match(/<script[^>]*src=\"([^\"]+)\"/g) || [];
      console.log('Script tags:', scripts.length);
      scripts.forEach(s => console.log('  ' + s));
      
      // Check if CTA links are present
      const ctas = d.match(/client\.keybuzz\.io\/register/g) || [];
      console.log('CTA register links:', ctas.length);
      
      // Check for utm code
      console.log('Has utm_source in HTML:', d.includes('utm_source'));
    });
  });
" 2>&1

echo ""
echo "=== 4. Check external PROD pricing ==="
HTTP_CODE=$(curl -sk -o /tmp/pricing-prod.html -w '%{http_code}' https://www.keybuzz.pro/pricing)
echo "HTTP: $HTTP_CODE"
grep -c 'client.keybuzz.io/register' /tmp/pricing-prod.html 2>/dev/null || echo "0 CTA links"
grep -o 'Application error' /tmp/pricing-prod.html 2>/dev/null || echo "No Application error in HTML"

echo ""
echo "=== 5. Check external PROD homepage ==="
HTTP_CODE=$(curl -sk -o /tmp/home-prod.html -w '%{http_code}' https://www.keybuzz.pro/)
echo "HTTP: $HTTP_CODE"
grep -o 'Application error' /tmp/home-prod.html 2>/dev/null || echo "No Application error in HTML"

echo ""
echo "=== 6. Fetch JS chunk with UTM code and check for syntax issues ==="
UTM_CHUNK=$(kubectl exec -n keybuzz-website-prod "$POD" -- find /app/.next/static -name '*.js' -exec grep -l 'utm_source' {} + 2>/dev/null | head -1)
echo "UTM chunk: $UTM_CHUNK"
if [ -n "$UTM_CHUNK" ]; then
  kubectl exec -n keybuzz-website-prod "$POD" -- node -e "
    const fs = require('fs');
    const code = fs.readFileSync('$UTM_CHUNK', 'utf8');
    // Find the UTM section
    const idx = code.indexOf('utm_source');
    if (idx > -1) {
      const start = Math.max(0, idx - 200);
      const end = Math.min(code.length, idx + 300);
      console.log('=== UTM code context ===');
      console.log(code.substring(start, end));
    }
  " 2>&1
fi

echo ""
echo "=== DIAGNOSTIC DONE ==="
