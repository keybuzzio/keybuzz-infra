#!/bin/bash
set -e

echo "=== PH-WEBSITE VALIDATION PROD ==="
echo "Date: $(date)"

NS="keybuzz-website-prod"

echo ""
echo "=== 1. Get PROD pods ==="
kubectl get pods -n $NS -o wide | grep Running
PODS=$(kubectl get pods -n $NS -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}')
POD1=$(echo $PODS | awk '{print $1}')
echo "Using pod: $POD1"

echo ""
echo "=== 2. Pod logs — check for clean startup ==="
kubectl logs -n $NS $POD1 --tail=10 2>&1

echo ""
echo "=== 3. Check EACCES in ALL logs ==="
kubectl logs -n $NS $POD1 2>&1 | grep -i "eacces" || echo "  ZERO EACCES errors"

echo ""
echo "=== 4. Cache directory permissions ==="
kubectl exec -n $NS $POD1 -- ls -la /app/.next/cache/ 2>&1

echo ""
echo "=== 5. Test images via node (1st round — MISS expected) ==="
for IMG_PATH in \
  "/_next/image?url=%2Fbrand%2Ficon.png&w=96&q=75" \
  "/_next/image?url=%2Fimages%2Fludovic.jpg&w=640&q=75" \
  "/_next/image?url=%2Fbrand%2Fmarketplaces%2Fdarty.png&w=256&q=75" \
  "/_next/image?url=%2Fbrand%2Fmarketplaces%2Fcdiscount.jpg&w=256&q=75" \
  "/_next/image?url=%2Fbrand%2Fmarketplaces%2Febay.png&w=256&q=75" \
  "/_next/image?url=%2Fbrand%2Fmarketplaces%2Ffnac.png&w=256&q=75"
do
  echo -n "  $IMG_PATH -> "
  kubectl exec -n $NS $POD1 -- node -e "
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
echo "=== 6. Cache populated? ==="
kubectl exec -n $NS $POD1 -- ls -laR /app/.next/cache/ 2>&1 | head -20

echo ""
echo "=== 7. Test images (2nd round — HIT expected) ==="
for IMG_PATH in \
  "/_next/image?url=%2Fbrand%2Ficon.png&w=96&q=75" \
  "/_next/image?url=%2Fimages%2Fludovic.jpg&w=640&q=75" \
  "/_next/image?url=%2Fbrand%2Fmarketplaces%2Fdarty.png&w=256&q=75"
do
  echo -n "  $IMG_PATH -> "
  kubectl exec -n $NS $POD1 -- node -e "
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
echo "=== 8. Test via www.keybuzz.pro (public) ==="
echo "--- Homepage ---"
curl -s -o /dev/null -w 'HTTP %{http_code} | size: %{size_download}\n' 'https://www.keybuzz.pro/' 2>/dev/null
echo "--- icon.png ---"
curl -s -o /dev/null -w 'HTTP %{http_code} | size: %{size_download}\n' 'https://www.keybuzz.pro/_next/image?url=%2Fbrand%2Ficon.png&w=96&q=75' 2>/dev/null
echo "--- ludovic.jpg ---"
curl -s -o /dev/null -w 'HTTP %{http_code} | size: %{size_download}\n' 'https://www.keybuzz.pro/_next/image?url=%2Fimages%2Fludovic.jpg&w=640&q=75' 2>/dev/null
echo "--- darty.png ---"
curl -s -o /dev/null -w 'HTTP %{http_code} | size: %{size_download}\n' 'https://www.keybuzz.pro/_next/image?url=%2Fbrand%2Fmarketplaces%2Fdarty.png&w=256&q=75' 2>/dev/null
echo "--- cdiscount.jpg ---"
curl -s -o /dev/null -w 'HTTP %{http_code} | size: %{size_download}\n' 'https://www.keybuzz.pro/_next/image?url=%2Fbrand%2Fmarketplaces%2Fcdiscount.jpg&w=256&q=75' 2>/dev/null
echo "--- ebay.png ---"
curl -s -o /dev/null -w 'HTTP %{http_code} | size: %{size_download}\n' 'https://www.keybuzz.pro/_next/image?url=%2Fbrand%2Fmarketplaces%2Febay.png&w=256&q=75' 2>/dev/null
echo "--- fnac.png ---"
curl -s -o /dev/null -w 'HTTP %{http_code} | size: %{size_download}\n' 'https://www.keybuzz.pro/_next/image?url=%2Fbrand%2Fmarketplaces%2Ffnac.png&w=256&q=75' 2>/dev/null

echo ""
echo "=== 9. Cache headers via www.keybuzz.pro (2nd request) ==="
echo "--- icon.png 2nd ---"
curl -sI 'https://www.keybuzz.pro/_next/image?url=%2Fbrand%2Ficon.png&w=96&q=75' 2>/dev/null | grep -i "x-nextjs-cache\|content-type\|HTTP/"
echo "--- ludovic.jpg 2nd ---"
curl -sI 'https://www.keybuzz.pro/_next/image?url=%2Fimages%2Fludovic.jpg&w=640&q=75' 2>/dev/null | grep -i "x-nextjs-cache\|content-type\|HTTP/"
echo "--- darty.png 2nd ---"
curl -sI 'https://www.keybuzz.pro/_next/image?url=%2Fbrand%2Fmarketplaces%2Fdarty.png&w=256&q=75' 2>/dev/null | grep -i "x-nextjs-cache\|content-type\|HTTP/"

echo ""
echo "=== 10. Final EACCES check ==="
kubectl logs -n $NS $POD1 2>&1 | grep -i "eacces" || echo "  ZERO EACCES errors"

echo ""
echo "=== VALIDATION PROD COMPLETE ==="
