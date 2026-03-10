#!/usr/bin/env python3
"""
PH26.5K: Add raw MIME storage call
"""

TARGET = '/opt/keybuzz/keybuzz-backend/src/modules/webhooks/inboxConversation.service.ts'

with open(TARGET, 'r') as f:
    content = f.read()

if 'PH26.5K: Store raw MIME' in content:
    print('INFO: Raw MIME storage call already present')
    exit(0)

# Find the pattern: const rawBody = payload.body;
# And add storage right after the if block that checks MIME content

old_pattern = '''  // ===== PROCESS MIME ATTACHMENTS (PH-ATTACHMENTS-DOWNLOAD-TRUTH-01) =====
  try {
    // Check if body contains MIME content
    const rawBody = payload.body;
    if (rawBody && (rawBody.includes('Content-Disposition:') || rawBody.includes('Content-Type:') || /JVBERi0[A-Za-z0-9+\\/=]{50,}/.test(rawBody))) {
      console.log('[InboxConversation] Detected MIME content, parsing for attachments...');'''

new_pattern = '''  // ===== PROCESS MIME ATTACHMENTS (PH-ATTACHMENTS-DOWNLOAD-TRUTH-01) =====
  try {
    // Check if body contains MIME content
    const rawBody = payload.body;
    
    // PH26.5K: Store raw MIME for replay parsing (before parsing/processing)
    if (rawBody && rawBody.length > 100) {
      const mimeInfo = await storeRawMime(tenantId, msgId, rawBody);
      if (mimeInfo) {
        await productDb.query(
          'UPDATE messages SET raw_mime_key = $1, raw_mime_sha256 = $2, raw_mime_size_bytes = $3 WHERE id = $4',
          [mimeInfo.key, mimeInfo.sha256, mimeInfo.size, msgId]
        );
        console.log(`[PH26.5K] Stored raw MIME for message ${msgId}`);
      }
    }
    
    if (rawBody && (rawBody.includes('Content-Disposition:') || rawBody.includes('Content-Type:') || /JVBERi0[A-Za-z0-9+\\/=]{50,}/.test(rawBody))) {
      console.log('[InboxConversation] Detected MIME content, parsing for attachments...');'''

if old_pattern in content:
    content = content.replace(old_pattern, new_pattern)
    print('OK: Added raw MIME storage call')
else:
    print('ERROR: Pattern not found, manual intervention needed')
    print('Looking for alternative pattern...')
    
    # Try simpler pattern
    simple_old = '    const rawBody = payload.body;\n    if (rawBody && (rawBody.includes'
    if simple_old in content:
        simple_new = '''    const rawBody = payload.body;
    
    // PH26.5K: Store raw MIME for replay parsing
    if (rawBody && rawBody.length > 100) {
      const mimeInfo = await storeRawMime(tenantId, msgId, rawBody);
      if (mimeInfo) {
        await productDb.query(
          'UPDATE messages SET raw_mime_key = $1, raw_mime_sha256 = $2, raw_mime_size_bytes = $3 WHERE id = $4',
          [mimeInfo.key, mimeInfo.sha256, mimeInfo.size, msgId]
        );
        console.log(`[PH26.5K] Stored raw MIME for message ${msgId}`);
      }
    }
    
    if (rawBody && (rawBody.includes'''
        content = content.replace(simple_old, simple_new)
        print('OK: Added raw MIME storage call (simple pattern)')
    else:
        exit(1)

with open(TARGET, 'w') as f:
    f.write(content)

print('Done')
