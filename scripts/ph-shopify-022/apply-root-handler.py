#!/usr/bin/env python3
"""
PH-SHOPIFY-02.2 — Add root handler for managed install redirect
When Shopify managed install completes, it redirects to application_url (/) with
hmac, host, shop, timestamp. We need to catch this and continue the OAuth flow.
"""

API_DIR = "/opt/keybuzz/keybuzz-api/src/modules/marketplaces/shopify"

def update_connect_route():
    """Store shop→tenant mapping in Redis during /shopify/connect"""
    print("[1/2] Updating /shopify/connect to store pending install mapping...")
    path = f"{API_DIR}/shopify.routes.ts"

    with open(path, 'r') as f:
        content = f.read()

    # Find the connect handler where it stores OAuth state
    old_store = "await storeOAuthState(state, tenantId as string, shop);"
    new_store = """await storeOAuthState(state, tenantId as string, shop);
      // Also store shop→state mapping for managed install redirect
      const redis = (await import('../../../config/redis')).getRedis();
      await redis.setex(`shopify:pending:${shop}`, 600, JSON.stringify({ state, tenantId }));"""

    if old_store in content:
        content = content.replace(old_store, new_store)
    else:
        print("   WARNING: storeOAuthState call not found, trying alternative approach...")
        return

    with open(path, 'w') as f:
        f.write(content)
    print("   OK: /shopify/connect now stores pending install mapping")


def add_root_handler():
    """Add GET / handler that catches managed install redirect"""
    print("[2/2] Adding root handler for managed install redirect...")
    path = f"{API_DIR}/shopify.routes.ts"

    with open(path, 'r') as f:
        content = f.read()

    # Find the shopifyRoutes function opening to add the root handler
    # We need to add it after the function declaration
    # Look for the first route definition pattern
    marker = "app.post('/connect',"
    if marker not in content:
        print("   ERROR: Could not find /connect route to insert before")
        return

    root_handler = """// ─── Managed install redirect handler ────────────────────────
  app.get('/', async (request, reply) => {
    const query = request.query as Record<string, string>;
    if (!query.shop || !query.hmac) {
      return reply.status(200).send({ status: 'ok', service: 'shopify-module' });
    }

    const shop = normalizeShop(query.shop);
    console.log(`[Shopify] Managed install redirect for shop=${shop}`);

    const redis = (await import('../../../config/redis')).getRedis();
    const pendingRaw = await redis.get(`shopify:pending:${shop}`);

    if (!pendingRaw) {
      console.warn(`[Shopify] No pending install found for shop=${shop}`);
      const clientRedirect = process.env.SHOPIFY_CLIENT_REDIRECT_URL || 'https://client-dev.keybuzz.io/channels';
      return reply.redirect(`${clientRedirect}?shopify_error=no_pending_install`);
    }

    const pending = JSON.parse(pendingRaw);
    console.log(`[Shopify] Continuing OAuth for tenant=${pending.tenantId} shop=${shop}`);

    const clientId = process.env.SHOPIFY_CLIENT_ID;
    const redirectUri = process.env.SHOPIFY_REDIRECT_URI;
    const scopes = 'read_orders,read_customers,read_fulfillments,read_returns';
    const authUrl = `https://${shop}/admin/oauth/authorize?client_id=${clientId}&scope=${scopes}&redirect_uri=${encodeURIComponent(redirectUri!)}&state=${pending.state}`;
    return reply.redirect(authUrl);
  });

  """

    content = content.replace(marker, root_handler + marker)

    with open(path, 'w') as f:
        f.write(content)
    print("   OK: Root handler added for managed install redirect")


if __name__ == '__main__':
    update_connect_route()
    add_root_handler()
    print("\n=== Managed install root handler applied ===")
