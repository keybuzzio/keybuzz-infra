#!/bin/bash
# PH-SHOPIFY-02: DB Migration — Create shopify_connections + shopify_webhook_events
set -e

POD=$(kubectl get pods -n keybuzz-api-dev -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}')

echo "=== PH-SHOPIFY-02: DB MIGRATION ==="

kubectl exec -n keybuzz-api-dev "$POD" -- node -e "
const { Pool } = require('pg');
const pool = new Pool();

(async () => {
  const client = await pool.connect();
  try {
    // shopify_connections
    await client.query(\`
      CREATE TABLE IF NOT EXISTS shopify_connections (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        tenant_id VARCHAR(255) NOT NULL,
        shop_domain VARCHAR(255) NOT NULL,
        access_token_enc TEXT NOT NULL,
        scopes TEXT,
        status VARCHAR(50) NOT NULL DEFAULT 'active',
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    \`);
    console.log('OK: shopify_connections created');

    // Indexes
    await client.query(\`CREATE INDEX IF NOT EXISTS idx_shopify_conn_tenant ON shopify_connections (tenant_id, status)\`);
    await client.query(\`CREATE INDEX IF NOT EXISTS idx_shopify_conn_shop ON shopify_connections (shop_domain)\`);
    console.log('OK: shopify_connections indexes');

    // shopify_webhook_events
    await client.query(\`
      CREATE TABLE IF NOT EXISTS shopify_webhook_events (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        tenant_id VARCHAR(255) NOT NULL,
        connection_id UUID,
        topic VARCHAR(255) NOT NULL,
        payload JSONB,
        processed BOOLEAN NOT NULL DEFAULT false,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    \`);
    console.log('OK: shopify_webhook_events created');

    await client.query(\`CREATE INDEX IF NOT EXISTS idx_shopify_wh_tenant ON shopify_webhook_events (tenant_id, processed)\`);
    await client.query(\`CREATE INDEX IF NOT EXISTS idx_shopify_wh_topic ON shopify_webhook_events (topic)\`);
    console.log('OK: shopify_webhook_events indexes');

    // Verify
    const tables = await client.query(\"SELECT tablename FROM pg_tables WHERE schemaname='public' AND tablename LIKE 'shopify_%'\");
    console.log('Tables created:', tables.rows.map(r => r.tablename).join(', '));
  } finally {
    client.release();
    await pool.end();
  }
})().catch(err => { console.error('MIGRATION ERROR:', err.message); process.exit(1); });
"

echo "=== MIGRATION COMPLETE ==="
