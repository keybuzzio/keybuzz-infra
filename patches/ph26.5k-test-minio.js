// PH26.5K: Test MinIO connection and bucket
const { Client } = require('minio');

const endpoint = process.env.MINIO_ENDPOINT || '';
const urlMatch = endpoint.match(/^(https?):\/\/([^:]+):?(\d+)?$/);
const host = urlMatch ? urlMatch[2] : '10.0.0.11';
const port = urlMatch && urlMatch[3] ? parseInt(urlMatch[3]) : 9000;
const useSSL = urlMatch && urlMatch[1] === 'https';

console.log('Parsed MinIO config:', JSON.stringify({ host, port, useSSL }));

const client = new Client({
  endPoint: host,
  port: port,
  useSSL: useSSL,
  accessKey: process.env.MINIO_ACCESS_KEY || 'keybuzz',
  secretKey: process.env.MINIO_SECRET_KEY || 'keybuzz123',
});

async function test() {
  try {
    const exists = await client.bucketExists('keybuzz-raw-mime');
    console.log('Bucket keybuzz-raw-mime exists:', exists);
    
    if (!exists) {
      await client.makeBucket('keybuzz-raw-mime');
      console.log('Bucket created successfully');
    }
    
    const buckets = await client.listBuckets();
    console.log('All buckets:', buckets.map(b => b.name));
    
    // List objects in raw-mime bucket
    const objects = [];
    const stream = client.listObjects('keybuzz-raw-mime', '', true);
    stream.on('data', obj => objects.push(obj.name));
    stream.on('end', () => {
      console.log('Objects in keybuzz-raw-mime:', objects.length);
      if (objects.length > 0) {
        console.log('First 5 objects:', objects.slice(0, 5));
      }
    });
    stream.on('error', err => console.error('List error:', err.message));
    
  } catch (err) {
    console.error('MinIO error:', err.message);
  }
}

test();
