#!/usr/bin/env python3
# PH26.5G: Fix stats useMemo - no fake counters

TARGET = '/opt/keybuzz/keybuzz-client/app/inbox/InboxTripane.tsx'

with open(TARGET, 'r') as f:
    lines = f.readlines()

# Find and replace the stats useMemo block
new_lines = []
in_stats_block = False
brace_count = 0
skip_until_closing = False

for i, line in enumerate(lines):
    # Detect start of stats useMemo
    if 'const stats = useMemo(() => {' in line and not in_stats_block:
        in_stats_block = True
        brace_count = 1
        # Insert new implementation
        new_lines.append('  // PH26.5G: Stats - ONLY from API (Single Source of Truth)\n')
        new_lines.append('  // NO FAKE COUNTERS - if API unavailable, show "â€”" not pagination size\n')
        new_lines.append('  const stats = useMemo(() => {\n')
        new_lines.append('    // Local count for unread only (not in API) and displayedCount\n')
        new_lines.append('    const localUnread = conversations.filter(c => c.unread).length;\n')
        new_lines.append('    const displayedCount = conversations.length;\n')
        new_lines.append('    \n')
        new_lines.append('    // If API stats available, use them (accurate, not capped at 50)\n')
        new_lines.append('    if (apiStats) {\n')
        new_lines.append('      return {\n')
        new_lines.append('        total: apiStats.conversations.total,\n')
        new_lines.append('        open: apiStats.conversations.open,\n')
        new_lines.append('        pending: apiStats.conversations.pending,\n')
        new_lines.append('        unread: localUnread,\n')
        new_lines.append('        displayedCount,\n')
        new_lines.append('        hasMore: apiStats.conversations.total > displayedCount,\n')
        new_lines.append('        statsAvailable: true,\n')
        new_lines.append('      };\n')
        new_lines.append('    }\n')
        new_lines.append('    \n')
        new_lines.append('    // PH26.5G: API unavailable - return null for counters\n')
        new_lines.append('    return {\n')
        new_lines.append('      total: null,\n')
        new_lines.append('      open: null,\n')
        new_lines.append('      pending: null,\n')
        new_lines.append('      unread: localUnread,\n')
        new_lines.append('      displayedCount,\n')
        new_lines.append('      hasMore: false,\n')
        new_lines.append('      statsAvailable: false,\n')
        new_lines.append('    };\n')
        skip_until_closing = True
        continue
    
    if skip_until_closing:
        # Count braces to find the end of useMemo
        brace_count += line.count('{') - line.count('}')
        if brace_count <= 0:
            # Found the closing - add it and stop skipping
            new_lines.append('  }, [conversations, apiStats]);\n')
            skip_until_closing = False
            in_stats_block = False
        continue
    
    new_lines.append(line)

with open(TARGET, 'w') as f:
    f.writelines(new_lines)

print('OK: Replaced stats useMemo with PH26.5G no-fake-counters version')
