#!/usr/bin/env python3
"""
PH26.5K: Fix MinIO endpoint configuration
"""

TARGET = '/opt/keybuzz/keybuzz-backend/src/modules/webhooks/inboxConversation.service.ts'

with open(TARGET, 'r') as f:
    content = f.read()

# Fix the MinIO endpoint - remove http:// prefix handling
# The environment variable MINIO_ENDPOINT might contain http:// which is wrong

old_minio_config = '''// PH26.5K: Raw MIME storage configuration
const rawMimeMinioClient = new MinioClient({
  endPoint: process.env.MINIO_ENDPOINT || 'minio.keybuzz-backend-dev.svc.cluster.local',
  port: parseInt(process.env.MINIO_PORT || '9000'),
  useSSL: process.env.MINIO_USE_SSL === 'true',
  accessKey: process.env.MINIO_ACCESS_KEY || 'keybuzz',
  secretKey: process.env.MINIO_SECRET_KEY || 'keybuzz123',
});'''

new_minio_config = '''// PH26.5K: Raw MIME storage configuration
// Strip http:// or https:// from MINIO_ENDPOINT if present
const rawMinioEndpoint = (process.env.MINIO_ENDPOINT || '10.0.0.11').replace(/^https?:\\/\\//, '');
const rawMimeMinioClient = new MinioClient({
  endPoint: rawMinioEndpoint,
  port: parseInt(process.env.MINIO_PORT || '9000'),
  useSSL: process.env.MINIO_USE_SSL === 'true',
  accessKey: process.env.MINIO_ACCESS_KEY || 'keybuzz',
  secretKey: process.env.MINIO_SECRET_KEY || 'keybuzz123',
});'''

if old_minio_config in content:
    content = content.replace(old_minio_config, new_minio_config)
    print('OK: Fixed MinIO endpoint configuration')
else:
    print('ERROR: Could not find MinIO config to fix')
    # Try to find what's there
    import re
    match = re.search(r'const rawMimeMinioClient = new MinioClient', content)
    if match:
        print(f'Found MinioClient at position {match.start()}')
    exit(1)

with open(TARGET, 'w') as f:
    f.write(content)

print('Done')
