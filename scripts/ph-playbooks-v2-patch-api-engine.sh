#!/bin/bash
# PH-PLAYBOOKS-V2: Patch playbook-engine.service.ts
# Fix 1: Remove "commande" from tracking_request keywords (too generic)
# Fix 2: Add "suivi commande" as specific synonym instead
set -e

FILE="/opt/keybuzz/keybuzz-api/src/services/playbook-engine.service.ts"
cp "$FILE" "${FILE}.bak"

# Remove 'commande' from tracking_request keywords (keep other keywords)
sed -i "s/keywords: \['suivi', 'tracking', 'colis', 'livraison', 'commande'\]/keywords: ['suivi', 'tracking', 'colis', 'livraison']/" "$FILE"

echo "[PATCH] playbook-engine.service.ts - removed 'commande' from tracking_request keywords"
grep "tracking_request" "$FILE" | head -3
echo "DONE"
