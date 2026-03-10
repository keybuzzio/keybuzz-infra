#!/usr/bin/env python3
# PH26.5G: Fix Inbox counters - no fake counters from pagination

TARGET = '/opt/keybuzz/keybuzz-client/app/inbox/InboxTripane.tsx'

with open(TARGET, 'r') as f:
    content = f.read()

# 1. Fix the stats useMemo to return null when API unavailable
old_stats = '''  // PH26.4B: Stats - Use API stats (Single Source of Truth), fallback to local counts
  // âš ï¸ SOURCE OF TRUTH â€” les compteurs viennent de /stats/conversations
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
  }, [conversations, apiStats]);'''

new_stats = '''  // PH26.5G: Stats - ONLY from API (Single Source of Truth)
  // âš ï¸ NO FAKE COUNTERS - if API unavailable, show "â€”" not pagination size
  const stats = useMemo(() => {
    // Local count for unread only (not in API) and displayedCount
    const localUnread = conversations.filter(c => c.unread).length;
    const displayedCount = conversations.length;
    
    // If API stats available, use them (they're accurate, not capped at 50)
    if (apiStats) {
      return {
        total: apiStats.conversations.total,
        open: apiStats.conversations.open,
        pending: apiStats.conversations.pending,
        unread: localUnread,
        displayedCount,
        hasMore: apiStats.conversations.total > displayedCount,
        statsAvailable: true,
      };
    }
    
    // PH26.5G: API unavailable - return null for counters to show "â€”"
    return {
      total: null,      // Will display as "â€”"
      open: null,       // Will display as "â€”"
      pending: null,    // Will display as "â€”"
      unread: localUnread,  // Local is OK for this
      displayedCount,
      hasMore: false,
      statsAvailable: false,
    };
  }, [conversations, apiStats]);'''

if old_stats in content:
    content = content.replace(old_stats, new_stats)
    print('OK: Fixed stats useMemo - no fake counters')
elif 'PH26.5G' in content:
    print('INFO: PH26.5G stats fix already applied')
else:
    print('WARNING: Could not find stats useMemo pattern')

# 2. Fix UI to display "â€”" when stats are null
old_total_ui = '''              <div className="p-2 bg-gray-50 dark:bg-gray-700/50 rounded-lg text-center">
                <div className="text-lg font-bold text-gray-900 dark:text-white">
                  {stats.total}
                  {stats.hasMore && <span className="text-xs text-gray-400 ml-0.5">+</span>}
                </div>
                <div className="text-xs text-gray-500">Total</div>
              </div>'''

new_total_ui = '''              <div className="p-2 bg-gray-50 dark:bg-gray-700/50 rounded-lg text-center">
                <div className="text-lg font-bold text-gray-900 dark:text-white">
                  {stats.total !== null ? stats.total : <span className="text-gray-400">â€”</span>}
                  {stats.hasMore && <span className="text-xs text-gray-400 ml-0.5">+</span>}
                </div>
                <div className="text-xs text-gray-500">Total</div>
              </div>'''

if old_total_ui in content:
    content = content.replace(old_total_ui, new_total_ui)
    print('OK: Fixed Total display for null')
else:
    print('INFO: Total display already handles null or different format')

# Fix Open counter
old_open_ui = '''              <div className="p-2 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg text-center">
                <div className="text-lg font-bold text-yellow-600 dark:text-yellow-400">{stats.open}</div>
                <div className="text-xs text-gray-500">Ouvert</div>
              </div>'''

new_open_ui = '''              <div className="p-2 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg text-center">
                <div className="text-lg font-bold text-yellow-600 dark:text-yellow-400">{stats.open !== null ? stats.open : <span className="text-gray-400">â€”</span>}</div>
                <div className="text-xs text-gray-500">Ouvert</div>
              </div>'''

if old_open_ui in content:
    content = content.replace(old_open_ui, new_open_ui)
    print('OK: Fixed Open display for null')

# Fix Pending counter
old_pending_ui = '''              <div className="p-2 bg-blue-50 dark:bg-blue-900/20 rounded-lg text-center">
                <div className="text-lg font-bold text-blue-600 dark:text-blue-400">{stats.pending}</div>
                <div className="text-xs text-gray-500">En attente</div>
              </div>'''

new_pending_ui = '''              <div className="p-2 bg-blue-50 dark:bg-blue-900/20 rounded-lg text-center">
                <div className="text-lg font-bold text-blue-600 dark:text-blue-400">{stats.pending !== null ? stats.pending : <span className="text-gray-400">â€”</span>}</div>
                <div className="text-xs text-gray-500">En attente</div>
              </div>'''

if old_pending_ui in content:
    content = content.replace(old_pending_ui, new_pending_ui)
    print('OK: Fixed Pending display for null')

# 3. Add warning banner when stats unavailable - find the stats grid and add before it
stats_grid_pattern = '''            {/* Stats rapides - PH26.4B: Using API stats */}
            <div className="grid grid-cols-2 gap-2">'''

stats_grid_with_warning = '''            {/* PH26.5G: Warning if stats API unavailable */}
            {!stats.statsAvailable && (
              <div className="mb-2 px-2 py-1.5 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg">
                <p className="text-xs text-amber-700 dark:text-amber-300 text-center">
                  Stats API indisponible
                </p>
              </div>
            )}
            
            {/* Stats rapides - PH26.5G: Using API stats (no fake counters) */}
            <div className="grid grid-cols-2 gap-2">'''

if stats_grid_pattern in content and 'PH26.5G: Warning if stats API' not in content:
    content = content.replace(stats_grid_pattern, stats_grid_with_warning)
    print('OK: Added stats unavailable warning banner')
elif 'PH26.5G: Warning if stats API' in content:
    print('INFO: Warning banner already added')
else:
    print('WARNING: Could not find stats grid pattern')

with open(TARGET, 'w') as f:
    f.write(content)

print('Done')
