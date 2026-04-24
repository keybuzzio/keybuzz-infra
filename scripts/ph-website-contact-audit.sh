#!/bin/bash
set -e

echo "=== CONTACT FORM AUDIT ==="
echo "Date: $(date)"

echo ""
echo "=== 1. PROD — API endpoint test (GET → expect 404/405) ==="
curl -sk -o /dev/null -w "GET https://api.keybuzz.io/api/public/contact → HTTP %{http_code}\n" https://api.keybuzz.io/api/public/contact

echo ""
echo "=== 2. PROD — POST with honeypot filled (should be rejected) ==="
RESP_HONEYPOT=$(curl -sk -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"audit","email":"audit@test.local","company":"audit","subject":"audit","message":"audit honeypot test","website":"filled"}' \
  -w "\nHTTP_CODE:%{http_code}" \
  https://api.keybuzz.io/api/public/contact)
echo "$RESP_HONEYPOT"

echo ""
echo "=== 3. PROD — POST with valid data (empty honeypot) ==="
RESP_VALID=$(curl -sk -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"Audit KeyBuzz","email":"audit@keybuzz.pro","company":"KeyBuzz","subject":"Test audit formulaire","message":"Ceci est un test audit du formulaire contact. Ne pas répondre.","website":""}' \
  -w "\nHTTP_CODE:%{http_code}" \
  https://api.keybuzz.io/api/public/contact)
echo "$RESP_VALID"

echo ""
echo "=== 4. Check DNS resolution api.keybuzz.io ==="
nslookup api.keybuzz.io 2>/dev/null | head -10 || host api.keybuzz.io 2>/dev/null || echo "DNS lookup failed"

echo ""
echo "=== 5. Check if api.keybuzz.io responds ==="
curl -sk -o /dev/null -w "GET https://api.keybuzz.io/ → HTTP %{http_code}\n" https://api.keybuzz.io/
curl -sk -o /dev/null -w "GET https://api.keybuzz.io/api → HTTP %{http_code}\n" https://api.keybuzz.io/api

echo ""
echo "=== 6. Check NEXT_PUBLIC_CONTACT_API_URL in website env ==="
echo "Default in code: https://api.keybuzz.io/api/public/contact"

echo ""
echo "=== 7. DEV — check same endpoint via client-dev ==="
curl -sk -o /dev/null -w "GET https://api.keybuzz.io/api/public/contact → HTTP %{http_code} (from bastion)\n" https://api.keybuzz.io/api/public/contact

echo ""
echo "=== 8. Check K8s services — is there a keybuzz-api? ==="
kubectl get svc --all-namespaces 2>/dev/null | grep -i "api\|contact" || echo "No API services found"

echo ""
echo "=== 9. Check K8s deployments — is there a keybuzz-api? ==="
kubectl get deployments --all-namespaces 2>/dev/null | grep -i "api" || echo "No API deployments found"

echo ""
echo "=== 10. Check K8s ingress — api.keybuzz.io routing ==="
kubectl get ingress --all-namespaces 2>/dev/null | grep -i "api" || echo "No API ingress found"

echo ""
echo "=== 11. Check if /api/public/contact route exists in any API pod ==="
API_POD=$(kubectl get pods --all-namespaces -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
API_NS=$(kubectl get pods --all-namespaces -l app=keybuzz-api -o jsonpath='{.items[0].metadata.namespace}' 2>/dev/null || echo "")
if [ -n "$API_POD" ] && [ -n "$API_NS" ]; then
  echo "API Pod: $API_POD (namespace: $API_NS)"
  kubectl logs -n "$API_NS" "$API_POD" --tail=20 2>/dev/null | tail -10
else
  echo "No keybuzz-api pods found with label app=keybuzz-api"
  echo "Trying broader search..."
  kubectl get pods --all-namespaces 2>/dev/null | grep -i "api" || echo "No API pods at all"
fi

echo ""
echo "=== 12. Check platform-api if exists ==="
curl -sk -o /dev/null -w "GET https://platform-api.keybuzz.io/ → HTTP %{http_code}\n" https://platform-api.keybuzz.io/ 2>/dev/null || echo "platform-api.keybuzz.io unreachable"
curl -sk -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"Audit","email":"audit@keybuzz.pro","company":"KeyBuzz","subject":"Test","message":"Test audit","website":""}' \
  -o /dev/null -w "POST https://platform-api.keybuzz.io/api/public/contact → HTTP %{http_code}\n" \
  https://platform-api.keybuzz.io/api/public/contact 2>/dev/null || echo "platform-api unreachable"

echo ""
echo "=== AUDIT DONE ==="
