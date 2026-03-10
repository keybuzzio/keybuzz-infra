// PH26.5K: Simulate raw MIME storage
const { Client } = require('minio');
const crypto = require('crypto');
const { Pool } = require('pg');

const endpoint = process.env.MINIO_ENDPOINT || '';
const urlMatch = endpoint.match(/^(https?):\/\/([^:]+):?(\d+)?$/);
const host = urlMatch ? urlMatch[2] : '10.0.0.11';
const port = urlMatch && urlMatch[3] ? parseInt(urlMatch[3]) : 9000;
const useSSL = urlMatch && urlMatch[1] === 'https';

const minioClient = new Client({
  endPoint: host,
  port: port,
  useSSL: useSSL,
  accessKey: process.env.MINIO_ACCESS_KEY || 'keybuzz',
  secretKey: process.env.MINIO_SECRET_KEY || 'keybuzz123',
});

const RAW_MIME_BUCKET = 'keybuzz-raw-mime';

// Simulated raw MIME content
const testRawMime = `Content-Type: multipart/mixed; boundary="----=_Part_TEST_12345"

------=_Part_TEST_12345
Content-Type: text/plain; charset=utf-8

Bonjour, ceci est un message de test PH26.5K avec une piece jointe simulee.
Ce message sert a valider le stockage raw MIME.
Cordialement.

------=_Part_TEST_12345
Content-Type: image/jpeg; name="test-image.jpg"
Content-Disposition: attachment; filename="test-image.jpg"
Content-Transfer-Encoding: base64

/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRof
Hh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAALCAABAAEBAREA/8QAFAAB
AAAAAAAAAAAAAAAAAAAACP/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AVN//2Q==
------=_Part_TEST_12345--`;

async function simulate() {
  const tenantId = 'ecomlg-001';
  const messageId = 'test-ph265k-' + Date.now();
  
  console.log('=== PH26.5K Simulation ===');
  console.log('Tenant:', tenantId);
  console.log('MessageId:', messageId);
  
  try {
    // 1. Store raw MIME in MinIO
    const buffer = Buffer.from(testRawMime, 'utf-8');
    const sha256 = crypto.createHash('sha256').update(buffer).digest('hex');
    const key = `raw-mime/${tenantId}/${messageId}.eml`;
    
    console.log('\n1. Storing raw MIME...');
    console.log('   Key:', key);
    console.log('   Size:', buffer.length, 'bytes');
    console.log('   SHA256:', sha256.substring(0, 32) + '...');
    
    await minioClient.putObject(RAW_MIME_BUCKET, key, buffer, buffer.length, {
      'Content-Type': 'message/rfc822',
      'x-amz-meta-tenant-id': tenantId,
      'x-amz-meta-message-id': messageId,
      'x-amz-meta-sha256': sha256,
    });
    console.log('   STORED OK');
    
    // 2. Verify object exists
    console.log('\n2. Verifying storage...');
    const stat = await minioClient.statObject(RAW_MIME_BUCKET, key);
    console.log('   MinIO size:', stat.size, 'bytes');
    console.log('   Size match:', stat.size === buffer.length);
    
    // 3. Retrieve and verify hash
    console.log('\n3. Verifying integrity...');
    const stream = await minioClient.getObject(RAW_MIME_BUCKET, key);
    const chunks = [];
    for await (const chunk of stream) {
      chunks.push(chunk);
    }
    const retrieved = Buffer.concat(chunks);
    const retrievedHash = crypto.createHash('sha256').update(retrieved).digest('hex');
    console.log('   Retrieved size:', retrieved.length, 'bytes');
    console.log('   Hash match:', sha256 === retrievedHash);
    
    // 4. List objects
    console.log('\n4. Listing bucket objects...');
    const objects = [];
    const listStream = minioClient.listObjects(RAW_MIME_BUCKET, 'raw-mime/', true);
    listStream.on('data', obj => objects.push({ name: obj.name, size: obj.size }));
    await new Promise((resolve, reject) => {
      listStream.on('end', resolve);
      listStream.on('error', reject);
    });
    console.log('   Total objects:', objects.length);
    objects.forEach(o => console.log('   -', o.name, '(', o.size, 'bytes)'));
    
    console.log('\n=== VALIDATION SUCCESS ===');
    
  } catch (err) {
    console.error('ERROR:', err.message);
    process.exit(1);
  }
}

simulate();
