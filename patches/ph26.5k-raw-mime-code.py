#!/usr/bin/env python3
"""
PH26.5K: Add raw MIME storage to inboxConversation.service.ts
"""

import hashlib
import re

TARGET = '/opt/keybuzz/keybuzz-backend/src/modules/webhooks/inboxConversation.service.ts'

with open(TARGET, 'r') as f:
    content = f.read()

# Check if already patched
if 'PH26.5K' in content:
    print('INFO: PH26.5K already applied')
    exit(0)

# Find the imports section and add crypto import
if "import * as crypto from 'crypto';" not in content:
    # Add after first import
    first_import = content.find("import {")
    if first_import == -1:
        first_import = content.find("import ")
    
    if first_import != -1:
        # Find end of first import line
        end_of_line = content.find('\n', first_import)
        content = content[:end_of_line+1] + "import * as crypto from 'crypto';\n" + content[end_of_line+1:]
        print('OK: Added crypto import')

# Find the MinIO client import/usage
# Looking for minioClient or similar
if 'minioClient' not in content and 'import { minioClient }' not in content:
    # Add MinIO import after crypto
    crypto_import_pos = content.find("import * as crypto from 'crypto';")
    if crypto_import_pos != -1:
        end_of_line = content.find('\n', crypto_import_pos)
        content = content[:end_of_line+1] + "import { minioClient, BUCKET } from './attachmentParser.service';\n" + content[end_of_line+1:]
        print('OK: Added minioClient import')

# Add the storeRawMime function before the first export
store_raw_mime_func = '''
// PH26.5K: Store raw MIME for replay parsing
const RAW_MIME_BUCKET = process.env.MINIO_BUCKET_RAW_MIME || 'keybuzz-raw-mime';

async function storeRawMime(tenantId: string, messageId: string, rawMime: string): Promise<{key: string, sha256: string, size: number} | null> {
  try {
    const buffer = Buffer.from(rawMime, 'utf-8');
    const sha256 = crypto.createHash('sha256').update(buffer).digest('hex');
    const key = `raw-mime/${tenantId}/${messageId}.eml`;
    
    // Ensure bucket exists
    const bucketExists = await minioClient.bucketExists(RAW_MIME_BUCKET);
    if (!bucketExists) {
      await minioClient.makeBucket(RAW_MIME_BUCKET);
      console.log(`[PH26.5K] Created bucket: ${RAW_MIME_BUCKET}`);
    }
    
    await minioClient.putObject(RAW_MIME_BUCKET, key, buffer, buffer.length, {
      'Content-Type': 'message/rfc822',
      'x-amz-meta-tenant-id': tenantId,
      'x-amz-meta-message-id': messageId,
      'x-amz-meta-sha256': sha256,
    });
    
    console.log(`[PH26.5K] Stored raw MIME: ${key} (${buffer.length} bytes, sha256=${sha256.substring(0,16)}...)`);
    return { key, sha256, size: buffer.length };
  } catch (err) {
    console.error('[PH26.5K] Failed to store raw MIME:', err);
    return null;
  }
}

'''

# Find first export function
export_func = content.find('export async function')
if export_func == -1:
    export_func = content.find('export function')

if export_func != -1 and 'storeRawMime' not in content:
    content = content[:export_func] + store_raw_mime_func + content[export_func:]
    print('OK: Added storeRawMime function')

# Now add the call to storeRawMime in the message processing
# Find where rawBody is used for parsing
# Looking for: const rawBody = payload.body;
rawbody_pattern = r"const rawBody = payload\.body;"
match = re.search(rawbody_pattern, content)

if match:
    # Find the end of the MIME processing block and add raw MIME storage
    # We need to add it after the message is created but before/during attachment processing
    
    # Look for the line that creates the message (msgId)
    msgid_pattern = r"console\.log\(`\[InboxConversation\] Created message: \$\{msgId\}"
    msgid_match = re.search(msgid_pattern, content)
    
    if msgid_match:
        # Find the end of this log statement
        pos = msgid_match.end()
        # Find the next newline
        next_newline = content.find('\n', pos)
        
        # Add raw MIME storage after message creation
        raw_mime_storage_code = '''
  // PH26.5K: Store raw MIME for replay parsing (before attachment processing)
  if (rawBody && rawBody.length > 100) {
    const mimeInfo = await storeRawMime(tenantId, msgId, rawBody);
    if (mimeInfo) {
      await productDb.query(
        'UPDATE messages SET raw_mime_key = $1, raw_mime_sha256 = $2, raw_mime_size_bytes = $3 WHERE id = $4',
        [mimeInfo.key, mimeInfo.sha256, mimeInfo.size, msgId]
      );
    }
  }
'''
        if 'PH26.5K: Store raw MIME' not in content:
            content = content[:next_newline+1] + raw_mime_storage_code + content[next_newline+1:]
            print('OK: Added raw MIME storage call after message creation')

with open(TARGET, 'w') as f:
    f.write(content)

print('Done')
