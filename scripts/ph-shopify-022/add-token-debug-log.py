#!/usr/bin/env python3
"""Add debug logging to exchangeToken to see the full response from Shopify."""

path = "/opt/keybuzz/keybuzz-api/src/modules/marketplaces/shopify/shopifyAuth.service.ts"

with open(path, 'r') as f:
    content = f.read()

old = """  const data = await resp.json() as TokenExchangeResult;
  if (data.expires_in) {
    console.log(`[Shopify Auth] Token expires in ${data.expires_in}s (${Math.round(data.expires_in / 3600)}h)`);
  }
  return data;"""

new = """  const data = await resp.json() as TokenExchangeResult;
  const safeKeys = Object.keys(data).filter(k => k !== 'access_token');
  console.log(`[Shopify Auth] Token exchange response keys: ${JSON.stringify(safeKeys)}, scope=${(data as any).scope}, expires_in=${data.expires_in || 'NONE'}`);
  if (data.expires_in) {
    console.log(`[Shopify Auth] Token expires in ${data.expires_in}s (${Math.round(data.expires_in / 3600)}h)`);
  } else {
    console.warn(`[Shopify Auth] WARNING: Token has NO expires_in — non-expiring token received`);
  }
  return data;"""

if old in content:
    content = content.replace(old, new)
    with open(path, 'w') as f:
        f.write(content)
    print("OK: Added debug logging to exchangeToken")
else:
    print("ERROR: Could not find target")
    import sys; sys.exit(1)
