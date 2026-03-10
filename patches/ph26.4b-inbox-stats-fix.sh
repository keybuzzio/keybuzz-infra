#!/bin/bash
# PH26.4B: Fix Inbox stats cap 50 - Use /stats/conversations as source of truth
# This patch modifies InboxTripane.tsx to fetch stats from the centralized API

set -e

INBOX_FILE="/opt/keybuzz/keybuzz-client/app/inbox/InboxTripane.tsx"
BACKUP_FILE="${INBOX_FILE}.bak.ph264b.$(date +%Y%m%d_%H%M%S)"

echo "[PH26.4B] Creating backup: $BACKUP_FILE"
cp "$INBOX_FILE" "$BACKUP_FILE"

echo "[PH26.4B] Adding import for fetchInboxStats..."

# 1. Add import for fetchInboxStats after the last import
sed -i '/import { resolveOrderId }/a\
// PH26.4B: Single Source of Truth - Stats API\
import { fetchInboxStats, InboxStats } from "@/src/services/stats.service";' "$INBOX_FILE"

# 2. Add state for API stats after the state declarations
# Find the line with "const [attachments, setAttachments]" and add after it
sed -i '/const \[attachments, setAttachments\]/a\
  \
  // PH26.4B: Stats from API (Single Source of Truth)\
  const [apiStats, setApiStats] = useState<InboxStats | null>(null);' "$INBOX_FILE"

echo "[PH26.4B] Adding useEffect to fetch stats..."

# 3. We need to find a good place to add the useEffect for stats
# Let's add it after the tenant initialization
# Create a temp file with the additional useEffect
cat > /tmp/ph264b_stats_effect.txt << 'EFFECT_EOF'

  // PH26.4B: Fetch stats from /stats/conversations (Single Source of Truth)
  // ⚠️ SOURCE OF TRUTH — NE PAS RECALCULER localement
  useEffect(() => {
    async function loadStats() {
      const tenantId = getCurrentTenantId();
      if (!tenantId) return;
      
      const mappedTenantId = mapTenantIdForApi(tenantId);
      console.log('[InboxTripane] PH26.4B: Fetching stats from /stats/conversations for', mappedTenantId);
      
      try {
        const stats = await fetchInboxStats(mappedTenantId);
        if (stats) {
          console.log('[InboxTripane] PH26.4B: Got stats - total:', stats.conversations.total, 'open:', stats.conversations.open);
          setApiStats(stats);
        }
      } catch (error) {
        console.warn('[InboxTripane] PH26.4B: Failed to fetch stats, will use local counts');
      }
    }
    
    loadStats();
    
    // Refresh stats every 30 seconds
    const interval = setInterval(loadStats, 30000);
    return () => clearInterval(interval);
  }, []);
EFFECT_EOF

# Find the line "hasInitialized.current = true;" and insert after it
# Using awk for more complex insertion
awk '
/hasInitialized\.current = true;/ {
    print
    while ((getline line < "/tmp/ph264b_stats_effect.txt") > 0) {
        print line
    }
    close("/tmp/ph264b_stats_effect.txt")
    next
}
{print}
' "$INBOX_FILE" > "${INBOX_FILE}.tmp" && mv "${INBOX_FILE}.tmp" "$INBOX_FILE"

echo "[PH26.4B] Updating stats calculation to use API stats..."

# 4. Replace the stats useMemo to use API stats with fallback
# Original:
#   const stats = useMemo(() => ({
#     total: conversations.length,
#     open: conversations.filter(c => c.status === "open").length,
#     pending: conversations.filter(c => c.status === "pending").length,
#     unread: conversations.filter(c => c.unread).length,
#   }), [conversations]);
# 
# New: Use API stats if available, fallback to local

cat > /tmp/ph264b_stats_memo.txt << 'MEMO_EOF'
  // PH26.4B: Stats - Use API stats (Single Source of Truth), fallback to local counts
  // ⚠️ SOURCE OF TRUTH — les compteurs viennent de /stats/conversations
  const stats = useMemo(() => {
    // Local counts for fallback and for "unread" (not in API)
    const localCounts = {
      total: conversations.length,
      open: conversations.filter(c => c.status === "open").length,
      pending: conversations.filter(c => c.status === "pending").length,
      unread: conversations.filter(c => c.unread).length,
    };
    
    // If API stats available, use them (they're accurate, not capped at 50)
    if (apiStats) {
      return {
        total: apiStats.conversations.total,
        open: apiStats.conversations.open,
        pending: apiStats.conversations.pending,
        unread: localCounts.unread, // Keep local for unread (not in API)
        // For UI: show if there are more than displayed
        displayedCount: localCounts.total,
        hasMore: apiStats.conversations.total > localCounts.total,
      };
    }
    
    return {
      ...localCounts,
      displayedCount: localCounts.total,
      hasMore: false,
    };
  }, [conversations, apiStats]);
MEMO_EOF

# Replace the old stats useMemo with the new one
# This is tricky - we need to replace a multi-line block
# Use perl for multi-line replacement
perl -i -0pe 's/\/\/ Stats rapides\s*\n\s*const stats = useMemo\(\(\) => \(\{\s*\n\s*total: conversations\.length,\s*\n\s*open: conversations\.filter\(c => c\.status === "open"\)\.length,\s*\n\s*pending: conversations\.filter\(c => c\.status === "pending"\)\.length,\s*\n\s*unread: conversations\.filter\(c => c\.unread\)\.length,\s*\n\s*\}\), \[conversations\]\);/`cat \/tmp\/ph264b_stats_memo.txt`/e' "$INBOX_FILE"

# If perl replacement didn't work (pattern might be slightly different), try sed approach
if grep -q "total: conversations.length" "$INBOX_FILE"; then
  echo "[PH26.4B] Perl replacement incomplete, trying alternative approach..."
  
  # Create a modified version using Python for better multi-line handling
  python3 << 'PYEOF'
import re

with open('/opt/keybuzz/keybuzz-client/app/inbox/InboxTripane.tsx', 'r') as f:
    content = f.read()

# Read the new memo content
with open('/tmp/ph264b_stats_memo.txt', 'r') as f:
    new_memo = f.read()

# Pattern to match the old stats calculation
old_pattern = r'// Stats rapides\s*\n\s*const stats = useMemo\(\(\) => \(\{\s*\n\s*total: conversations\.length,\s*\n\s*open: conversations\.filter\(c => c\.status === "open"\)\.length,\s*\n\s*pending: conversations\.filter\(c => c\.status === "pending"\)\.length,\s*\n\s*unread: conversations\.filter\(c => c\.unread\)\.length,\s*\n\s*\}\), \[conversations\]\);'

# Replace
new_content = re.sub(old_pattern, new_memo.strip(), content, flags=re.MULTILINE)

with open('/opt/keybuzz/keybuzz-client/app/inbox/InboxTripane.tsx', 'w') as f:
    f.write(new_content)

print("[PH26.4B] Python replacement completed")
PYEOF
fi

echo "[PH26.4B] Verifying changes..."

# Verify the import was added
if grep -q "fetchInboxStats" "$INBOX_FILE"; then
  echo "[PH26.4B] ✅ Import added successfully"
else
  echo "[PH26.4B] ❌ Import NOT found - patch may have failed"
fi

# Verify the state was added
if grep -q "apiStats, setApiStats" "$INBOX_FILE"; then
  echo "[PH26.4B] ✅ apiStats state added successfully"
else
  echo "[PH26.4B] ❌ apiStats state NOT found - patch may have failed"
fi

# Verify the useEffect was added
if grep -q "PH26.4B: Fetching stats from" "$INBOX_FILE"; then
  echo "[PH26.4B] ✅ Stats useEffect added successfully"
else
  echo "[PH26.4B] ❌ Stats useEffect NOT found - patch may have failed"
fi

# Verify the stats memo was updated
if grep -q "apiStats.conversations.total" "$INBOX_FILE"; then
  echo "[PH26.4B] ✅ Stats memo updated successfully"
else
  echo "[PH26.4B] ❌ Stats memo NOT updated - patch may have failed"
fi

# Clean up temp files
rm -f /tmp/ph264b_stats_effect.txt /tmp/ph264b_stats_memo.txt

echo "[PH26.4B] Patch completed. Backup at: $BACKUP_FILE"
