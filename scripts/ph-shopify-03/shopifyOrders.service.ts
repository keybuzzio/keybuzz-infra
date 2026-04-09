import crypto from 'crypto';
import { getPool } from '../../../config/database';
import { decryptToken } from './shopifyCrypto.service';

const SHOPIFY_API_VERSION = '2024-10';

const ORDERS_GRAPHQL = `
query($first: Int!) {
  orders(first: $first, sortKey: CREATED_AT, reverse: true) {
    edges {
      node {
        id
        name
        createdAt
        displayFinancialStatus
        displayFulfillmentStatus
        totalPriceSet {
          shopMoney { amount currencyCode }
        }
        customer {
          displayName
          email
        }
        shippingAddress {
          address1 city zip country
        }
        lineItems(first: 50) {
          edges {
            node {
              title
              sku
              quantity
              originalUnitPriceSet { shopMoney { amount } }
            }
          }
        }
        fulfillments {
          trackingInfo { number url company }
          createdAt
          status
        }
      }
    }
  }
}`;

interface MappedOrder {
  externalOrderId: string;
  channel: 'shopify';
  status: string;
  totalAmount: number;
  currency: string;
  orderDate: string;
  fulfillmentChannel: string;
  customerName: string;
  customerEmail: string | null;
  customerAddress: string | null;
  carrier: string | null;
  trackingCode: string | null;
  trackingUrl: string | null;
  deliveryStatus: string;
  products: string;
  rawData: string;
  shippedAt: string | null;
  deliveredAt: string | null;
}

export interface SyncResult {
  total: number;
  inserted: number;
  updated: number;
  errors: number;
  details: string[];
}

// ─── Connection helper ──────────────────────────────────────

export async function getActiveConnection(tenantId: string) {
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
}

// ─── GraphQL fetch ──────────────────────────────────────────

export async function fetchOrdersGraphQL(shopDomain: string, accessToken: string, limit: number = 50): Promise<any[]> {
  const resp = await fetch(`https://${shopDomain}/admin/api/${SHOPIFY_API_VERSION}/graphql.json`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Shopify-Access-Token': accessToken,
    },
    body: JSON.stringify({ query: ORDERS_GRAPHQL, variables: { first: Math.min(limit, 50) } }),
  });

  if (!resp.ok) {
    const errText = await resp.text();
    throw new Error(`Shopify GraphQL ${resp.status}: ${errText.substring(0, 200)}`);
  }

  const data = await resp.json() as any;
  if (data.errors?.length) {
    throw new Error(`Shopify GraphQL errors: ${JSON.stringify(data.errors[0])}`);
  }

  return (data.data?.orders?.edges || []).map((e: any) => e.node);
}

// ─── Mapping: GraphQL format ────────────────────────────────

function mapFinancialStatus(s: string): string {
  const v = (s || '').toUpperCase();
  if (v === 'REFUNDED' || v === 'VOIDED') return 'Cancelled';
  return '';
}

function mapFulfillmentStatus(s: string, financialOverride: string): string {
  if (financialOverride) return financialOverride;
  const v = (s || '').toUpperCase();
  if (v === 'FULFILLED') return 'Shipped';
  if (v === 'PARTIALLY_FULFILLED') return 'PartiallyShipped';
  if (v === 'UNFULFILLED' || v === '' || v === 'NULL') return 'Unshipped';
  return 'Unshipped';
}

function mapDeliveryStatus(fulfillments: any[]): string {
  if (!fulfillments?.length) return 'preparing';
  const f = fulfillments[0];
  const st = (f.status || '').toUpperCase();
  if (st === 'DELIVERED') return 'delivered';
  if (st === 'IN_TRANSIT') return 'in_transit';
  if (st === 'SUCCESS') return 'shipped';
  return 'preparing';
}

export function mapGraphQLOrder(order: any): MappedOrder {
  const totalAmount = parseFloat(order.totalPriceSet?.shopMoney?.amount || '0');
  const currency = order.totalPriceSet?.shopMoney?.currencyCode || 'EUR';

  const products = (order.lineItems?.edges || []).map((e: any) => ({
    name: e.node.title || 'Article',
    sku: e.node.sku || '',
    quantity: e.node.quantity || 1,
    price: parseFloat(e.node.originalUnitPriceSet?.shopMoney?.amount || '0'),
  }));

  const fulfillment = (order.fulfillments || [])[0];
  const trackingInfo = fulfillment?.trackingInfo?.[0];

  const addr = order.shippingAddress;
  const customerAddress = addr
    ? [addr.address1, addr.city, addr.zip, addr.country].filter(Boolean).join(', ')
    : null;

  const financialOverride = mapFinancialStatus(order.displayFinancialStatus);
  const status = mapFulfillmentStatus(order.displayFulfillmentStatus, financialOverride);
  const deliveryStatus = mapDeliveryStatus(order.fulfillments);

  return {
    externalOrderId: order.name || order.id,
    channel: 'shopify',
    status,
    totalAmount,
    currency,
    orderDate: order.createdAt || new Date().toISOString(),
    fulfillmentChannel: 'MFN',
    customerName: order.customer?.displayName || 'Client Shopify',
    customerEmail: order.customer?.email || null,
    customerAddress,
    carrier: trackingInfo?.company || null,
    trackingCode: trackingInfo?.number || null,
    trackingUrl: trackingInfo?.url || null,
    deliveryStatus,
    products: JSON.stringify(products),
    rawData: JSON.stringify(order),
    shippedAt: fulfillment?.createdAt || null,
    deliveredAt: null,
  };
}

// ─── Mapping: REST webhook format ───────────────────────────

export function mapWebhookOrder(payload: any): MappedOrder {
  const totalAmount = parseFloat(payload.total_price || '0');
  const currency = payload.currency || 'EUR';

  const products = (payload.line_items || []).map((item: any) => ({
    name: item.title || 'Article',
    sku: item.sku || '',
    quantity: item.quantity || 1,
    price: parseFloat(item.price || '0'),
  }));

  const fulfillment = (payload.fulfillments || [])[0];

  const addr = payload.shipping_address;
  const customerAddress = addr
    ? [addr.address1, addr.city, addr.zip, addr.country].filter(Boolean).join(', ')
    : null;

  const customerName = payload.customer
    ? [payload.customer.first_name, payload.customer.last_name].filter(Boolean).join(' ') || 'Client Shopify'
    : 'Client Shopify';

  const fin = (payload.financial_status || '').toLowerCase();
  const ful = (payload.fulfillment_status || '').toLowerCase();
  let status: string;
  if (fin === 'refunded' || fin === 'voided') status = 'Cancelled';
  else if (ful === 'fulfilled') status = 'Shipped';
  else if (ful === 'partial') status = 'PartiallyShipped';
  else status = 'Unshipped';

  let deliveryStatus: string;
  if (fulfillment?.status === 'success' || ful === 'fulfilled') deliveryStatus = 'shipped';
  else deliveryStatus = 'preparing';

  return {
    externalOrderId: payload.name || `#${payload.order_number || payload.id}`,
    channel: 'shopify',
    status,
    totalAmount,
    currency,
    orderDate: payload.created_at || new Date().toISOString(),
    fulfillmentChannel: 'MFN',
    customerName,
    customerEmail: payload.customer?.email || payload.email || null,
    customerAddress,
    carrier: fulfillment?.tracking_company || null,
    trackingCode: fulfillment?.tracking_number || null,
    trackingUrl: fulfillment?.tracking_url || null,
    deliveryStatus,
    products: JSON.stringify(products),
    rawData: JSON.stringify(payload),
    shippedAt: fulfillment?.created_at || null,
    deliveredAt: null,
  };
}

// ─── Idempotent upsert ─────────────────────────────────────

function generateOrderId(): string {
  return `ord-${Date.now().toString(36)}-${Math.random().toString(36).substr(2, 6)}`;
}

export async function upsertOrder(tenantId: string, mapped: MappedOrder): Promise<'inserted' | 'updated'> {
  const pool = await getPool();

  const existing = await pool.query(
    `SELECT id FROM orders WHERE tenant_id = $1 AND external_order_id = $2 AND channel = 'shopify' LIMIT 1`,
    [tenantId, mapped.externalOrderId]
  );

  if (existing.rows.length > 0) {
    await pool.query(
      `UPDATE orders SET
        status = $1, total_amount = $2, currency = $3, customer_name = $4, customer_email = $5,
        customer_address = $6, carrier = $7, tracking_code = $8, tracking_url = $9,
        delivery_status = $10, products = $11, raw_data = $12, shipped_at = $13, delivered_at = $14,
        updated_at = NOW()
       WHERE tenant_id = $15 AND external_order_id = $16 AND channel = 'shopify'`,
      [
        mapped.status, mapped.totalAmount, mapped.currency, mapped.customerName, mapped.customerEmail,
        mapped.customerAddress, mapped.carrier, mapped.trackingCode, mapped.trackingUrl,
        mapped.deliveryStatus, mapped.products, mapped.rawData, mapped.shippedAt, mapped.deliveredAt,
        tenantId, mapped.externalOrderId,
      ]
    );
    return 'updated';
  }

  const orderId = generateOrderId();
  await pool.query(
    `INSERT INTO orders (id, tenant_id, external_order_id, channel, status, total_amount, currency, order_date,
      fulfillment_channel, customer_name, customer_email, customer_address, carrier, tracking_code, tracking_url,
      delivery_status, products, raw_data, shipped_at, delivered_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20)`,
    [
      orderId, tenantId, mapped.externalOrderId, mapped.channel, mapped.status, mapped.totalAmount,
      mapped.currency, mapped.orderDate, mapped.fulfillmentChannel, mapped.customerName, mapped.customerEmail,
      mapped.customerAddress, mapped.carrier, mapped.trackingCode, mapped.trackingUrl,
      mapped.deliveryStatus, mapped.products, mapped.rawData, mapped.shippedAt, mapped.deliveredAt,
    ]
  );
  return 'inserted';
}

// ─── Sync orchestrator ──────────────────────────────────────

export async function syncOrders(tenantId: string, limit: number = 50): Promise<SyncResult> {
  const conn = await getActiveConnection(tenantId);
  if (!conn) throw new Error('No active Shopify connection');

  const result: SyncResult = { total: 0, inserted: 0, updated: 0, errors: 0, details: [] };

  console.log(`[Shopify Orders] Starting sync tenant=${tenantId} shop=${conn.shopDomain} limit=${limit}`);
  const orders = await fetchOrdersGraphQL(conn.shopDomain, conn.accessToken, limit);
  result.total = orders.length;

  for (const order of orders) {
    try {
      const mapped = mapGraphQLOrder(order);
      const action = await upsertOrder(tenantId, mapped);
      if (action === 'inserted') result.inserted++;
      else result.updated++;
    } catch (err: any) {
      result.errors++;
      result.details.push(`${order.name || order.id}: ${err.message}`);
      console.error(`[Shopify Orders] Error: ${order.name}: ${err.message}`);
    }
  }

  console.log(`[Shopify Orders] Done tenant=${tenantId}: ${result.total} total, ${result.inserted} inserted, ${result.updated} updated, ${result.errors} errors`);
  return result;
}

// ─── Webhook registration ───────────────────────────────────

const WEBHOOK_TOPICS = ['orders/create', 'orders/updated'];

export async function registerWebhooks(shopDomain: string, accessToken: string): Promise<{ registered: string[]; errors: string[] }> {
  const webhookUrl = process.env.SHOPIFY_WEBHOOK_URL || 'https://api-dev.keybuzz.io/webhooks/shopify';
  const registered: string[] = [];
  const errors: string[] = [];

  for (const topic of WEBHOOK_TOPICS) {
    try {
      const resp = await fetch(`https://${shopDomain}/admin/api/${SHOPIFY_API_VERSION}/webhooks.json`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Access-Token': accessToken,
        },
        body: JSON.stringify({
          webhook: { topic, address: webhookUrl, format: 'json' },
        }),
      });
      if (resp.ok || resp.status === 201) {
        registered.push(topic);
        console.log(`[Shopify Webhooks] Registered ${topic} -> ${webhookUrl}`);
      } else {
        const body = await resp.text();
        if (body.includes('for this topic has already been taken')) {
          registered.push(topic);
          console.log(`[Shopify Webhooks] ${topic} already registered`);
        } else {
          errors.push(`${topic}: ${resp.status} ${body.substring(0, 100)}`);
          console.warn(`[Shopify Webhooks] Failed ${topic}: ${resp.status}`);
        }
      }
    } catch (err: any) {
      errors.push(`${topic}: ${err.message}`);
    }
  }

  return { registered, errors };
}
