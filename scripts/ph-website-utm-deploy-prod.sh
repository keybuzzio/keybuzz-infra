#!/bin/bash
set -e

echo "=== PH-WEBSITE UTM — DEPLOY PROD ==="
echo "Date: $(date)"

cd /opt/keybuzz/keybuzz-infra
echo "=== 1. Pull infra ==="
git pull origin main --ff-only

echo ""
echo "=== 2. Apply PROD manifest ==="
kubectl apply -f k8s/website-prod/deployment.yaml

echo ""
echo "=== 3. Rollout status ==="
kubectl rollout status deployment/keybuzz-website -n keybuzz-website-prod --timeout=120s

echo ""
echo "=== 4. Pods ==="
kubectl get pods -n keybuzz-website-prod -o wide

echo ""
echo "=== 5. Image deployed ==="
kubectl get deploy keybuzz-website -n keybuzz-website-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

echo ""
echo "=== 6. Logs ==="
kubectl logs -n keybuzz-website-prod deployment/keybuzz-website --tail=15 2>&1

echo ""
echo "=== 7. EACCES check ==="
kubectl logs -n keybuzz-website-prod deployment/keybuzz-website --tail=100 2>&1 | grep -i "eacces" && echo "EACCES FOUND!" || echo "OK: No EACCES errors"

echo ""
echo "=== 8. HTTP check www.keybuzz.pro ==="
HTTP_CODE=$(curl -sk -o /dev/null -w '%{http_code}' https://www.keybuzz.pro/pricing)
echo "HTTP status: $HTTP_CODE"

echo ""
echo "=== 9. CTA links in PROD HTML ==="
POD=$(kubectl get pods -n keybuzz-website-prod -o name --field-selector=status.phase=Running | head -1)
kubectl exec -n keybuzz-website-prod "$POD" -- node -e '
const http = require("http");
http.get("http://127.0.0.1:3000/pricing", r => {
  let d = "";
  r.on("data", c => d += c);
  r.on("end", () => {
    const m = d.match(/href="[^"]*client\.keybuzz\.io\/register[^"]*"/g) || [];
    console.log("CTA links found:", m.length);
    m.forEach(x => console.log(" ", x));
  });
});
'

echo ""
echo "=== 10. UTM code in PROD JS bundle ==="
kubectl exec -n keybuzz-website-prod "$POD" -- find /app/.next/static -name '*.js' -exec grep -l 'utm_source' {} + 2>/dev/null && echo "OK: UTM code in bundle" || echo "WARNING: UTM not found in bundle"

echo ""
echo "=== DEPLOY PROD DONE ==="
