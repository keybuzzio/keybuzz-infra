#!/usr/bin/env python3
"""Fix build errors for PH-SHOPIFY-02.1"""

# Fix 1: ai-supervision/page.tsx - unescaped apostrophe
path1 = '/opt/keybuzz/keybuzz-client/app/settings/ai-supervision/page.tsx'
with open(path1, 'r', encoding='utf-8') as f:
    c = f.read()
old1 = "Suivi des suggestions IA proposées aux agents et de leur taux d'acceptation."
new1 = "Suivi des suggestions IA propos\u00e9es aux agents et de leur taux d&apos;acceptation."
if old1 in c:
    c = c.replace(old1, new1, 1)
    with open(path1, 'w', encoding='utf-8') as f:
        f.write(c)
    print('OK: Fixed unescaped apostrophe in ai-supervision')
else:
    print('SKIP: ai-supervision already fixed or text not found')

# Fix 2: channels page - replace <img> with <Image> in Shopify modal
path2 = '/opt/keybuzz/keybuzz-client/app/channels/page.tsx'
with open(path2, 'r', encoding='utf-8') as f:
    c2 = f.read()
old2 = '<img src="/marketplaces/shopify.svg" alt="Shopify" className="w-8 h-8" />'
new2 = '<Image src="/marketplaces/shopify.svg" alt="Shopify" width={32} height={32} />'
if old2 in c2:
    c2 = c2.replace(old2, new2)
    with open(path2, 'w', encoding='utf-8') as f:
        f.write(c2)
    print('OK: Fixed <img> to <Image> in Shopify modal')
else:
    print('SKIP: <img> already fixed or not found')
