#!/usr/bin/env python3
"""
PH26.5K: Add raw MIME storage to inboxConversation.service.ts
"""

import re

TARGET = '/opt/keybuzz/keybuzz-backend/src/modules/webhooks/inboxConversation.service.ts'

with open(TARGET, 'r') as f:
    content = f.read()

# Check if already patched
if 'PH26.5K' in content:
    print('INFO: PH26.5K already applied')
    exit(0)

# Add imports after existing imports
import_block = '''import { productDb } from '../../lib/productDb';
import { randomBytes, createHash } from 'crypto';'''

old_import = '''import { productDb } from '../../lib/productDb';
import { randomBytes } from 'crypto';'''

if old_import in content:
    content = content.replace(old_import, import_block)
    print('OK: Updated crypto import to include createHash')
else:
    print('INFO: Import block different, adding createHash separately')
    if "import { randomBytes } from 'crypto';" in content:
        content = content.replace(
            "import { randomBytes } from 'crypto';",
            "import { randomBytes, createHash } from 'crypto';"
        )
        print('OK: Added createHash to crypto import')

# Add MinIO import after existing imports
if 'import { Client as MinioClient }' not in content:
    # Find last import statement
    last_import = content.rfind("import {")
    if last_import != -1:
        # Find end of that import
        end = content.find(';', last_import)
        if end != -1:
            content = content[:end+1] + "\nimport { Client as MinioClient } from 'minio';" + content[end+1:]
            print('OK: Added MinIO client import')

# Add storeRawMime function and MinIO config after imports, before first function
store_raw_mime_code = '''
// PH26.5K: Raw MIME storage configuration
const rawMimeMinioClient = new MinioClient({
  endPoint: process.env.MINIO_ENDPOINT || 'minio.keybuzz-backend-dev.svc.cluster.local',
  port: parseInt(process.env.MINIO_PORT || '9000'),
  useSSL: process.env.MINIO_USE_SSL === 'true',
  accessKey: process.env.MINIO_ACCESS_KEY || 'keybuzz',
  secretKey: process.env.MINIO_SECRET_KEY || 'keybuzz123',
});
const RAW_MIME_BUCKET = process.env.MINIO_BUCKET_RAW_MIME || 'keybuzz-raw-mime';

// PH26.5K: Store raw MIME for replay parsing
async function storeRawMime(tenantId: string, messageId: string, rawMime: string): Promise<{key: string, sha256: string, size: number} | null> {
  try {
    const buffer = Buffer.from(rawMime, 'utf-8');
    const sha256 = createHash('sha256').update(buffer).digest('hex');
    const key = `raw-mime/${tenantId}/${messageId}.eml`;
    
    // Ensure bucket exists
    try {
      const bucketExists = await rawMimeMinioClient.bucketExists(RAW_MIME_BUCKET);
      if (!bucketExists) {
        await rawMimeMinioClient.makeBucket(RAW_MIME_BUCKET);
        console.log(`[PH26.5K] Created bucket: ${RAW_MIME_BUCKET}`);
      }
    } catch (bucketErr) {
      // Bucket might already exist, continue
    }
    
    await rawMimeMinioClient.putObject(RAW_MIME_BUCKET, key, buffer, buffer.length, {
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

# Find the first function definition (after imports)
first_func = content.find('// Generate cuid-like ID')
if first_func == -1:
    first_func = content.find('function createId')

if first_func != -1 and 'storeRawMime' not in content:
    content = content[:first_func] + store_raw_mime_code + content[first_func:]
    print('OK: Added storeRawMime function and MinIO config')

# Add raw MIME storage call after message creation
# Find: console.log(`[InboxConversation] Created message: ${msgId}
call_pattern = r"console\.log\(`\[InboxConversation\] Created message: \$\{msgId\}[^`]*`\);"
match = re.search(call_pattern, content)

if match and 'PH26.5K: Store raw MIME' not in content:
    pos = match.end()
    
    raw_mime_call = '''

  // PH26.5K: Store raw MIME for replay parsing
  const rawBody = payload.body;
  if (rawBody && rawBody.length > 100 && (rawBody.includes('Content-Type:') || rawBody.includes('Content-Disposition:'))) {
    const mimeInfo = await storeRawMime(tenantId, msgId, rawBody);
    if (mimeInfo) {
      await productDb.query(
        'UPDATE messages SET raw_mime_key = $1, raw_mime_sha256 = $2, raw_mime_size_bytes = $3 WHERE id = $4',
        [mimeInfo.key, mimeInfo.sha256, mimeInfo.size, msgId]
      );
      console.log(`[PH26.5K] Updated message ${msgId} with raw MIME metadata`);
    }
  }
'''
    content = content[:pos] + raw_mime_call + content[pos:]
    print('OK: Added raw MIME storage call after message creation')

with open(TARGET, 'w') as f:
    f.write(content)

print('Done')
