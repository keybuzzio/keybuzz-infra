#!/bin/bash
POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
SECRET=$(kubectl get secret keybuzz-shopify -n keybuzz-api-dev -o jsonpath='{.data.SHOPIFY_CLIENT_SECRET}' | base64 -d)

echo "========================================="
echo "  PH-SHOPIFY-02.2 — COMPLIANCE VALIDATION"
echo "========================================="

echo ""
echo "=== 1. HEALTH CHECK ==="
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s http://127.0.0.1:3001/health | python3 -c "import sys,json;d=json.load(sys.stdin);print('OK' if d.get('status')=='ok' else 'FAIL')"

echo ""
echo "=== 2. TEST customers/data_request WEBHOOK ==="
PAYLOAD='{"shop_id":1,"shop_domain":"keybuzz-dev.myshopify.com","customer":{"id":1,"email":"test@test.com"},"data_request":{"id":1}}'
HMAC=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" -binary | base64)
RESULT=$(kubectl exec -n keybuzz-api-dev "$POD" -- curl -s -X POST 'http://127.0.0.1:3001/webhooks/shopify' \
  -H 'Content-Type: application/json' \
  -H "X-Shopify-Hmac-Sha256: $HMAC" \
  -H 'X-Shopify-Topic: customers/data_request' \
  -H 'X-Shopify-Shop-Domain: keybuzz-dev.myshopify.com' \
  -d "$PAYLOAD")
echo "customers/data_request: $RESULT"

echo ""
echo "=== 3. TEST customers/redact WEBHOOK ==="
PAYLOAD2='{"shop_id":1,"shop_domain":"keybuzz-dev.myshopify.com","customer":{"id":1,"email":"test@test.com"},"orders_to_redact":[1]}'
HMAC2=$(echo -n "$PAYLOAD2" | openssl dgst -sha256 -hmac "$SECRET" -binary | base64)
RESULT2=$(kubectl exec -n keybuzz-api-dev "$POD" -- curl -s -X POST 'http://127.0.0.1:3001/webhooks/shopify' \
  -H 'Content-Type: application/json' \
  -H "X-Shopify-Hmac-Sha256: $HMAC2" \
  -H 'X-Shopify-Topic: customers/redact' \
  -H 'X-Shopify-Shop-Domain: keybuzz-dev.myshopify.com' \
  -d "$PAYLOAD2")
echo "customers/redact: $RESULT2"

echo ""
echo "=== 4. TEST shop/redact WEBHOOK ==="
PAYLOAD3='{"shop_id":1,"shop_domain":"keybuzz-dev.myshopify.com"}'
HMAC3=$(echo -n "$PAYLOAD3" | openssl dgst -sha256 -hmac "$SECRET" -binary | base64)
RESULT3=$(kubectl exec -n keybuzz-api-dev "$POD" -- curl -s -X POST 'http://127.0.0.1:3001/webhooks/shopify' \
  -H 'Content-Type: application/json' \
  -H "X-Shopify-Hmac-Sha256: $HMAC3" \
  -H 'X-Shopify-Topic: shop/redact' \
  -H 'X-Shopify-Shop-Domain: keybuzz-dev.myshopify.com' \
  -d "$PAYLOAD3")
echo "shop/redact: $RESULT3"

echo ""
echo "=== 5. TEST app/uninstalled WEBHOOK ==="
PAYLOAD4='{"id":1}'
HMAC4=$(echo -n "$PAYLOAD4" | openssl dgst -sha256 -hmac "$SECRET" -binary | base64)
RESULT4=$(kubectl exec -n keybuzz-api-dev "$POD" -- curl -s -X POST 'http://127.0.0.1:3001/webhooks/shopify' \
  -H 'Content-Type: application/json' \
  -H "X-Shopify-Hmac-Sha256: $HMAC4" \
  -H 'X-Shopify-Topic: app/uninstalled' \
  -H 'X-Shopify-Shop-Domain: test-shop.myshopify.com' \
  -d "$PAYLOAD4")
echo "app/uninstalled: $RESULT4"

echo ""
echo "=== 6. TEST HMAC REJECTION ==="
RESULT5=$(kubectl exec -n keybuzz-api-dev "$POD" -- curl -s -X POST 'http://127.0.0.1:3001/webhooks/shopify' \
  -H 'Content-Type: application/json' \
  -H 'X-Shopify-Hmac-Sha256: INVALID_HMAC_HERE' \
  -H 'X-Shopify-Topic: customers/data_request' \
  -H 'X-Shopify-Shop-Domain: keybuzz-dev.myshopify.com' \
  -d '{"test":true}')
echo "Invalid HMAC (expected 401): $RESULT5"

echo ""
echo "=== 7. WEBHOOK EVENTS IN DB ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
(async()=>{
  const r=await p.query(\"SELECT topic, COUNT(*) as cnt FROM shopify_webhook_events GROUP BY topic ORDER BY topic\");
  console.log('Events by topic:', JSON.stringify(r.rows));
  await p.end();
})();
"

echo ""
echo "=== 8. NON-REGRESSION ==="
echo "--- conversations ---"
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/messages/conversations?tenantId=ecomlg-001&limit=1' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' | python3 -c "import sys,json;d=json.load(sys.stdin);print('OK')"
echo "--- ai/wallet ---"
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/ai/wallet/status?tenantId=ecomlg-001' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: ecomlg-001' | python3 -c "import sys,json;d=json.load(sys.stdin);print('OK - KBA:', d.get('kbActions',{}).get('remaining','?'))"
echo "--- shopify status ---"
kubectl exec -n keybuzz-api-dev "$POD" -- curl -s 'http://127.0.0.1:3001/shopify/status?tenantId=keybuzz-mnqnjna8' -H 'X-User-Email: ludo.gonthier@gmail.com' -H 'X-Tenant-Id: keybuzz-mnqnjna8'
echo ""

echo ""
echo "=== 9. POD LOGS (Shopify webhook) ==="
kubectl logs -n keybuzz-api-dev "$POD" --tail=30 | grep -i 'shopify webhook' | tail -10

echo ""
echo "========================================="
echo "  VALIDATION COMPLETE"
echo "========================================="
