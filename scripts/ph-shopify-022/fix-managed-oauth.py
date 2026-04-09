#!/usr/bin/env python3
"""
Fix: Remove scope param from OAuth redirect in managed install handler.
Shopify managed install uses TOML scopes — including scope= in the URL
forces legacy mode which returns non-expiring tokens.
"""

path = "/opt/keybuzz/keybuzz-api/src/modules/marketplaces/shopify/shopify.routes.ts"

with open(path, 'r') as f:
    content = f.read()

# Fix the managed install root handler — remove scope param
old = """    const clientId = process.env.SHOPIFY_CLIENT_ID;
    const redirectUri = process.env.SHOPIFY_REDIRECT_URI;
    const scopes = 'read_orders,read_customers,read_fulfillments,read_returns';
    const authUrl = `https://${shop}/admin/oauth/authorize?client_id=${clientId}&scope=${scopes}&redirect_uri=${encodeURIComponent(redirectUri!)}&state=${pending.state}`;
    return reply.redirect(authUrl);"""

new = """    const clientId = process.env.SHOPIFY_CLIENT_ID;
    const redirectUri = process.env.SHOPIFY_REDIRECT_URI;
    // Managed install: do NOT include scope — scopes come from TOML
    // Including scope forces legacy mode with non-expiring tokens
    const authUrl = `https://${shop}/admin/oauth/authorize?client_id=${clientId}&redirect_uri=${encodeURIComponent(redirectUri!)}&state=${pending.state}`;
    console.log(`[Shopify] Redirecting to OAuth (managed, no scope param)`);
    return reply.redirect(authUrl);"""

if old in content:
    content = content.replace(old, new)
    with open(path, 'w') as f:
        f.write(content)
    print("OK: Removed scope param from managed install OAuth redirect")
else:
    print("ERROR: Could not find the target code block")
    import sys; sys.exit(1)
