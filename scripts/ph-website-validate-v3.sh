#!/bin/bash
set -e

echo "=== PH-WEBSITE VALIDATION DEV v3 ==="
echo "Date: $(date)"

POD="keybuzz-website-7887b997c8-lzcd5"
NS="keybuzz-website-dev"

echo ""
echo "=== 1. Test via node (inside pod) ==="
for IMG_PATH in \
  "/_next/image?url=%2Fbrand%2Ficon.png&w=96&q=75" \
  "/_next/image?url=%2Fimages%2Fludovic.jpg&w=640&q=75" \
  "/_next/image?url=%2Fbrand%2Fmarketplaces%2Fdarty.png&w=256&q=75" \
  "/_next/image?url=%2Fbrand%2Fmarketplaces%2Fcdiscount.jpg&w=256&q=75" \
  "/_next/image?url=%2Fbrand%2Fmarketplaces%2Febay.png&w=256&q=75" \
  "/_next/image?url=%2Fbrand%2Fmarketplaces%2Ffnac.png&w=256&q=75"
do
  echo -n "  $IMG_PATH -> "
  kubectl exec -n $NS $POD -- node -e "
    const http = require('http');
    const url = 'http://127.0.0.1:3000${IMG_PATH}';
    http.get(url, (res) => {
      let size = 0;
      res.on('data', (chunk) => { size += chunk.length; });
      res.on('end', () => {
        console.log('HTTP ' + res.statusCode + ' | ' + size + ' bytes | cache: ' + (res.headers['x-nextjs-cache'] || 'N/A'));
      });
    }).on('error', (e) => { console.log('ERROR: ' + e.message); });
  " 2>/dev/null
done

echo ""
echo "=== 2. Cache directory after 1st round ==="
kubectl exec -n $NS $POD -- ls -laR /app/.next/cache/ 2>&1 | head -40

echo ""
echo "=== 3. Second round (should be cache HIT) ==="
for IMG_PATH in \
  "/_next/image?url=%2Fbrand%2Ficon.png&w=96&q=75" \
  "/_next/image?url=%2Fimages%2Fludovic.jpg&w=640&q=75" \
  "/_next/image?url=%2Fbrand%2Fmarketplaces%2Fdarty.png&w=256&q=75"
do
  echo -n "  $IMG_PATH -> "
  kubectl exec -n $NS $POD -- node -e "
    const http = require('http');
    const url = 'http://127.0.0.1:3000${IMG_PATH}';
    http.get(url, (res) => {
      let size = 0;
      res.on('data', (chunk) => { size += chunk.length; });
      res.on('end', () => {
        console.log('HTTP ' + res.statusCode + ' | ' + size + ' bytes | cache: ' + (res.headers['x-nextjs-cache'] || 'N/A'));
      });
    }).on('error', (e) => { console.log('ERROR: ' + e.message); });
  " 2>/dev/null
done

echo ""
echo "=== 4. Pod logs ==="
kubectl logs -n $NS $POD --tail=15 2>&1

echo ""
echo "=== 5. grep EACCES in ALL logs ==="
kubectl logs -n $NS $POD 2>&1 | grep -i "eacces" || echo "  ZERO EACCES errors"

echo ""
echo "=== VALIDATION COMPLETE ==="
