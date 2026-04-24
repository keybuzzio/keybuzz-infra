#!/bin/bash
set -e

echo "=== DEPLOY v0.6.3 DEV + PROD ==="
echo "Date: $(date)"

cd /opt/keybuzz/keybuzz-infra
echo "=== 1. Pull infra ==="
git pull origin main --ff-only

echo ""
echo "=== 2. Apply DEV ==="
kubectl apply -f k8s/website-dev/deployment.yaml
kubectl rollout status deployment/keybuzz-website -n keybuzz-website-dev --timeout=120s

echo ""
echo "=== 3. Apply PROD ==="
kubectl apply -f k8s/website-prod/deployment.yaml
kubectl rollout status deployment/keybuzz-website -n keybuzz-website-prod --timeout=120s

echo ""
echo "=== 4. Pods DEV ==="
kubectl get pods -n keybuzz-website-dev -o wide --field-selector=status.phase=Running

echo ""
echo "=== 5. Pods PROD ==="
kubectl get pods -n keybuzz-website-prod -o wide --field-selector=status.phase=Running

echo ""
echo "=== 6. Images deployed ==="
echo "DEV:"
kubectl get deploy keybuzz-website -n keybuzz-website-dev -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
echo "PROD:"
kubectl get deploy keybuzz-website -n keybuzz-website-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

echo ""
echo "=== 7. Logs PROD ==="
kubectl logs -n keybuzz-website-prod deployment/keybuzz-website --tail=10 2>&1

echo ""
echo "=== 8. EACCES check PROD ==="
kubectl logs -n keybuzz-website-prod deployment/keybuzz-website --tail=100 2>&1 | grep -i "eacces" && echo "EACCES FOUND!" || echo "OK: No EACCES"

echo ""
echo "=== 9. HTTP check PROD ==="
for page in "/" "/pricing" "/features" "/contact" "/about"; do
  CODE=$(curl -sk -o /dev/null -w '%{http_code}' "https://www.keybuzz.pro${page}")
  echo "  ${page}: HTTP ${CODE}"
done

echo ""
echo "=== 10. Verify error boundary in bundle ==="
POD=$(kubectl get pods -n keybuzz-website-prod -o name --field-selector=status.phase=Running | head -1)
kubectl exec -n keybuzz-website-prod "$POD" -- find /app/.next -name '*.js' -exec grep -l 'Recharger la page' {} + 2>/dev/null | head -3 && echo "OK: Error boundary found" || echo "WARNING: Error boundary not found"

echo ""
echo "=== 11. Verify UTM in PROD bundle ==="
kubectl exec -n keybuzz-website-prod "$POD" -- find /app/.next/static -name '*.js' -exec grep -l 'utm_source' {} + 2>/dev/null | head -1 && echo "OK: UTM code present" || echo "WARNING: UTM not found"

echo ""
echo "=== 12. CTA links PROD ==="
kubectl exec -n keybuzz-website-prod "$POD" -- node -e '
const http = require("http");
http.get("http://127.0.0.1:3000/pricing", r => {
  let d = "";
  r.on("data", c => d += c);
  r.on("end", () => {
    const m = d.match(/href="[^"]*register[^"]*"/g) || [];
    console.log("CTA links:", m.length);
    m.forEach(x => console.log("  " + x));
  });
});
'

echo ""
echo "=== DEPLOY DONE ==="
