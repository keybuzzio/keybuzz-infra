#!/bin/bash
# PH-SHOPIFY-PROD — Create Shopify tables in PROD database
#
# USAGE (on bastion):
#   bash migrate-prod-db.sh
#
# Creates shopify_connections and shopify_webhook_events tables in keybuzz_prod.
# Safe to run multiple times (IF NOT EXISTS).

set -euo pipefail

POD=$(kubectl get pods -n keybuzz-api-prod -l app=keybuzz-api -o jsonpath='{.items[0].metadata.name}')

echo "=== Creating Shopify tables in PROD DB ==="

kubectl exec -n keybuzz-api-prod "$POD" -- node -e "
const {Pool} = require('pg');
const p = new Pool();
(async () => {
  await p.query(\`
    CREATE TABLE IF NOT EXISTS shopify_connections (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      tenant_id VARCHAR(255) NOT NULL,
      shop_domain VARCHAR(255) NOT NULL,
      access_token_enc TEXT NOT NULL,
      scopes VARCHAR(1024) DEFAULT '',
      status VARCHAR(50) DEFAULT 'active',
      token_expires_at TIMESTAMPTZ,
      refresh_token_enc TEXT,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    )
  \`);
  console.log('shopify_connections: OK');

  await p.query(\`
    CREATE TABLE IF NOT EXISTS shopify_webhook_events (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      tenant_id VARCHAR(255),
      connection_id UUID,
      topic VARCHAR(255) NOT NULL,
      payload JSONB,
      processed BOOLEAN DEFAULT false,
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  \`);
  console.log('shopify_webhook_events: OK');

  await p.query(\`
    CREATE INDEX IF NOT EXISTS idx_shopify_conn_tenant
    ON shopify_connections(tenant_id, status)
  \`);
  console.log('index shopify_conn_tenant: OK');

  await p.query(\`
    CREATE INDEX IF NOT EXISTS idx_shopify_webhook_topic
    ON shopify_webhook_events(topic, created_at)
  \`);
  console.log('index shopify_webhook_topic: OK');

  // Verify
  const t1 = await p.query(\"SELECT COUNT(*) FROM shopify_connections\");
  const t2 = await p.query(\"SELECT COUNT(*) FROM shopify_webhook_events\");
  console.log('Verification: shopify_connections=' + t1.rows[0].count + ', shopify_webhook_events=' + t2.rows[0].count);

  await p.end();
})().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
"

echo ""
echo "=== Migration complete ==="
