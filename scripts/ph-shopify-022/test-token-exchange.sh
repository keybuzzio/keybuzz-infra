#!/bin/bash
echo "=== Test Token Exchange (convert non-expiring -> rotating) ==="

POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}')

kubectl exec -n keybuzz-api-dev "$POD" -- node -e '
const {Pool} = require("pg");
const crypto = require("crypto");

const ALGORITHM = "aes-256-gcm";
function decryptToken(ciphertext) {
  const key = Buffer.from(process.env.SHOPIFY_ENCRYPTION_KEY, "hex");
  const [ivHex, tagHex, enc] = ciphertext.split(":");
  const decipher = crypto.createDecipheriv(ALGORITHM, key, Buffer.from(ivHex, "hex"));
  decipher.setAuthTag(Buffer.from(tagHex, "hex"));
  let dec = decipher.update(enc, "hex", "utf8");
  dec += decipher.final("utf8");
  return dec;
}

(async () => {
  const p = new Pool();
  const r = await p.query("SELECT shop_domain, access_token_enc FROM shopify_connections WHERE status = '\''active'\'' LIMIT 1");
  if (!r.rows.length) { console.log("No active connection"); await p.end(); return; }

  const shop = r.rows[0].shop_domain;
  const token = decryptToken(r.rows[0].access_token_enc);
  console.log(`Shop: ${shop}, Token length: ${token.length}`);

  // Test 1: Direct API call with current token
  console.log("\n--- Test 1: shop.json (current token) ---");
  const shopResp = await fetch(`https://${shop}/admin/api/2024-10/shop.json`, {
    headers: { "X-Shopify-Access-Token": token }
  });
  console.log(`Status: ${shopResp.status}`);
  if (!shopResp.ok) console.log(await shopResp.text().then(t => t.substring(0, 200)));

  // Test 2: Token Exchange API (try to convert to rotating)
  console.log("\n--- Test 2: Token Exchange API ---");
  const exchangeResp = await fetch(`https://${shop}/admin/oauth/access_token`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      client_id: process.env.SHOPIFY_CLIENT_ID,
      client_secret: process.env.SHOPIFY_CLIENT_SECRET,
      grant_type: "urn:ietf:params:oauth:grant-type:token-exchange",
      subject_token: token,
      subject_token_type: "urn:ietf:params:oauth:token-type:access_token",
      requested_token_type: "urn:ietf:params:oauth:token-type:offline-access-token"
    })
  });
  console.log(`Status: ${exchangeResp.status}`);
  const exchangeData = await exchangeResp.json();
  const safeKeys = Object.keys(exchangeData).filter(k => k !== "access_token");
  console.log(`Response keys: ${JSON.stringify(safeKeys)}`);
  console.log(`expires_in: ${exchangeData.expires_in || "NONE"}`);
  console.log(`scope: ${exchangeData.scope || "N/A"}`);
  if (exchangeData.error) console.log(`Error: ${exchangeData.error} - ${exchangeData.error_description || ""}`);

  await p.end();
})();
'
