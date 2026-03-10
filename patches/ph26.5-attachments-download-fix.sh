#!/bin/bash
# PH26.5 â€” Fix: Forcer tÃ©lÃ©chargement des PJ (pas d'inline)

ATTACHMENTS_ROUTES="/opt/keybuzz/keybuzz-backend/src/modules/attachments/attachments.routes.ts"

# Backup
cp "$ATTACHMENTS_ROUTES" "${ATTACHMENTS_ROUTES}.bak.ph265"

# Remplacer la ligne qui dÃ©termine le disposition
sed -i "s/const disposition = att.isInline ? 'inline' : 'attachment';/const disposition = 'attachment';  \/\/ PH26.5: Toujours forcer le tÃ©lÃ©chargement/" "$ATTACHMENTS_ROUTES"

# VÃ©rifier
echo "=== Verification ==="
grep -n "disposition" "$ATTACHMENTS_ROUTES"

echo ""
echo "=== Done ==="
