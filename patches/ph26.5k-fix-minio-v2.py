#!/usr/bin/env python3
"""
PH26.5K: Fix MinIO endpoint configuration - v2
Parse URL properly to extract host, port, and SSL setting
"""

TARGET = '/opt/keybuzz/keybuzz-backend/src/modules/webhooks/inboxConversation.service.ts'

with open(TARGET, 'r') as f:
    content = f.read()

# Fix the MinIO endpoint - parse URL properly
old_minio_config = '''// PH26.5K: Raw MIME storage configuration
// Strip http:// or https:// from MINIO_ENDPOINT if present
const rawMinioEndpoint = (process.env.MINIO_ENDPOINT || '10.0.0.11').replace(/^https?:\\/\\//, '');
const rawMimeMinioClient = new MinioClient({
  endPoint: rawMinioEndpoint,
  port: parseInt(process.env.MINIO_PORT || '9000'),
  useSSL: process.env.MINIO_USE_SSL === 'true',
  accessKey: process.env.MINIO_ACCESS_KEY || 'keybuzz',
  secretKey: process.env.MINIO_SECRET_KEY || 'keybuzz123',
});'''

new_minio_config = '''// PH26.5K: Raw MIME storage configuration
// Parse MINIO_ENDPOINT URL to extract host, port, and SSL
function parseMinioEndpoint(endpoint: string): { host: string; port: number; useSSL: boolean } {
  const defaultPort = 9000;
  const defaultHost = '10.0.0.11';
  
  if (!endpoint) {
    return { host: defaultHost, port: defaultPort, useSSL: false };
  }
  
  // Handle URL format: http://host:port or https://host:port
  const urlMatch = endpoint.match(/^(https?):\\/\\/([^:]+):?(\\d+)?$/);
  if (urlMatch) {
    return {
      host: urlMatch[2],
      port: urlMatch[3] ? parseInt(urlMatch[3]) : (urlMatch[1] === 'https' ? 443 : defaultPort),
      useSSL: urlMatch[1] === 'https',
    };
  }
  
  // Handle host:port format
  const hostPortMatch = endpoint.match(/^([^:]+):(\\d+)$/);
  if (hostPortMatch) {
    return { host: hostPortMatch[1], port: parseInt(hostPortMatch[2]), useSSL: false };
  }
  
  // Just host
  return { host: endpoint, port: defaultPort, useSSL: false };
}

const minioConfig = parseMinioEndpoint(process.env.MINIO_ENDPOINT || '');
const rawMimeMinioClient = new MinioClient({
  endPoint: minioConfig.host,
  port: minioConfig.port,
  useSSL: minioConfig.useSSL,
  accessKey: process.env.MINIO_ACCESS_KEY || 'keybuzz',
  secretKey: process.env.MINIO_SECRET_KEY || 'keybuzz123',
});'''

if old_minio_config in content:
    content = content.replace(old_minio_config, new_minio_config)
    print('OK: Fixed MinIO endpoint configuration with URL parsing')
else:
    print('INFO: Old config not found, trying alternative pattern')
    # Try simpler approach - just replace the client instantiation
    if 'const rawMimeMinioClient = new MinioClient' in content:
        # Find and replace the whole block
        import re
        pattern = r'// PH26\.5K: Raw MIME storage configuration.*?const rawMimeMinioClient = new MinioClient\(\{[^}]+\}\);'
        if re.search(pattern, content, re.DOTALL):
            content = re.sub(pattern, new_minio_config, content, flags=re.DOTALL)
            print('OK: Replaced MinIO config with regex')
        else:
            print('ERROR: Could not match pattern')
            exit(1)
    else:
        print('ERROR: No MinioClient found')
        exit(1)

with open(TARGET, 'w') as f:
    f.write(content)

print('Done')
