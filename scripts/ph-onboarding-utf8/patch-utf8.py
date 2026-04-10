#!/usr/bin/env python3
# PH-ONBOARDING-UTF8-FIX-01: Fix unicode escape sequences in UI

import sys

BASE = "/opt/keybuzz/keybuzz-client"
changes = 0

# === FILE 1: app/login/page.tsx ===
f1 = BASE + "/app/login/page.tsx"
with open(f1, "r", encoding="utf-8") as f:
    content1 = f.read()

replacements_login = [
    (r"'Aucun compte trouv\u00e9'", "'Aucun compte trouvé'"),
    (r"associ\u00e9 \u00e0 l", "associé à l"),
    (r"Cr\u00e9ez votre compte pour commencer \u00e0 utiliser KeyBuzz.",
     "Créez votre compte pour commencer à utiliser KeyBuzz."),
    (r"'Cr\u00e9er un compte'", "'Créer un compte'"),
]

for old, new in replacements_login:
    if old in content1:
        content1 = content1.replace(old, new, 1)
        changes += 1
        print("[login] Fixed: " + old[:50])
    else:
        print("[login] SKIP: " + old[:50])

with open(f1, "w", encoding="utf-8") as f:
    f.write(content1)

# === FILE 2: OrderSidePanel.tsx ===
f2 = BASE + "/src/features/inbox/components/OrderSidePanel.tsx"
with open(f2, "r", encoding="utf-8") as f:
    content2 = f.read()

replacements_osp = [
    (r"'Pay\u00e9'", "'Payé'"),
    (r"'Rembours\u00e9'", "'Remboursé'"),
    (r"'Partiellement rembours\u00e9'", "'Partiellement remboursé'"),
    (r"'Annul\u00e9'", "'Annulé'"),
    (r"'Exp\u00e9di\u00e9'", "'Expédié'"),
    (r"'Non exp\u00e9di\u00e9'", "'Non expédié'"),
    (r"'Partiellement exp\u00e9di\u00e9'", "'Partiellement expédié'"),
]

for old, new in replacements_osp:
    if old in content2:
        content2 = content2.replace(old, new, 1)
        changes += 1
        print("[OrderSidePanel] Fixed: " + old)
    else:
        print("[OrderSidePanel] SKIP: " + old)

with open(f2, "w", encoding="utf-8") as f:
    f.write(content2)

print("\n=== " + str(changes) + " replacements applied ===")
sys.exit(0)
