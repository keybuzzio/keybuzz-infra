#!/bin/bash
# PH-PLAYBOOKS-V2: Patch BFF simulate/route.ts
# Fix 1: Remove "commande" from tracking_request keywords
# Fix 2: Use daysLate from request body instead of hardcoded 0
set -e

FILE="/opt/keybuzz/keybuzz-client/app/api/playbooks/[id]/simulate/route.ts"
cp "$FILE" "${FILE}.bak"

# Fix 1: Remove 'commande' from tracking_request keywords
sed -i "s/keywords: \['suivi', 'tracking', 'colis', 'livraison', 'commande'\]/keywords: ['suivi', 'tracking', 'colis', 'livraison']/" "$FILE"

# Fix 2: Add daysLate to request body destructuring
sed -i "s/const { messageContent, tenantId, channel, orderStatus, hasTracking, orderAmount } = body;/const { messageContent, tenantId, channel, orderStatus, hasTracking, orderAmount, daysLate } = body;/" "$FILE"

# Fix 3: Use daysLate from body instead of hardcoded 0
sed -i "s/case 'days_late':/case 'days_late':/" "$FILE"
sed -i "/case 'days_late':/{ n; s/actual = 0;/actual = Number(daysLate) || 0;/ }" "$FILE"

echo "[PATCH] simulate/route.ts - fixed tracking keyword + days_late"
grep "commande\|days_late\|daysLate" "$FILE" | head -5
echo "DONE"
