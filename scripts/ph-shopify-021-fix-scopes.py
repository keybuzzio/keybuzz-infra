#!/usr/bin/env python3
"""Fix Shopify OAuth scopes"""
path = '/opt/keybuzz/keybuzz-api/src/modules/marketplaces/shopify/shopifyAuth.service.ts'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()
old = "const SCOPES = 'read_orders,read_products,read_customers';"
new = "const SCOPES = 'read_orders,read_customers,read_fulfillments,read_returns';"
if old in c:
    c = c.replace(old, new, 1)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(c)
    print('OK: Scopes updated to', new)
else:
    print('WARN: Old scopes not found, checking current:')
    import re
    m = re.search(r"const SCOPES = '([^']+)';", c)
    if m:
        print('  Current:', m.group(1))
    else:
        print('  SCOPES not found in file')
