#!/bin/bash
set -e

POD=$(kubectl get pods -n keybuzz-website-dev -o name --field-selector=status.phase=Running | head -1)
echo "Pod: $POD"

echo ""
echo "=== 1. Check pricing HTML for CTA links ==="
kubectl exec -n keybuzz-website-dev "$POD" -- node -e '
const http = require("http");
http.get("http://127.0.0.1:3000/pricing", { headers: { Host: "preview.keybuzz.pro" } }, r => {
  let d = "";
  r.on("data", c => d += c);
  r.on("end", () => {
    const matches = d.match(/href="[^"]*client-dev\.keybuzz\.io\/register[^"]*"/g) || [];
    console.log("CTA register links found:", matches.length);
    matches.forEach(m => console.log(" ", m));

    const utmRef = d.includes("utmSuffix") || d.includes("utm_source");
    console.log("\nutmSuffix or UTM reference in HTML:", utmRef);

    const useEffectRef = d.includes("useEffect");
    console.log("useEffect in bundle:", useEffectRef);

    console.log("\n=== Check: UTM JS logic in client bundle ===");
    if (d.includes("utm_source")) {
      console.log("OK: utm_source keyword found in page output (client-side JS will handle it)");
    } else {
      console.log("NOTE: utm_source not in SSR output (expected - UTM logic runs client-side only)");
    }
  });
});
'

echo ""
echo "=== 2. Verify NO EACCES errors ==="
kubectl logs -n keybuzz-website-dev deployment/keybuzz-website --tail=20 2>&1 | grep -i "eacces" && echo "EACCES FOUND!" || echo "OK: No EACCES errors"

echo ""
echo "=== 3. Check external access ==="
HTTP_CODE=$(curl -sk -o /dev/null -w '%{http_code}' -u preview:Kb2026Preview! https://preview.keybuzz.pro/pricing)
echo "HTTP status preview.keybuzz.pro/pricing: $HTTP_CODE"

echo ""
echo "=== 4. Verify pricing page has UTM client code in JS bundle ==="
curl -sk -u preview:Kb2026Preview! https://preview.keybuzz.pro/pricing 2>/dev/null | grep -o 'utm_[a-z]*' | sort -u | head -10

echo ""
echo "=== VALIDATION DONE ==="
