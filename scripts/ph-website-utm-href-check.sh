#!/bin/bash
set -e

POD=$(kubectl get pods -n keybuzz-website-prod -o name --field-selector=status.phase=Running | head -1)
echo "Pod: $POD"

echo "=== Test 1: Pricing WITHOUT UTM params ==="
kubectl exec -n keybuzz-website-prod "$POD" -- node -e '
const http = require("http");
http.get("http://127.0.0.1:3000/pricing", r => {
  let d = "";
  r.on("data", c => d += c);
  r.on("end", () => {
    const m = d.match(/href="[^"]*register[^"]*"/g) || [];
    console.log("Links without UTM:");
    m.forEach(x => console.log("  " + x));
  });
});
'

echo ""
echo "=== Test 2: Pricing WITH UTM params (simulated client-side) ==="
echo "NOTE: UTM logic runs in browser (useEffect), NOT in SSR."
echo "Server-rendered HTML will NEVER contain UTM params in href."
echo "The useEffect fires AFTER hydration in the browser."
echo ""

echo "=== Test 3: Verify the UTM JS code in the bundle ==="
UTM_CHUNK=$(kubectl exec -n keybuzz-website-prod "$POD" -- find /app/.next/static -name '*.js' -exec grep -l 'utm_source' {} + 2>/dev/null | head -1)
echo "UTM chunk: $UTM_CHUNK"
kubectl exec -n keybuzz-website-prod "$POD" -- node -e "
const fs = require('fs');
const code = fs.readFileSync('$UTM_CHUNK', 'utf8');
const idx = code.indexOf('utm_source');
const start = Math.max(0, idx - 300);
const end = Math.min(code.length, idx + 400);
console.log(code.substring(start, end));
"

echo ""
echo "=== Test 4: Check if Reveal component might cause runtime errors ==="
kubectl exec -n keybuzz-website-prod "$POD" -- node -e '
const http = require("http");

function checkPage(path) {
  return new Promise((resolve) => {
    http.get("http://127.0.0.1:3000" + path, r => {
      let d = "";
      r.on("data", c => d += c);
      r.on("end", () => {
        const hasReveal = d.includes("kb-reveal");
        const hasSearchParams = d.includes("useSearchParams");
        const hasMotionDebug = d.includes("motion-debug");
        const hasNextError = d.includes("NEXT_NOT_FOUND") || d.includes("__next_error__");
        resolve({path, hasReveal, hasSearchParams, hasMotionDebug, hasNextError, status: r.statusCode});
      });
    });
  });
}

Promise.all([
  checkPage("/"),
  checkPage("/pricing"),
  checkPage("/features"),
  checkPage("/contact"),
]).then(results => {
  results.forEach(r => console.log(JSON.stringify(r)));
});
'

echo ""
echo "=== Test 5: Check all pages - full source for error patterns ==="
for page in "/" "/pricing" "/about" "/features" "/contact" "/amazon" "/privacy" "/terms"; do
  kubectl exec -n keybuzz-website-prod "$POD" -- node -e "
    const http = require('http');
    http.get('http://127.0.0.1:3000${page}', r => {
      let d = '';
      r.on('data', c => d += c);
      r.on('end', () => {
        const issues = [];
        if (d.includes('__NEXT_DATA__') && d.includes('err')) issues.push('NEXT_DATA_ERR');
        if (d.includes('error-boundary')) issues.push('ERROR_BOUNDARY');
        if (r.statusCode !== 200) issues.push('HTTP_' + r.statusCode);
        console.log('${page}: HTTP ' + r.statusCode + (issues.length ? ' ISSUES: ' + issues.join(',') : ' OK'));
      });
    });
  " 2>&1
done

echo ""
echo "=== HREF CHECK DONE ==="
