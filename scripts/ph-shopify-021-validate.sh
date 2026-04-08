#!/bin/bash
set -e

POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
echo "Pod: $POD"

echo ""
echo "=== 1. HEALTH ==="
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s http://127.0.0.1:3001/health

echo ""
echo ""
echo "=== 2. SHOPIFY STATUS (ecomlg-001) ==="
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/shopify/status?tenantId=ecomlg-001' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001'

echo ""
echo ""
echo "=== 3. SHOPIFY CONNECT TEST ==="
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s -X POST 'http://127.0.0.1:3001/shopify/connect' -H 'Content-Type: application/json' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' -d '{"shopDomain":"test-ecomlg.myshopify.com"}'

echo ""
echo ""
echo "=== 4. NON-REGRESSION ==="
echo "--- conversations ---"
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/messages/conversations?tenantId=ecomlg-001&limit=1' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' | head -c 200

echo ""
echo ""
echo "--- orders ---"
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/api/v1/orders?tenantId=ecomlg-001&limit=1' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' | head -c 200

echo ""
echo ""
echo "--- ai/wallet/status ---"
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/ai/wallet/status?tenantId=ecomlg-001' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001'

echo ""
echo ""
echo "=== 5. MULTI-TENANT ==="
echo "--- tenant that does not own shopify ---"
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/shopify/status?tenantId=tenant-1772234265142' -H 'X-User-Email: ludovic@ecomlg.fr' -H 'X-Tenant-Id: tenant-1772234265142'

echo ""
echo ""
echo "=== 6. CHANNELS CATALOG ==="
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/channels/catalog?tenantId=ecomlg-001' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' | python3 -c "import sys,json; d=json.load(sys.stdin); full=d.get('full',[]); shopify=[e for e in full if e.get('provider')=='shopify']; print('Shopify in catalog:', shopify)"

echo ""
echo ""
echo "=== 7. PROD UNCHANGED ==="
echo "API PROD:"
kubectl get deployment keybuzz-api -n keybuzz-api-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
echo "Client PROD:"
kubectl get deployment keybuzz-client -n keybuzz-client-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

echo ""
echo "=== VALIDATION COMPLETE ==="
