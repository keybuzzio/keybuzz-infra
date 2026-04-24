#!/bin/bash
set -e

echo "=== CONTACT FORM AUDIT — PART 2 (API PROD) ==="
echo "Date: $(date)"

echo ""
echo "=== 1. API PROD pod ==="
kubectl get pods -n keybuzz-api-prod -l app=keybuzz-api -o wide

echo ""
echo "=== 2. API PROD logs — last 100 lines (search for 'contact') ==="
kubectl logs -n keybuzz-api-prod deployment/keybuzz-api --tail=100 2>/dev/null | grep -i "contact\|mail\|smtp\|email\|public" || echo "No contact/mail references in last 100 lines"

echo ""
echo "=== 3. API PROD — search routes for 'contact' or 'public' ==="
API_POD_PROD=$(kubectl get pods -n keybuzz-api-prod -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}')
echo "Pod: $API_POD_PROD"

echo ""
echo "=== 4. Check if contact route file exists in API pod ==="
kubectl exec -n keybuzz-api-prod "$API_POD_PROD" -- sh -c "find / -name '*.js' -path '*/public*' 2>/dev/null | head -10" || echo "Find failed"
kubectl exec -n keybuzz-api-prod "$API_POD_PROD" -- sh -c "find / -name '*.js' 2>/dev/null | xargs grep -l 'contact' 2>/dev/null | head -10" || echo "Grep contact failed"

echo ""
echo "=== 5. POST directly to API PROD internal + check logs ==="
# First, send a POST
curl -sk -X POST \
  -H "Content-Type: application/json" \
  -d '{"name":"AUDIT-T6","email":"audit-t6@keybuzz.pro","company":"KeyBuzz Audit","subject":"AUDIT T6 Test","message":"This is an audit test from PH-T6.1. Please ignore.","website":""}' \
  https://api.keybuzz.io/api/public/contact
echo ""

# Wait 2 seconds then check logs
sleep 2
echo ""
echo "=== 6. API PROD logs after POST (last 30 lines) ==="
kubectl logs -n keybuzz-api-prod deployment/keybuzz-api --tail=30 2>/dev/null | grep -v "health" | tail -20

echo ""
echo "=== 7. Check API env vars for SMTP / mail config ==="
kubectl exec -n keybuzz-api-prod "$API_POD_PROD" -- sh -c "env | grep -iE 'smtp|mail|email|contact|notification' || echo 'No SMTP/mail env vars found'"

echo ""
echo "=== 8. Check API PROD ingress details ==="
kubectl describe ingress keybuzz-api -n keybuzz-api-prod 2>/dev/null | head -30

echo ""
echo "=== 9. Verify the actual ingress path for /api/public/contact ==="
kubectl get ingress -n keybuzz-api-prod -o yaml 2>/dev/null | grep -A5 "path\|host" | head -30

echo ""
echo "=== AUDIT PART 2 DONE ==="
