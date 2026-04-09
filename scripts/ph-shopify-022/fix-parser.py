#!/usr/bin/env python3
"""Fix the Fastify content type parser conflict in shopifyWebhook.routes.ts."""

WEBHOOK_PATH = '/opt/keybuzz/keybuzz-api/src/modules/marketplaces/shopify/shopifyWebhook.routes.ts'

new_webhook = r'''import { FastifyInstance } from 'fastify';
import crypto from 'crypto';
import { getPool } from '../../../config/database';
import { mapWebhookOrder, upsertOrder } from './shopifyOrders.service';

export async function shopifyWebhookRoutes(app: FastifyInstance) {

  // Capture raw body for HMAC verification via preParsing hook
  app.addHook('preParsing', async (request, _reply, payload) => {
    const chunks: Buffer[] = [];
    for await (const chunk of payload) {
      chunks.push(typeof chunk === 'string' ? Buffer.from(chunk) : chunk);
    }
    const raw = Buffer.concat(chunks);
    (request as any).rawBody = raw;
    const { Readable } = require('stream');
    return Readable.from(raw);
  });

  app.post('/shopify', async (request, reply) => {
    const hmac = request.headers['x-shopify-hmac-sha256'] as string;
    const topic = request.headers['x-shopify-topic'] as string;
    const shopDomain = request.headers['x-shopify-shop-domain'] as string;
    const secret = process.env.SHOPIFY_CLIENT_SECRET;

    if (!hmac || !secret) {
      return reply.status(401).send({ error: 'Unauthorized' });
    }

    // HMAC verification using raw body (Shopify compliance requirement)
    const rawBody = (request as any).rawBody as Buffer;
    const computed = crypto.createHmac('sha256', secret).update(rawBody).digest('base64');
    const valid = (() => {
      try { return crypto.timingSafeEqual(Buffer.from(hmac, 'base64'), Buffer.from(computed, 'base64')); }
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

    await pool.query(
      `INSERT INTO shopify_webhook_events (id, tenant_id, connection_id, topic, payload, processed, created_at)
       VALUES ($1, $2, $3, $4, $5, false, NOW())`,
      [crypto.randomUUID(), tenantId, connectionId, topic || 'unknown', JSON.stringify(request.body)]
    );

    if (topic === 'customers/data_request') {
      console.log(`[Shopify Webhook] customers/data_request from ${shopDomain} (tenant=${tenantId}) — acknowledged`);
      return reply.status(200).send({ ok: true });
    }

    if (topic === 'customers/redact') {
      console.log(`[Shopify Webhook] customers/redact from ${shopDomain} (tenant=${tenantId}) — acknowledged`);
      return reply.status(200).send({ ok: true });
    }

    if (topic === 'shop/redact') {
      console.log(`[Shopify Webhook] shop/redact from ${shopDomain} — acknowledged`);
      return reply.status(200).send({ ok: true });
    }

    if (topic === 'app/uninstalled') {
      console.log(`[Shopify Webhook] app/uninstalled from ${shopDomain} (tenant=${tenantId})`);
      if (tenantId !== 'unknown') {
        try {
          await pool.query(
            `UPDATE shopify_connections SET status = 'disconnected', updated_at = NOW() WHERE tenant_id = $1 AND status = 'active'`,
            [tenantId]
          );
          await pool.query(
            `UPDATE tenant_channels SET status = 'removed', updated_at = NOW() WHERE tenant_id = $1 AND marketplace_key = 'shopify-global' AND status != 'removed'`,
            [tenantId]
          );
          console.log(`[Shopify Webhook] Disconnected tenant ${tenantId} after uninstall`);
        } catch (e: any) {
          console.error(`[Shopify Webhook] Uninstall cleanup error: ${e.message}`);
        }
      }
      return reply.status(200).send({ ok: true });
    }

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
      return reply.status(200).send({ ok: true });
    }

    console.log(`[Shopify Webhook] ${topic} from ${shopDomain} (tenant=${tenantId}) — logged`);
    return reply.status(200).send({ ok: true });
  });
}
'''

with open(WEBHOOK_PATH, 'w') as f:
    f.write(new_webhook)
print("Fixed: replaced addContentTypeParser with preParsing hook")
