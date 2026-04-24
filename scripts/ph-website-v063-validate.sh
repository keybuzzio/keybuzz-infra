#!/bin/bash
set -e

echo "=== VALIDATION v0.6.3 ==="
echo "Date: $(date)"

echo "=== 1. Pods PROD ==="
kubectl get pods -n keybuzz-website-prod --field-selector=status.phase=Running

echo ""
echo "=== 2. Image deployed ==="
kubectl get deploy keybuzz-website -n keybuzz-website-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

echo ""
echo "=== 3. Logs ==="
kubectl logs -n keybuzz-website-prod deployment/keybuzz-website --tail=10 2>&1

echo ""
echo "=== 4. EACCES check ==="
kubectl logs -n keybuzz-website-prod deployment/keybuzz-website --tail=100 2>&1 | grep -i "eacces" && echo "FOUND!" || echo "OK"

echo ""
echo "=== 5. HTTP check ==="
for page in "/" "/pricing" "/features" "/contact" "/about"; do
  CODE=$(curl -sk -o /dev/null -w '%{http_code}' "https://www.keybuzz.pro${page}")
  echo "  ${page}: HTTP ${CODE}"
done

echo ""
echo "=== 6. Error boundary in bundle ==="
POD=$(kubectl get pods -n keybuzz-website-prod -o name --field-selector=status.phase=Running | head -1)
kubectl exec -n keybuzz-website-prod "$POD" -- find /app/.next -name '*.js' -exec grep -l 'Recharger la page' {} + 2>/dev/null | wc -l | xargs -I{} echo "Error boundary in {} JS files"

echo ""
echo "=== 7. UTM in bundle ==="
kubectl exec -n keybuzz-website-prod "$POD" -- find /app/.next/static -name '*.js' -exec grep -l 'utm_source' {} + 2>/dev/null | head -1 && echo "OK" || echo "NOT FOUND"

echo ""
echo "=== 8. CTA links ==="
kubectl exec -n keybuzz-website-prod "$POD" -- node -e '
const http = require("http");
http.get("http://127.0.0.1:3000/pricing", r => {
  let d = "";
  r.on("data", c => d += c);
  r.on("end", () => {
    const m = d.match(/href="[^"]*register[^"]*"/g) || [];
    m.forEach(x => console.log(x));
  });
});
'

echo ""
echo "=== VALIDATION DONE ==="
