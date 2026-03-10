#!/usr/bin/env python3
# PH26.5D: Fix Content-Disposition to force download

TARGET = '/opt/keybuzz/keybuzz-client/app/api/attachments/[id]/route.ts'

with open(TARGET, 'r') as f:
    content = f.read()

# Fix 1: Change fallback from inline to attachment
old1 = '"Content-Disposition": contentDisposition || `inline; filename="attachment"`,'
new1 = '"Content-Disposition": contentDisposition || `attachment; filename="attachment"`,'

if old1 in content:
    content = content.replace(old1, new1)
    print('OK: Fixed fallback inline -> attachment')
else:
    print('INFO: Fallback already fixed or different format')

# Fix 2: Also ensure we always force attachment even if backend returns inline
# Find the line and replace it to always use attachment
old2 = '"Content-Disposition": contentDisposition || `attachment; filename="attachment"`,'
new2 = '''// PH26.5D: Always force download - never inline
        "Content-Disposition": contentDisposition 
          ? contentDisposition.replace(/^inline/, 'attachment')
          : `attachment; filename="attachment"`,'''

if old2 in content and 'PH26.5D' not in content:
    content = content.replace(old2, new2)
    print('OK: Added force attachment logic')
elif 'PH26.5D' in content:
    print('INFO: PH26.5D fix already applied')

with open(TARGET, 'w') as f:
    f.write(content)

print('Done')
