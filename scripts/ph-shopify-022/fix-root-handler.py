#!/usr/bin/env python3
"""
Move the Shopify managed install handler from /shopify/ prefix to the API root.
Shopify always redirects to the root / regardless of application_url for non-embedded apps.
"""

APP_TS = "/opt/keybuzz/keybuzz-api/src/app.ts"
ROUTES_TS = "/opt/keybuzz/keybuzz-api/src/modules/marketplaces/shopify/shopify.routes.ts"

def remove_from_routes():
    """Remove the root handler from shopify.routes.ts"""
    print("[1/2] Removing root handler from shopify.routes.ts...")
    with open(ROUTES_TS, 'r') as f:
        content = f.read()

    # Remove the managed install handler block
    start_marker = "// ─── Managed install redirect handler ────────────────────────"
    end_marker = "app.post('/connect',"

    if start_marker in content:
        idx_start = content.index(start_marker)
        idx_end = content.index(end_marker)
        content = content[:idx_start] + content[idx_end:]
        with open(ROUTES_TS, 'w') as f:
            f.write(content)
        print("   OK: Root handler removed from shopify.routes.ts")
    else:
        print("   SKIP: Root handler not found in shopify.routes.ts")

def add_to_app_ts():
    """Add the root handler directly in app.ts (before all route registrations)"""
    print("[2/2] Adding Shopify managed install handler to app.ts root...")
    with open(APP_TS, 'r') as f:
        content = f.read()

    if 'shopify:pending' in content:
        print("   SKIP: Handler already present in app.ts")
        return

    # Find the line where shopifyRoutes is registered
    marker = "app.register(shopifyRoutes, { prefix: '/shopify' });"
    if marker not in content:
        print("   ERROR: Could not find shopifyRoutes registration in app.ts")
        import sys; sys.exit(1)

    handler = """
  // ─── Shopify managed install redirect handler (root level) ─────
  // Shopify redirects to / after managed install regardless of application_url
  app.get('/', async (request, reply) => {
    const query = request.query as Record<string, string>;
    if (!query.shop || !query.hmac) {
      return reply.status(404).send({ error: 'Not found' });
    }
    const shopRaw = query.shop.trim().toLowerCase().replace(/^https?:\\/\\//, '').replace(/\\/$/, '');
    const shop = shopRaw.includes('.') ? shopRaw : `${shopRaw}.myshopify.com`;
    console.log(`[Shopify] Managed install redirect for shop=${shop}`);

    const { getRedis } = await import('./config/redis');
    const redis = getRedis();
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
    const authUrl = `https://${shop}/admin/oauth/authorize?client_id=${clientId}&redirect_uri=${encodeURIComponent(redirectUri!)}&state=${pending.state}`;
    console.log(`[Shopify] Redirecting to OAuth (managed, no scope param)`);
    return reply.redirect(authUrl);
  });

  """

    content = content.replace(marker, handler + marker)

    with open(APP_TS, 'w') as f:
        f.write(content)
    print("   OK: Root handler added to app.ts")


if __name__ == '__main__':
    remove_from_routes()
    add_to_app_ts()
    print("\n=== Root handler moved to app.ts ===")
