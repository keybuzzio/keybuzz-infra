#!/bin/bash
# Test webhook with valid HMAC signature

POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')

echo "=== Webhook test with valid HMAC ==="
# Compute HMAC inside the pod where SHOPIFY_CLIENT_SECRET is available
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const crypto = require('crypto');
const http = require('http');

const body = JSON.stringify({id: 999999, email: 'test@example.com'});
const secret = process.env.SHOPIFY_CLIENT_SECRET;
const hmac = crypto.createHmac('sha256', secret).update(body, 'utf8').digest('base64');

console.log('HMAC computed, sending webhook...');

const options = {
  hostname: '127.0.0.1',
  port: 3001,
  path: '/webhooks/shopify',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Shopify-Topic': 'orders/create',
    'X-Shopify-Shop-Domain': 'keybuzz-dev.myshopify.com',
    'X-Shopify-Hmac-Sha256': hmac,
    'Content-Length': Buffer.byteLength(body)
  }
};

const req = http.request(options, (res) => {
  let data = '';
  res.on('data', c => data += c);
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    console.log('Response:', data);
  });
});
req.write(body);
req.end();
"

sleep 2

echo ""
echo "=== DB: webhook_events after test ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
(async()=>{
  const r=await p.query('SELECT id, tenant_id, connection_id, topic, processed, created_at FROM shopify_webhook_events ORDER BY created_at DESC LIMIT 5');
  console.log(JSON.stringify(r.rows, null, 2));
  const c=await p.query('SELECT count(*) as total FROM shopify_webhook_events');
  console.log('Total events:', c.rows[0].total);
  await p.end();
})();
"

echo ""
echo "=== WEBHOOK TEST COMPLETE ==="
