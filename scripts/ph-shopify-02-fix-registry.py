#!/usr/bin/env python3
f = "/opt/keybuzz/keybuzz-client/app/api/channels/registry/route.ts"
with open(f, 'r', encoding='utf-8') as fh:
    content = fh.read()
if 'shopify' in content:
    print("SKIP: Shopify already in registry")
else:
    old = """  {
    id: 'email',
    label: 'Email',
    description: 'Emails directs',
    logo: '/marketplaces/email.svg',
    status: 'coming_soon'
  }
];"""
    new = """  {
    id: 'email',
    label: 'Email',
    description: 'Emails directs',
    logo: '/marketplaces/email.svg',
    status: 'coming_soon'
  },
  {
    id: 'shopify',
    label: 'Shopify',
    description: 'Boutique e-commerce Shopify',
    logo: '/marketplaces/shopify.svg',
    status: 'available'
  }
];"""
    if old in content:
        content = content.replace(old, new)
        with open(f, 'w', encoding='utf-8') as fh:
            fh.write(content)
        print("OK: Shopify added to CHANNELS_REGISTRY")
    else:
        print("WARN: email entry not found in expected format")
