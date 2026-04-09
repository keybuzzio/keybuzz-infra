#!/usr/bin/env python3
"""
PH-SHOPIFY-02.2 — Token Rotation for Shopify Expiring Offline Tokens
Applies changes to:
  1. DB: adds token_expires_at column
  2. shopifyAuth.service.ts: exchangeToken returns expires_in, saveConnection stores it
  3. shopifyOrders.service.ts: getActiveConnection auto-rotates expired tokens
"""
import subprocess, sys, textwrap

API_DIR = "/opt/keybuzz/keybuzz-api/src/modules/marketplaces/shopify"

# ─── 1. DB migration ─────────────────────────────────────────
def migrate_db():
    print("[1/4] Adding token_expires_at column...")
    pod = subprocess.check_output(
        "kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}'",
        shell=True, text=True
    ).strip().strip("'")

    sql = textwrap.dedent("""
        DO $$ BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM information_schema.columns
                WHERE table_name = 'shopify_connections' AND column_name = 'token_expires_at'
            ) THEN
                ALTER TABLE shopify_connections ADD COLUMN token_expires_at TIMESTAMPTZ;
            END IF;
        END $$;
    """).strip().replace('\n', ' ')

    cmd = f"""kubectl exec -n keybuzz-api-dev {pod} -- node -e 'const {{Pool}} = require("pg"); const p = new Pool(); (async () => {{ await p.query(`{sql}`); console.log("OK: token_expires_at column ready"); await p.end(); }})()'"""
    subprocess.run(cmd, shell=True, check=True)

# ─── 2. Update shopifyAuth.service.ts ────────────────────────
def update_auth_service():
    print("[2/4] Updating shopifyAuth.service.ts (exchangeToken + saveConnection)...")
    path = f"{API_DIR}/shopifyAuth.service.ts"

    new_content = textwrap.dedent("""\
        import crypto from 'crypto';
        import { encryptToken } from './shopifyCrypto.service';
        import { getPool } from '../../../config/database';
        import { getRedis } from '../../../config/redis';

        const SCOPES = 'read_orders,read_customers,read_fulfillments,read_returns';
        const STATE_TTL = 600;

        export function normalizeShop(domain: string): string {
          let s = domain.trim().toLowerCase().replace(/^https?:\\/\\//, '').replace(/\\/$/, '');
          if (!s.includes('.')) s = `${s}.myshopify.com`;
          return s;
        }

        export function buildAuthUrl(shop: string, state: string): string {
          const clientId = process.env.SHOPIFY_CLIENT_ID;
          const redirectUri = process.env.SHOPIFY_REDIRECT_URI;
          if (!clientId || !redirectUri) throw new Error('Shopify OAuth not configured');
          return `https://${shop}/admin/oauth/authorize?client_id=${clientId}&scope=${SCOPES}&redirect_uri=${encodeURIComponent(redirectUri)}&state=${state}`;
        }

        export async function storeOAuthState(state: string, tenantId: string, shop: string): Promise<void> {
          const redis = getRedis();
          await redis.setex(`shopify:oauth:${state}`, STATE_TTL, JSON.stringify({ tenantId, shop }));
        }

        export async function popOAuthState(state: string): Promise<{ tenantId: string; shop: string } | null> {
          const redis = getRedis();
          const raw = await redis.get(`shopify:oauth:${state}`);
          if (!raw) return null;
          await redis.del(`shopify:oauth:${state}`);
          return JSON.parse(raw);
        }

        export function verifyHmac(query: Record<string, string>, secret: string): boolean {
          const { hmac, ...rest } = query;
          if (!hmac) return false;
          const msg = Object.keys(rest).sort().map(k => `${k}=${rest[k]}`).join('&');
          const computed = crypto.createHmac('sha256', secret).update(msg).digest('hex');
          try { return crypto.timingSafeEqual(Buffer.from(hmac), Buffer.from(computed)); }
          catch { return false; }
        }

        export interface TokenExchangeResult {
          access_token: string;
          scope: string;
          expires_in?: number;
        }

        export async function exchangeToken(shop: string, code: string): Promise<TokenExchangeResult> {
          const clientId = process.env.SHOPIFY_CLIENT_ID;
          const clientSecret = process.env.SHOPIFY_CLIENT_SECRET;
          if (!clientId || !clientSecret) throw new Error('Shopify credentials not configured');
          const resp = await fetch(`https://${shop}/admin/oauth/access_token`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ client_id: clientId, client_secret: clientSecret, code }),
          });
          if (!resp.ok) throw new Error(`Token exchange failed: ${resp.status}`);
          const data = await resp.json() as TokenExchangeResult;
          if (data.expires_in) {
            console.log(`[Shopify Auth] Token expires in ${data.expires_in}s (${Math.round(data.expires_in / 3600)}h)`);
          }
          return data;
        }

        export async function rotateToken(shop: string, currentToken: string): Promise<TokenExchangeResult> {
          const clientId = process.env.SHOPIFY_CLIENT_ID;
          const clientSecret = process.env.SHOPIFY_CLIENT_SECRET;
          if (!clientId || !clientSecret) throw new Error('Shopify credentials not configured');
          console.log(`[Shopify Auth] Rotating token for ${shop}...`);
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
          });
          if (!resp.ok) {
            const errText = await resp.text();
            throw new Error(`Token rotation failed: ${resp.status} ${errText.substring(0, 200)}`);
          }
          const data = await resp.json() as TokenExchangeResult;
          console.log(`[Shopify Auth] Token rotated, new expiry: ${data.expires_in || 'unknown'}s`);
          return data;
        }

        export async function saveConnection(
          tenantId: string, shop: string, token: string, scopes: string, expiresIn?: number
        ): Promise<string> {
          const pool = await getPool();
          const id = crypto.randomUUID();
          const enc = encryptToken(token);
          const expiresAt = expiresIn
            ? new Date(Date.now() + expiresIn * 1000).toISOString()
            : null;

          await pool.query(
            `UPDATE shopify_connections SET status = 'disconnected', updated_at = NOW() WHERE tenant_id = $1 AND status = 'active'`,
            [tenantId]
          );
          await pool.query(
            `INSERT INTO shopify_connections (id, tenant_id, shop_domain, access_token_enc, scopes, status, token_expires_at, created_at, updated_at)
             VALUES ($1, $2, $3, $4, $5, 'active', $6, NOW(), NOW())`,
            [id, tenantId, shop, enc, scopes, expiresAt]
          );
          if (expiresAt) console.log(`[Shopify Auth] Connection saved, token expires at ${expiresAt}`);
          return id;
        }

        export async function updateConnectionToken(
          connectionId: string, newToken: string, expiresIn?: number
        ): Promise<void> {
          const pool = await getPool();
          const enc = encryptToken(newToken);
          const expiresAt = expiresIn
            ? new Date(Date.now() + expiresIn * 1000).toISOString()
            : null;
          await pool.query(
            `UPDATE shopify_connections SET access_token_enc = $1, token_expires_at = $2, updated_at = NOW() WHERE id = $3`,
            [enc, expiresAt, connectionId]
          );
        }

        export async function getStatus(tenantId: string) {
          const pool = await getPool();
          const r = await pool.query(
            `SELECT shop_domain, scopes, created_at FROM shopify_connections WHERE tenant_id = $1 AND status = 'active' ORDER BY created_at DESC LIMIT 1`,
            [tenantId]
          );
          if (r.rows.length === 0) return { connected: false };
          return { connected: true, shopDomain: r.rows[0].shop_domain, scopes: r.rows[0].scopes, connectedAt: r.rows[0].created_at };
        }

        export async function disconnect(tenantId: string): Promise<boolean> {
          const pool = await getPool();
          const r = await pool.query(
            `UPDATE shopify_connections SET status = 'disconnected', updated_at = NOW() WHERE tenant_id = $1 AND status = 'active'`,
            [tenantId]
          );
          return (r.rowCount ?? 0) > 0;
        }
    """)
    with open(path, 'w') as f:
        f.write(new_content)
    print("   OK: shopifyAuth.service.ts updated")

# ─── 3. Update shopifyOrders.service.ts ──────────────────────
def update_orders_service():
    print("[3/4] Updating shopifyOrders.service.ts (auto-rotate in getActiveConnection)...")
    path = f"{API_DIR}/shopifyOrders.service.ts"

    with open(path, 'r') as f:
        content = f.read()

    # Replace the getActiveConnection function with one that handles token rotation
    old_fn = """export async function getActiveConnection(tenantId: string) {
  const pool = await getPool();
  const r = await pool.query(
    `SELECT id, shop_domain, access_token_enc FROM shopify_connections WHERE tenant_id = $1 AND status = 'active' LIMIT 1`,
    [tenantId]
  );
  if (r.rows.length === 0) return null;
  const row = r.rows[0];
  return {
    connectionId: row.id as string,
    shopDomain: row.shop_domain as string,
    accessToken: decryptToken(row.access_token_enc),
  };
}"""

    new_fn = """export async function getActiveConnection(tenantId: string) {
  const pool = await getPool();
  const r = await pool.query(
    `SELECT id, shop_domain, access_token_enc, token_expires_at FROM shopify_connections WHERE tenant_id = $1 AND status = 'active' LIMIT 1`,
    [tenantId]
  );
  if (r.rows.length === 0) return null;
  const row = r.rows[0];
  let accessToken = decryptToken(row.access_token_enc);

  const expiresAt = row.token_expires_at ? new Date(row.token_expires_at) : null;
  const ROTATION_BUFFER_MS = 5 * 60 * 1000;
  if (expiresAt && expiresAt.getTime() - Date.now() < ROTATION_BUFFER_MS) {
    try {
      const { rotateToken, updateConnectionToken } = await import('./shopifyAuth.service');
      const rotated = await rotateToken(row.shop_domain, accessToken);
      await updateConnectionToken(row.id, rotated.access_token, rotated.expires_in);
      accessToken = rotated.access_token;
      console.log(`[Shopify] Token auto-rotated for tenant=${tenantId}`);
    } catch (err: any) {
      console.error(`[Shopify] Token rotation failed for tenant=${tenantId}: ${err.message}`);
    }
  }

  return {
    connectionId: row.id as string,
    shopDomain: row.shop_domain as string,
    accessToken,
  };
}"""

    if old_fn not in content:
        print("   WARNING: getActiveConnection not found with expected format, trying flexible match...")
        # Try to find it with a more flexible approach
        import re
        pattern = r'export async function getActiveConnection\(tenantId: string\)\s*\{[^}]+return \{[^}]+\};\s*\}'
        match = re.search(pattern, content, re.DOTALL)
        if match:
            content = content[:match.start()] + new_fn + content[match.end():]
        else:
            print("   ERROR: Could not find getActiveConnection function!")
            sys.exit(1)
    else:
        content = content.replace(old_fn, new_fn)

    with open(path, 'w') as f:
        f.write(content)
    print("   OK: shopifyOrders.service.ts updated")

# ─── 4. Update shopify.routes.ts callback ────────────────────
def update_routes():
    print("[4/4] Updating shopify.routes.ts (pass expires_in to saveConnection)...")
    path = f"{API_DIR}/shopify.routes.ts"

    with open(path, 'r') as f:
        content = f.read()

    # Fix the saveConnection call to pass expires_in
    old_save = "const connId = await saveConnection(oauthState.tenantId, shop, tok.access_token, tok.scope);"
    new_save = "const connId = await saveConnection(oauthState.tenantId, shop, tok.access_token, tok.scope, tok.expires_in);"

    if old_save in content:
        content = content.replace(old_save, new_save)
    else:
        print("   WARNING: saveConnection call not found with expected format")

    # Also fix the import if needed - add updateConnectionToken
    if 'updateConnectionToken' not in content:
        old_import = "import { saveConnection, getStatus, disconnect"
        if old_import in content:
            content = content.replace(old_import, "import { saveConnection, updateConnectionToken, getStatus, disconnect")

    with open(path, 'w') as f:
        f.write(content)
    print("   OK: shopify.routes.ts updated")

if __name__ == '__main__':
    # migrate_db() — already done via migrate-db.sh
    update_auth_service()
    update_orders_service()
    update_routes()
    print("\n=== All token rotation changes applied ===")
    print("Next: Build + deploy API")
