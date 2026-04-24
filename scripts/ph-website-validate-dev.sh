#!/bin/bash
set -e

echo "=== PH-WEBSITE VALIDATION DEV ==="
echo "Date: $(date)"

POD="keybuzz-website-7887b997c8-lzcd5"
NS="keybuzz-website-dev"

echo ""
echo "=== 1. Trigger image requests via preview.keybuzz.pro ==="
echo "--- icon.png (header logo) ---"
curl -s -o /dev/null -w 'HTTP %{http_code} | size: %{size_download} | type: %{content_type}\n' 'https://preview.keybuzz.pro/_next/image?url=%2Fbrand%2Ficon.png&w=96&q=75' -u keybuzz:keybuzz2026
echo "--- ludovic.jpg (founder photo) ---"
curl -s -o /dev/null -w 'HTTP %{http_code} | size: %{size_download} | type: %{content_type}\n' 'https://preview.keybuzz.pro/_next/image?url=%2Fimages%2Fludovic.jpg&w=640&q=75' -u keybuzz:keybuzz2026
echo "--- darty.png ---"
curl -s -o /dev/null -w 'HTTP %{http_code} | size: %{size_download} | type: %{content_type}\n' 'https://preview.keybuzz.pro/_next/image?url=%2Fbrand%2Fmarketplaces%2Fdarty.png&w=256&q=75' -u keybuzz:keybuzz2026
echo "--- cdiscount.jpg ---"
curl -s -o /dev/null -w 'HTTP %{http_code} | size: %{size_download} | type: %{content_type}\n' 'https://preview.keybuzz.pro/_next/image?url=%2Fbrand%2Fmarketplaces%2Fcdiscount.jpg&w=256&q=75' -u keybuzz:keybuzz2026
echo "--- ebay.png ---"
curl -s -o /dev/null -w 'HTTP %{http_code} | size: %{size_download} | type: %{content_type}\n' 'https://preview.keybuzz.pro/_next/image?url=%2Fbrand%2Fmarketplaces%2Febay.png&w=256&q=75' -u keybuzz:keybuzz2026
echo "--- fnac.png ---"
curl -s -o /dev/null -w 'HTTP %{http_code} | size: %{size_download} | type: %{content_type}\n' 'https://preview.keybuzz.pro/_next/image?url=%2Fbrand%2Fmarketplaces%2Ffnac.png&w=256&q=75' -u keybuzz:keybuzz2026

echo ""
echo "=== 2. Check cache populated ==="
kubectl exec -n $NS $POD -- ls -laR /app/.next/cache/ 2>&1 | head -30

echo ""
echo "=== 3. Second request — check x-nextjs-cache header ==="
echo "--- icon.png (2nd request) ---"
curl -sI 'https://preview.keybuzz.pro/_next/image?url=%2Fbrand%2Ficon.png&w=96&q=75' -u keybuzz:keybuzz2026 2>&1 | grep -i "http/\|x-nextjs-cache\|content-type"
echo "--- ludovic.jpg (2nd request) ---"
curl -sI 'https://preview.keybuzz.pro/_next/image?url=%2Fimages%2Fludovic.jpg&w=640&q=75' -u keybuzz:keybuzz2026 2>&1 | grep -i "http/\|x-nextjs-cache\|content-type"
echo "--- darty.png (2nd request) ---"
curl -sI 'https://preview.keybuzz.pro/_next/image?url=%2Fbrand%2Fmarketplaces%2Fdarty.png&w=256&q=75' -u keybuzz:keybuzz2026 2>&1 | grep -i "http/\|x-nextjs-cache\|content-type"

echo ""
echo "=== 4. Pod logs after requests (check for EACCES) ==="
kubectl logs -n $NS $POD --tail=20 2>&1

echo ""
echo "=== VALIDATION COMPLETE ==="
