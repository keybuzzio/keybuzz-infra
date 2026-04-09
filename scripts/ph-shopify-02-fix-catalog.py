#!/usr/bin/env python3
"""Fix: add Shopify to MARKETPLACE_CATALOG"""
f = "/opt/keybuzz/keybuzz-api/src/modules/channels/channelsService.ts"
with open(f, 'r', encoding='utf-8') as fh:
    content = fh.read()

if 'shopify' in content.lower():
    print("SKIP: Shopify already in catalog")
else:
    old = '  { provider: "darty", country_code: "FR", marketplace_key: "darty-fr", display_name: "Darty France", marketplace_id: null, supports_messaging: false, supports_orders: false, coming_soon: true },'
    new = old + '\n  { provider: "shopify", country_code: null, marketplace_key: "shopify-global", display_name: "Shopify", marketplace_id: null, supports_messaging: false, supports_orders: true, coming_soon: false },'
    if old in content:
        content = content.replace(old, new)
        with open(f, 'w', encoding='utf-8') as fh:
            fh.write(content)
        print("OK: Shopify added to MARKETPLACE_CATALOG")
    else:
        print("WARN: Darty entry not found")
