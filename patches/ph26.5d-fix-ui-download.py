#!/usr/bin/env python3
# PH26.5D: Fix attachment download in UI - add download attribute

TARGET = '/opt/keybuzz/keybuzz-client/app/inbox/InboxTripane.tsx'

with open(TARGET, 'r') as f:
    content = f.read()

# Find and fix the attachment link
# Remove target="_blank" and add download attribute
old_link = '''<a
                                key={att.id}
                                href={`/api/attachments/${att.id}?tenantId=${getCurrentTenantId() || ""}`}
                                target="_blank"
                                rel="noopener noreferrer"'''

new_link = '''<a
                                key={att.id}
                                href={`/api/attachments/${att.id}?tenantId=${getCurrentTenantId() || ""}`}
                                download={att.filename}
                                rel="noopener noreferrer"
                                // PH26.5D: Force download instead of inline'''

if old_link in content:
    content = content.replace(old_link, new_link)
    print('OK: Fixed attachment link - added download attribute')
elif 'PH26.5D: Force download' in content:
    print('INFO: PH26.5D UI fix already applied')
else:
    print('WARNING: Could not find attachment link pattern')
    # Try alternative search
    if 'target="_blank"' in content and '/api/attachments/' in content:
        print('INFO: Pattern exists but in different format')

with open(TARGET, 'w') as f:
    f.write(content)

print('Done')
