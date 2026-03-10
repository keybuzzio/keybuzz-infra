#!/usr/bin/env python3
"""
PH26.5K: Add raw MIME storage call - v2
"""

TARGET = '/opt/keybuzz/keybuzz-backend/src/modules/webhooks/inboxConversation.service.ts'

with open(TARGET, 'r') as f:
    content = f.read()

# Check if call already exists (not just function definition)
if 'await storeRawMime(tenantId' in content:
    print('INFO: storeRawMime call already present')
    exit(0)

# Find: const rawBody = payload.body;
# Insert storage call right after

old_code = '    const rawBody = payload.body;'

new_code = '''    const rawBody = payload.body;
    
    // PH26.5K: Store raw MIME for replay parsing (before any processing)
    if (rawBody && rawBody.length > 100) {
      try {
        const mimeInfo = await storeRawMime(tenantId, msgId, rawBody);
        if (mimeInfo) {
          await productDb.query(
            'UPDATE messages SET raw_mime_key = $1, raw_mime_sha256 = $2, raw_mime_size_bytes = $3 WHERE id = $4',
            [mimeInfo.key, mimeInfo.sha256, mimeInfo.size, msgId]
          );
        }
      } catch (storeErr) {
        console.error('[PH26.5K] Raw MIME storage failed (non-blocking):', storeErr);
      }
    }'''

if old_code in content:
    content = content.replace(old_code, new_code, 1)  # Only first occurrence
    print('OK: Added storeRawMime call')
else:
    print('ERROR: Could not find insertion point')
    exit(1)

with open(TARGET, 'w') as f:
    f.write(content)

print('Done')
