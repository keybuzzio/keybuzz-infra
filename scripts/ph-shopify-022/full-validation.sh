#!/bin/bash
set -e
API="https://api-dev.keybuzz.io"
TENANT="keybuzz-mnqnjna8"
HDR="-H X-User-Email:ludo.gonthier@gmail.com -H X-Tenant-Id:$TENANT"

echo "============================================"
echo " PH-SHOPIFY — Validation complète"
echo "============================================"

echo ""
echo "1. Statut connexion Shopify..."
curl -sf $HDR "$API/shopify/status" 2>&1
echo ""

echo ""
echo "2. Vérification token_expires_at en DB..."
POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n keybuzz-api-dev "$POD" -- node -e '
const {Pool} = require("pg");
const p = new Pool();
(async () => {
  const r = await p.query("SELECT id, scopes, status, token_expires_at, created_at FROM shopify_connections WHERE status = '\''active'\'' ORDER BY created_at DESC LIMIT 1");
  console.log(JSON.stringify(r.rows[0], null, 2));
  await p.end();
})();
'

echo ""
echo "3. Sync commandes Shopify (GraphQL)..."
SYNC=$(curl -s -w '\nHTTP:%{http_code}' -X POST $HDR -H "Content-Type: application/json" -d '{}' "$API/shopify/orders/sync")
echo "$SYNC"

echo ""
echo "4. Liste commandes Shopify importées..."
curl -sf $HDR "$API/shopify/orders/list" 2>&1
echo ""

echo ""
echo "5. Commandes Shopify en DB..."
kubectl exec -n keybuzz-api-dev "$POD" -- node -e '
const {Pool} = require("pg");
const p = new Pool();
(async () => {
  const r = await p.query("SELECT id, external_order_id, channel, status, total_amount, currency, customer_name, order_date FROM orders WHERE channel = '\''shopify'\'' ORDER BY order_date DESC LIMIT 10");
  console.log("Shopify orders in DB:", r.rows.length);
  r.rows.forEach(o => console.log(`  ${o.external_order_id} | ${o.status} | ${o.total_amount} ${o.currency} | ${o.customer_name} | ${o.order_date}`));
  await p.end();
})();
'

echo ""
echo "6. Logs Shopify post-reconnexion..."
kubectl logs -n keybuzz-api-dev "$POD" --tail=100 2>/dev/null | grep -i -E 'shopify|token.*rotat' | tail -20

echo ""
echo "7. Non-régression: commandes Amazon..."
kubectl exec -n keybuzz-api-dev "$POD" -- node -e '
const {Pool} = require("pg");
const p = new Pool();
(async () => {
  const r = await p.query("SELECT channel, count(*) as cnt FROM orders GROUP BY channel ORDER BY cnt DESC");
  console.log("Orders by channel:");
  r.rows.forEach(o => console.log("  " + o.channel + ": " + o.cnt));
  await p.end();
})();
'

echo ""
echo "8. Non-régression: conversations..."
kubectl exec -n keybuzz-api-dev "$POD" -- node -e '
const {Pool} = require("pg");
const p = new Pool();
(async () => {
  const r = await p.query("SELECT count(*) as cnt FROM conversations");
  console.log("Total conversations:", r.rows[0].cnt);
  await p.end();
})();
'

echo ""
echo "9. Health check API..."
curl -sf "$API/health" 2>&1
echo ""

echo ""
echo "============================================"
echo " Validation terminée"
echo "============================================"
