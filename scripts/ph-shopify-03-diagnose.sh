#!/bin/bash
POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')

echo "=== 1. Check stored scopes in DB ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
(async()=>{
  const r=await p.query(\"SELECT id, tenant_id, shop_domain, scopes, status, created_at FROM shopify_connections ORDER BY created_at DESC LIMIT 5\");
  console.log(JSON.stringify(r.rows,null,2));
  await p.end();
})();
"

echo ""
echo "=== 2. Test token with REST API (shop.json — no scope needed) ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
const crypto=require('crypto');
(async()=>{
  const r=await p.query(\"SELECT shop_domain, access_token_enc FROM shopify_connections WHERE status='active' LIMIT 1\");
  if(!r.rows.length){console.log('No active connection');await p.end();return;}
  const row=r.rows[0];
  const ALGORITHM='aes-256-gcm';
  const key=Buffer.from(process.env.SHOPIFY_ENCRYPTION_KEY,'hex');
  const [ivHex,tagHex,enc]=row.access_token_enc.split(':');
  const decipher=crypto.createDecipheriv(ALGORITHM,key,Buffer.from(ivHex,'hex'));
  decipher.setAuthTag(Buffer.from(tagHex,'hex'));
  let dec=decipher.update(enc,'hex','utf8');
  dec+=decipher.final('utf8');
  console.log('Token length:', dec.length);
  const resp=await fetch('https://'+row.shop_domain+'/admin/api/2024-10/shop.json',{headers:{'X-Shopify-Access-Token':dec}});
  console.log('shop.json status:', resp.status);
  if(resp.ok){const d=await resp.json();console.log('Shop name:', d.shop?.name);}
  else{console.log('Error:', await resp.text());}
  await p.end();
})();
"

echo ""
echo "=== 3. Test token with REST orders (needs read_orders) ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
const crypto=require('crypto');
(async()=>{
  const r=await p.query(\"SELECT shop_domain, access_token_enc FROM shopify_connections WHERE status='active' LIMIT 1\");
  if(!r.rows.length){console.log('No active connection');await p.end();return;}
  const row=r.rows[0];
  const key=Buffer.from(process.env.SHOPIFY_ENCRYPTION_KEY,'hex');
  const [ivHex,tagHex,enc]=row.access_token_enc.split(':');
  const decipher=crypto.createDecipheriv('aes-256-gcm',key,Buffer.from(ivHex,'hex'));
  decipher.setAuthTag(Buffer.from(tagHex,'hex'));
  let dec=decipher.update(enc,'hex','utf8');
  dec+=decipher.final('utf8');
  const resp=await fetch('https://'+row.shop_domain+'/admin/api/2024-10/orders.json?limit=1&status=any',{headers:{'X-Shopify-Access-Token':dec}});
  console.log('orders.json status:', resp.status);
  if(resp.ok){const d=await resp.json();console.log('Orders count:', d.orders?.length);}
  else{const t=await resp.text();console.log('Error:', t.substring(0,300));}
  await p.end();
})();
"

echo ""
echo "=== 4. Check token scopes via access_scopes endpoint ==="
kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const {Pool}=require('pg');const p=new Pool();
const crypto=require('crypto');
(async()=>{
  const r=await p.query(\"SELECT shop_domain, access_token_enc FROM shopify_connections WHERE status='active' LIMIT 1\");
  if(!r.rows.length){console.log('No active connection');await p.end();return;}
  const row=r.rows[0];
  const key=Buffer.from(process.env.SHOPIFY_ENCRYPTION_KEY,'hex');
  const [ivHex,tagHex,enc]=row.access_token_enc.split(':');
  const decipher=crypto.createDecipheriv('aes-256-gcm',key,Buffer.from(ivHex,'hex'));
  decipher.setAuthTag(Buffer.from(tagHex,'hex'));
  let dec=decipher.update(enc,'hex','utf8');
  dec+=decipher.final('utf8');
  const resp=await fetch('https://'+row.shop_domain+'/admin/oauth/access_scopes.json',{headers:{'X-Shopify-Access-Token':dec}});
  console.log('access_scopes status:', resp.status);
  if(resp.ok){const d=await resp.json();console.log('Granted scopes:', JSON.stringify(d));}
  else{console.log('Error:', await resp.text());}
  await p.end();
})();
"
