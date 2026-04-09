#!/usr/bin/env python3
"""
PH-SHOPIFY-02.2 — Fix: Add expiring=1 to token exchange + refresh_token support
Since April 1, 2026, Shopify requires expiring=1 in the token exchange request.
Without it, non-expiring tokens are issued and rejected by the API.

Changes:
1. shopifyAuth.service.ts: exchangeToken adds expiring=1, returns refresh_token
2. shopifyAuth.service.ts: saveConnection stores refresh_token
3. shopifyAuth.service.ts: rotateToken uses refresh_token grant
4. DB: add refresh_token_enc column to shopify_connections
"""

import subprocess

API_DIR = "/opt/keybuzz/keybuzz-api/src/modules/marketplaces/shopify"

def migrate_db():
    print("[1/3] Adding refresh_token_enc column...")
    pod = subprocess.check_output(
        "kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}'",
        shell=True, text=True
    ).strip().strip("'")

    cmd = f"""kubectl exec -n keybuzz-api-dev {pod} -- node -e '
const {{Pool}} = require("pg");
const p = new Pool();
(async () => {{
  const check = await p.query(
    "SELECT 1 FROM information_schema.columns WHERE table_name = $1 AND column_name = $2",
    ["shopify_connections", "refresh_token_enc"]
  );
  if (check.rows.length === 0) {{
    await p.query("ALTER TABLE shopify_connections ADD COLUMN refresh_token_enc TEXT");
    console.log("OK: refresh_token_enc column added");
  }} else {{
    console.log("OK: refresh_token_enc already exists");
  }}
  await p.end();
}})();
'"""
    subprocess.run(cmd, shell=True, check=True)

def update_auth_service():
    print("[2/3] Updating shopifyAuth.service.ts (expiring=1 + refresh_token)...")
    path = f"{API_DIR}/shopifyAuth.service.ts"

    with open(path, 'r') as f:
        content = f.read()

    # 1. Fix TokenExchangeResult interface to include refresh_token
    old_interface = """export interface TokenExchangeResult {
  access_token: string;
  scope: string;
  expires_in?: number;
}"""
    new_interface = """export interface TokenExchangeResult {
  access_token: string;
  scope: string;
  expires_in?: number;
  refresh_token?: string;
}"""
    content = content.replace(old_interface, new_interface)

    # 2. Fix exchangeToken to add expiring=1
    old_exchange_body = "body: JSON.stringify({ client_id: clientId, client_secret: clientSecret, code }),"
    new_exchange_body = "body: JSON.stringify({ client_id: clientId, client_secret: clientSecret, code, expiring: 1 }),"
    content = content.replace(old_exchange_body, new_exchange_body)

    # 3. Fix rotateToken to use refresh_token grant
    old_rotate = """  console.log(`[Shopify Auth] Rotating token for ${shop}...`);
  const resp = await fetch(`https://${shop}/admin/oauth/access_token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      client_id: clientId,
      client_secret: clientSecret,
      grant_type: 'urn:ietf:params:oauth:grant-type:token-exchange',
      subject_token: currentToken,
      subject_token_type: 'urn:ietf:params:oauth:token-type:access_token',
      requested_token_type: 'urn:ietf:params:oauth:token-type:offline-access-token',
    }),
  });"""
    new_rotate = """  console.log(`[Shopify Auth] Rotating token for ${shop} using refresh_token...`);
  const resp = await fetch(`https://${shop}/admin/oauth/access_token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      client_id: clientId,
      client_secret: clientSecret,
      grant_type: 'refresh_token',
      refresh_token: currentToken,
    }),
  });"""
    content = content.replace(old_rotate, new_rotate)

    # 4. Fix rotateToken function signature (currentToken is now refreshToken)
    old_sig = "export async function rotateToken(shop: string, currentToken: string): Promise<TokenExchangeResult> {"
    new_sig = "export async function rotateToken(shop: string, refreshToken: string): Promise<TokenExchangeResult> {"
    content = content.replace(old_sig, new_sig)

    # 5. Fix saveConnection to store refresh_token
    old_save_insert = """  await pool.query(
    `INSERT INTO shopify_connections (id, tenant_id, shop_domain, access_token_enc, scopes, status, token_expires_at, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, 'active', $6, NOW(), NOW())`,
    [id, tenantId, shop, enc, scopes, expiresAt]
  );"""
    new_save_insert = """  const refreshEnc = refreshToken ? encryptToken(refreshToken) : null;
  await pool.query(
    `INSERT INTO shopify_connections (id, tenant_id, shop_domain, access_token_enc, scopes, status, token_expires_at, refresh_token_enc, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, 'active', $6, $7, NOW(), NOW())`,
    [id, tenantId, shop, enc, scopes, expiresAt, refreshEnc]
  );"""
    content = content.replace(old_save_insert, new_save_insert)

    # 6. Fix saveConnection signature to accept refreshToken
    old_save_sig = """export async function saveConnection(
  tenantId: string, shop: string, token: string, scopes: string, expiresIn?: number
): Promise<string> {"""
    new_save_sig = """export async function saveConnection(
  tenantId: string, shop: string, token: string, scopes: string, expiresIn?: number, refreshToken?: string
): Promise<string> {"""
    content = content.replace(old_save_sig, new_save_sig)

    # 7. Fix updateConnectionToken to also update refresh_token
    old_update = """  await pool.query(
    `UPDATE shopify_connections SET access_token_enc = $1, token_expires_at = $2, updated_at = NOW() WHERE id = $3`,
    [enc, expiresAt, connectionId]
  );"""
    new_update = """  const refreshEnc = refreshToken ? encryptToken(refreshToken) : null;
  await pool.query(
    `UPDATE shopify_connections SET access_token_enc = $1, token_expires_at = $2, refresh_token_enc = COALESCE($3, refresh_token_enc), updated_at = NOW() WHERE id = $4`,
    [enc, expiresAt, refreshEnc, connectionId]
  );"""
    content = content.replace(old_update, new_update)

    # 8. Fix updateConnectionToken signature
    old_update_sig = """export async function updateConnectionToken(
  connectionId: string, newToken: string, expiresIn?: number
): Promise<void> {"""
    new_update_sig = """export async function updateConnectionToken(
  connectionId: string, newToken: string, expiresIn?: number, refreshToken?: string
): Promise<void> {"""
    content = content.replace(old_update_sig, new_update_sig)

    with open(path, 'w') as f:
        f.write(content)
    print("   OK: shopifyAuth.service.ts updated with expiring=1 + refresh_token")

def update_orders_service():
    print("[3/3] Updating shopifyOrders.service.ts (getActiveConnection reads refresh_token)...")
    path = f"{API_DIR}/shopifyOrders.service.ts"

    with open(path, 'r') as f:
        content = f.read()

    # Fix getActiveConnection to read refresh_token and pass it to rotateToken
    old_query = "`SELECT id, shop_domain, access_token_enc, token_expires_at FROM shopify_connections WHERE tenant_id = $1 AND status = 'active' LIMIT 1`"
    new_query = "`SELECT id, shop_domain, access_token_enc, token_expires_at, refresh_token_enc FROM shopify_connections WHERE tenant_id = $1 AND status = 'active' LIMIT 1`"
    content = content.replace(old_query, new_query)

    # Fix the rotation call to use refresh_token
    old_rotate_call = """      const { rotateToken, updateConnectionToken } = await import('./shopifyAuth.service');
      const rotated = await rotateToken(row.shop_domain, accessToken);
      await updateConnectionToken(row.id, rotated.access_token, rotated.expires_in);"""
    new_rotate_call = """      const { rotateToken, updateConnectionToken } = await import('./shopifyAuth.service');
      const { decryptToken: decrypt } = await import('./shopifyCrypto.service');
      const refreshToken = row.refresh_token_enc ? decrypt(row.refresh_token_enc) : null;
      if (!refreshToken) {
        console.warn(`[Shopify] No refresh_token for tenant=${tenantId}, cannot rotate`);
      } else {
        const rotated = await rotateToken(row.shop_domain, refreshToken);
        await updateConnectionToken(row.id, rotated.access_token, rotated.expires_in, rotated.refresh_token);
        accessToken = rotated.access_token;
      }"""
    content = content.replace(old_rotate_call, new_rotate_call)

    # Remove the old accessToken assignment after rotation (it's now inside the if/else)
    old_assign = """      accessToken = rotated.access_token;
      console.log(`[Shopify] Token auto-rotated for tenant=${tenantId}`);"""
    new_assign = """      console.log(`[Shopify] Token auto-rotated for tenant=${tenantId}`);"""
    content = content.replace(old_assign, new_assign)

    with open(path, 'w') as f:
        f.write(content)
    print("   OK: shopifyOrders.service.ts updated")

def update_routes():
    print("[bonus] Updating shopify.routes.ts (pass refresh_token to saveConnection)...")
    path = f"{API_DIR}/shopify.routes.ts"

    with open(path, 'r') as f:
        content = f.read()

    # Fix the saveConnection call in callback to pass refresh_token
    old_save = "const connId = await saveConnection(oauthState.tenantId, shop, tok.access_token, tok.scope, tok.expires_in);"
    new_save = "const connId = await saveConnection(oauthState.tenantId, shop, tok.access_token, tok.scope, tok.expires_in, tok.refresh_token);"
    content = content.replace(old_save, new_save)

    with open(path, 'w') as f:
        f.write(content)
    print("   OK: shopify.routes.ts updated")


if __name__ == '__main__':
    migrate_db()
    update_auth_service()
    update_orders_service()
    update_routes()
    print("\n=== All expiring token fixes applied ===")
    print("Next: Build + deploy + reconnect")
