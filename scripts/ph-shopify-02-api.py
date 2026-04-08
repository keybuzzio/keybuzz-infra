#!/usr/bin/env python3
"""PH-SHOPIFY-02: Create API module for Shopify OAuth + patch app.ts/tenantGuard/channelsService"""
import os, shutil

API_ROOT = "/opt/keybuzz/keybuzz-api/src"
SHOPIFY_DIR = f"{API_ROOT}/modules/marketplaces/shopify"

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"  Created: {path}")

def patch_file(path, old, new, label):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    if old not in content:
        print(f"  WARN: target not found for [{label}] in {path}")
        return False
    bak = path + '.bak-shopify-02'
    if not os.path.exists(bak):
        shutil.copy2(path, bak)
    content = content.replace(old, new, 1)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"  OK: {label}")
    return True

print("=== PH-SHOPIFY-02: API MODULE ===\n")

# ── 1. shopifyCrypto.service.ts ──────────────────────────────
print("[1/8] shopifyCrypto.service.ts")
write_file(f"{SHOPIFY_DIR}/shopifyCrypto.service.ts", r'''import crypto from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 16;

function getKey(): Buffer {
  const key = process.env.SHOPIFY_ENCRYPTION_KEY;
  if (!key || key.length < 32) throw new Error('SHOPIFY_ENCRYPTION_KEY missing or too short');
  return Buffer.from(key, 'hex');
}

export function encryptToken(plaintext: string): string {
  const key = getKey();
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
  let enc = cipher.update(plaintext, 'utf8', 'hex');
  enc += cipher.final('hex');
  const tag = cipher.getAuthTag();
  return `${iv.toString('hex')}:${tag.toString('hex')}:${enc}`;
}

export function decryptToken(ciphertext: string): string {
  const key = getKey();
  const [ivHex, tagHex, enc] = ciphertext.split(':');
  const decipher = crypto.createDecipheriv(ALGORITHM, key, Buffer.from(ivHex, 'hex'));
  decipher.setAuthTag(Buffer.from(tagHex, 'hex'));
  let dec = decipher.update(enc, 'hex', 'utf8');
  dec += decipher.final('utf8');
  return dec;
}
''')

# ── 2. shopifyAuth.service.ts ────────────────────────────────
print("[2/8] shopifyAuth.service.ts")
write_file(f"{SHOPIFY_DIR}/shopifyAuth.service.ts", r'''import crypto from 'crypto';
import { encryptToken } from './shopifyCrypto.service';
import { getPool } from '../../../config/database';
import { getRedis } from '../../../config/redis';

const SCOPES = 'read_orders,read_products,read_customers';
const STATE_TTL = 600;

export function normalizeShop(domain: string): string {
  let s = domain.trim().toLowerCase().replace(/^https?:\/\//, '').replace(/\/$/, '');
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

export async function exchangeToken(shop: string, code: string): Promise<{ access_token: string; scope: string }> {
  const clientId = process.env.SHOPIFY_CLIENT_ID;
  const clientSecret = process.env.SHOPIFY_CLIENT_SECRET;
  if (!clientId || !clientSecret) throw new Error('Shopify credentials not configured');
  const resp = await fetch(`https://${shop}/admin/oauth/access_token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ client_id: clientId, client_secret: clientSecret, code }),
  });
  if (!resp.ok) throw new Error(`Token exchange failed: ${resp.status}`);
  return resp.json();
}

export async function saveConnection(tenantId: string, shop: string, token: string, scopes: string): Promise<string> {
  const pool = await getPool();
  const id = crypto.randomUUID();
  const enc = encryptToken(token);
  await pool.query(
    `UPDATE shopify_connections SET status = 'disconnected', updated_at = NOW() WHERE tenant_id = $1 AND status = 'active'`,
    [tenantId]
  );
  await pool.query(
    `INSERT INTO shopify_connections (id, tenant_id, shop_domain, access_token_enc, scopes, status, created_at, updated_at)
     VALUES ($1, $2, $3, $4, $5, 'active', NOW(), NOW())`,
    [id, tenantId, shop, enc, scopes]
  );
  return id;
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
''')

# ── 3. shopify.routes.ts ─────────────────────────────────────
print("[3/8] shopify.routes.ts")
write_file(f"{SHOPIFY_DIR}/shopify.routes.ts", r'''import { FastifyInstance } from 'fastify';
import crypto from 'crypto';
import { normalizeShop, buildAuthUrl, storeOAuthState, popOAuthState, verifyHmac, exchangeToken, saveConnection, getStatus, disconnect } from './shopifyAuth.service';

export async function shopifyRoutes(app: FastifyInstance) {

  app.get('/status', async (request, reply) => {
    const tenantId = (request.query as any).tenantId || request.headers['x-tenant-id'];
    if (!tenantId) return reply.status(400).send({ error: 'tenantId required' });
    try {
      return reply.send(await getStatus(tenantId as string));
    } catch (err: any) {
      return reply.send({ connected: false, error: err.message });
    }
  });

  app.post('/connect', async (request, reply) => {
    const body = request.body as any || {};
    const tenantId = body.tenantId || request.headers['x-tenant-id'];
    const shopDomain = body.shopDomain;
    if (!tenantId) return reply.status(400).send({ error: 'tenantId required' });
    if (!shopDomain) return reply.status(400).send({ error: 'shopDomain required' });
    if (!process.env.SHOPIFY_CLIENT_ID) return reply.status(503).send({ error: 'Shopify OAuth not configured' });
    try {
      const state = crypto.randomBytes(24).toString('hex');
      const shop = normalizeShop(shopDomain);
      await storeOAuthState(state, tenantId as string, shop);
      const authUrl = buildAuthUrl(shop, state);
      console.log(`[Shopify] OAuth start tenant=${tenantId} shop=${shop}`);
      return reply.send({ authUrl });
    } catch (err: any) {
      return reply.status(500).send({ error: err.message });
    }
  });

  app.get('/callback', async (request, reply) => {
    const q = request.query as Record<string, string>;
    const { code, shop, state } = q;
    const secret = process.env.SHOPIFY_CLIENT_SECRET;
    const clientRedirect = process.env.SHOPIFY_CLIENT_REDIRECT_URL || 'https://client-dev.keybuzz.io/channels';
    if (!code || !shop || !state) return reply.redirect(`${clientRedirect}?shopify_error=missing_params`);
    if (!secret) return reply.redirect(`${clientRedirect}?shopify_error=not_configured`);
    if (!verifyHmac(q, secret)) {
      console.error('[Shopify] HMAC failed');
      return reply.redirect(`${clientRedirect}?shopify_error=hmac_failed`);
    }
    const oauthState = await popOAuthState(state);
    if (!oauthState) return reply.redirect(`${clientRedirect}?shopify_error=expired_state`);
    try {
      const tok = await exchangeToken(shop, code);
      await saveConnection(oauthState.tenantId, shop, tok.access_token, tok.scope);
      console.log(`[Shopify] Connected tenant=${oauthState.tenantId} shop=${shop}`);
      return reply.redirect(`${clientRedirect}?shopify_connected=true`);
    } catch (err: any) {
      console.error('[Shopify] callback error:', err.message);
      return reply.redirect(`${clientRedirect}?shopify_error=${encodeURIComponent(err.message)}`);
    }
  });

  app.post('/disconnect', async (request, reply) => {
    const body = request.body as any || {};
    const tenantId = body.tenantId || request.headers['x-tenant-id'];
    if (!tenantId) return reply.status(400).send({ error: 'tenantId required' });
    try {
      const ok = await disconnect(tenantId as string);
      console.log(`[Shopify] Disconnect tenant=${tenantId} result=${ok}`);
      return reply.send({ disconnected: ok });
    } catch (err: any) {
      return reply.status(500).send({ error: err.message });
    }
  });
}
''')

# ── 4. shopifyWebhook.routes.ts ──────────────────────────────
print("[4/8] shopifyWebhook.routes.ts")
write_file(f"{SHOPIFY_DIR}/shopifyWebhook.routes.ts", r'''import { FastifyInstance } from 'fastify';
import crypto from 'crypto';
import { getPool } from '../../../config/database';

export async function shopifyWebhookRoutes(app: FastifyInstance) {

  app.post('/shopify', async (request, reply) => {
    const hmac = request.headers['x-shopify-hmac-sha256'] as string;
    const topic = request.headers['x-shopify-topic'] as string;
    const shopDomain = request.headers['x-shopify-shop-domain'] as string;
    const secret = process.env.SHOPIFY_CLIENT_SECRET;

    if (!hmac || !secret) {
      return reply.status(401).send({ error: 'Unauthorized' });
    }

    const bodyStr = JSON.stringify(request.body);
    const computed = crypto.createHmac('sha256', secret).update(bodyStr, 'utf8').digest('base64');
    const valid = (() => {
      try { return crypto.timingSafeEqual(Buffer.from(hmac), Buffer.from(computed)); }
      catch { return false; }
    })();

    if (!valid) {
      console.warn(`[Shopify Webhook] HMAC failed for ${topic} from ${shopDomain}`);
      return reply.status(401).send({ error: 'HMAC verification failed' });
    }

    // Look up tenant from shop domain
    const pool = await getPool();
    const conn = await pool.query(
      `SELECT id, tenant_id FROM shopify_connections WHERE shop_domain = $1 AND status = 'active' LIMIT 1`,
      [shopDomain]
    );
    const tenantId = conn.rows[0]?.tenant_id || 'unknown';
    const connectionId = conn.rows[0]?.id || null;

    await pool.query(
      `INSERT INTO shopify_webhook_events (id, tenant_id, connection_id, topic, payload, processed, created_at)
       VALUES ($1, $2, $3, $4, $5, false, NOW())`,
      [crypto.randomUUID(), tenantId, connectionId, topic || 'unknown', JSON.stringify(request.body)]
    );

    console.log(`[Shopify Webhook] ${topic} from ${shopDomain} (tenant=${tenantId}) — logged, not processed`);
    return reply.status(200).send({ ok: true });
  });
}
''')

# ── 5. index.ts ──────────────────────────────────────────────
print("[5/8] index.ts")
write_file(f"{SHOPIFY_DIR}/index.ts", r'''export { shopifyRoutes } from './shopify.routes';
export { shopifyWebhookRoutes } from './shopifyWebhook.routes';
''')

# ── 6. Patch app.ts ──────────────────────────────────────────
print("[6/8] Patch app.ts")
APP_TS = f"{API_ROOT}/app.ts"

patch_file(APP_TS,
    "import { channelsRoutes } from \"./modules/channels/channelsRoutes\";",
    "import { channelsRoutes } from \"./modules/channels/channelsRoutes\";\nimport { shopifyRoutes, shopifyWebhookRoutes } from './modules/marketplaces/shopify';",
    "app.ts: import shopify"
)

patch_file(APP_TS,
    "  app.register(channelsRoutes, { prefix: \"/channels\" });",
    "  app.register(channelsRoutes, { prefix: \"/channels\" });\n  app.register(shopifyRoutes, { prefix: '/shopify' });\n  app.register(shopifyWebhookRoutes, { prefix: '/webhooks' });",
    "app.ts: register shopify routes"
)

# ── 7. Patch tenantGuard.ts ──────────────────────────────────
print("[7/8] Patch tenantGuard.ts")
GUARD = f"{API_ROOT}/plugins/tenantGuard.ts"

patch_file(GUARD,
    "'/api/v1/tracking/webhook',",
    "'/api/v1/tracking/webhook',\n  '/shopify/callback',\n  '/webhooks/shopify',",
    "tenantGuard: add shopify exemptions"
)

# ── 8. Patch channelsService.ts ──────────────────────────────
print("[8/8] Patch channelsService.ts")
CHANNELS = f"{API_ROOT}/modules/channels/channelsService.ts"

# Find the last entry in MARKETPLACE_CATALOG and add Shopify after it
with open(CHANNELS, 'r', encoding='utf-8') as f:
    content = f.read()

# Add Shopify entry before the closing bracket of MARKETPLACE_CATALOG
SHOPIFY_ENTRY = """  {
    provider: 'shopify',
    country_code: null,
    marketplace_key: 'shopify_GLOBAL',
    display_name: 'Shopify',
    marketplace_id: null,
    supports_messaging: false,
    supports_orders: true,
    coming_soon: false,
  },"""

if 'shopify' not in content.lower():
    # Find the last entry (darty) and add after it
    target = "    coming_soon: true,\n  },\n];"
    if target in content:
        content = content.replace(target, f"    coming_soon: true,\n  }},\n{SHOPIFY_ENTRY}\n];")
        with open(CHANNELS, 'w', encoding='utf-8') as f:
            f.write(content)
        print("  OK: channelsService.ts: add Shopify catalog entry")
    else:
        print("  WARN: Could not find MARKETPLACE_CATALOG end marker")
else:
    print("  SKIP: Shopify already in channelsService.ts")

print("\n=== API MODULE COMPLETE ===")
