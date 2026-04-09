#!/usr/bin/env python3
"""PH-SHOPIFY-03 — Apply all code changes for Shopify orders sync."""
import os

SHOPIFY_DIR = '/opt/keybuzz/keybuzz-api/src/modules/marketplaces/shopify'

# ─── 1. Copy new shopifyOrders.service.ts ────────────────────
print("[1/4] shopifyOrders.service.ts — installing...")
os.system(f'cp /tmp/ph-shopify-03/shopifyOrders.service.ts {SHOPIFY_DIR}/shopifyOrders.service.ts')
print("      OK")

# ─── 2. Patch shopify.routes.ts — add sync routes + initial sync in callback ──
print("[2/4] shopify.routes.ts — patching...")

routes_path = f'{SHOPIFY_DIR}/shopify.routes.ts'
with open(routes_path, 'r') as f:
    content = f.read()

# Backup
with open(routes_path + '.bak-pre-shopify-03', 'w') as f:
    f.write(content)

# Add import for shopifyOrders at top
if 'shopifyOrders.service' not in content:
    old_import = "import { normalizeShop, buildAuthUrl, storeOAuthState, popOAuthState, verifyHmac, exchangeToken, saveConnection, getStatus, disconnect } from './shopifyAuth.service';"
    new_import = old_import + "\nimport { syncOrders, registerWebhooks, getActiveConnection } from './shopifyOrders.service';"
    content = content.replace(old_import, new_import)

# Add initial sync + webhook registration after channel activation in callback
old_callback_log = "console.log(`[Shopify] Connected tenant=${oauthState.tenantId} shop=${shop}`);"
new_callback_log = """console.log(`[Shopify] Connected tenant=${oauthState.tenantId} shop=${shop}`);
      // PH-SHOPIFY-03: register webhooks + initial order sync (async, non-blocking)
      (async () => {
        try {
          const conn = await getActiveConnection(oauthState.tenantId);
          if (conn) {
            await registerWebhooks(conn.shopDomain, conn.accessToken);
            const sr = await syncOrders(oauthState.tenantId, 50);
            console.log(`[Shopify] Initial sync: ${sr.inserted} inserted, ${sr.updated} updated, ${sr.errors} errors`);
          }
        } catch (e: any) {
          console.warn('[Shopify] Post-connect tasks warning:', e.message);
        }
      })();"""

if old_callback_log in content:
    content = content.replace(old_callback_log, new_callback_log)

# Add sync routes before the closing brace of shopifyRoutes function
# Find the last closing brace of the disconnect route
sync_routes = """
  // ─── PH-SHOPIFY-03: Order sync routes ──────────────────────

  app.post('/orders/sync', async (request, reply) => {
    const body = request.body as any || {};
    const tenantId = body.tenantId || request.headers['x-tenant-id'];
    if (!tenantId) return reply.status(400).send({ error: 'tenantId required' });
    try {
      const result = await syncOrders(tenantId as string, body.limit || 50);
      return reply.send(result);
    } catch (err: any) {
      console.error('[Shopify Orders] Sync error:', err.message);
      return reply.status(500).send({ error: err.message });
    }
  });

  app.get('/orders/list', async (request, reply) => {
    const tenantId = (request.query as any).tenantId || request.headers['x-tenant-id'];
    if (!tenantId) return reply.status(400).send({ error: 'tenantId required' });
    const pool = await (await import('../../../config/database')).getPool();
    const limit = parseInt((request.query as any).limit || '50');
    const offset = parseInt((request.query as any).offset || '0');
    try {
      const r = await pool.query(
        `SELECT * FROM orders WHERE tenant_id = $1 AND channel = 'shopify' ORDER BY order_date DESC NULLS LAST LIMIT $2 OFFSET $3`,
        [tenantId, limit, offset]
      );
      const count = await pool.query(
        `SELECT COUNT(*) FROM orders WHERE tenant_id = $1 AND channel = 'shopify'`,
        [tenantId]
      );
      return reply.send({ orders: r.rows, total: parseInt(count.rows[0].count) });
    } catch (err: any) {
      return reply.status(500).send({ error: err.message });
    }
  });
"""

# Insert sync routes before the final closing brace of the function
# The function ends with a final `}\n` - we insert before that
last_close = content.rstrip()
if last_close.endswith('}') and 'orders/sync' not in content:
    # Find the position of the last `}` which closes the shopifyRoutes function
    idx = content.rfind('}')
    content = content[:idx] + sync_routes + '\n}\n'

with open(routes_path, 'w') as f:
    f.write(content)
print("      OK")

# ─── 3. Patch shopifyWebhook.routes.ts — handle order topics ──
print("[3/4] shopifyWebhook.routes.ts — patching...")

webhook_path = f'{SHOPIFY_DIR}/shopifyWebhook.routes.ts'
with open(webhook_path, 'r') as f:
    wh_content = f.read()

# Backup
with open(webhook_path + '.bak-pre-shopify-03', 'w') as f:
    f.write(wh_content)

# Replace the entire webhook routes file with enhanced version
new_webhook = '''import { FastifyInstance } from 'fastify';
import crypto from 'crypto';
import { getPool } from '../../../config/database';
import { mapWebhookOrder, upsertOrder } from './shopifyOrders.service';

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

    const pool = await getPool();
    const conn = await pool.query(
      `SELECT id, tenant_id FROM shopify_connections WHERE shop_domain = $1 AND status = 'active' LIMIT 1`,
      [shopDomain]
    );
    const tenantId = conn.rows[0]?.tenant_id || 'unknown';
    const connectionId = conn.rows[0]?.id || null;

    // Log event
    await pool.query(
      `INSERT INTO shopify_webhook_events (id, tenant_id, connection_id, topic, payload, processed, created_at)
       VALUES ($1, $2, $3, $4, $5, false, NOW())`,
      [crypto.randomUUID(), tenantId, connectionId, topic || 'unknown', JSON.stringify(request.body)]
    );

    // PH-SHOPIFY-03: Process order webhooks
    if (tenantId !== 'unknown' && (topic === 'orders/create' || topic === 'orders/updated')) {
      try {
        const mapped = mapWebhookOrder(request.body as any);
        const action = await upsertOrder(tenantId, mapped);
        console.log(`[Shopify Webhook] ${topic} ${mapped.externalOrderId} -> ${action} (tenant=${tenantId})`);
        await pool.query(
          `UPDATE shopify_webhook_events SET processed = true WHERE tenant_id = $1 AND topic = $2 AND created_at = (SELECT MAX(created_at) FROM shopify_webhook_events WHERE tenant_id = $1 AND topic = $2)`,
          [tenantId, topic]
        );
      } catch (err: any) {
        console.error(`[Shopify Webhook] Order processing error: ${err.message}`);
      }
    } else {
      console.log(`[Shopify Webhook] ${topic} from ${shopDomain} (tenant=${tenantId}) — logged`);
    }

    return reply.status(200).send({ ok: true });
  });
}
'''

with open(webhook_path, 'w') as f:
    f.write(new_webhook)
print("      OK")

# ─── 4. Update index.ts — export shopifyOrders if needed ──
print("[4/4] index.ts — checking exports...")

index_path = f'{SHOPIFY_DIR}/index.ts'
with open(index_path, 'r') as f:
    idx_content = f.read()

# No need to export shopifyOrders from index — it's imported internally by routes
# But let's verify existing exports are fine
print(f"      Current: {idx_content.strip()}")
print("      OK (no changes needed)")

print("\n=== ALL PATCHES APPLIED ===")
