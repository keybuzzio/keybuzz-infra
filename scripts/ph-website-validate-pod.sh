#!/bin/bash
set -e

echo "=== PH-WEBSITE VALIDATION DEV (via pod direct) ==="
echo "Date: $(date)"

POD="keybuzz-website-7887b997c8-lzcd5"
NS="keybuzz-website-dev"
SVC_IP=$(kubectl get svc keybuzz-website -n $NS -o jsonpath='{.spec.clusterIP}')
echo "Service ClusterIP: $SVC_IP"

echo ""
echo "=== 1. Trigger image requests via Service ClusterIP ==="

for IMG in \
  "icon.png|/_next/image?url=%2Fbrand%2Ficon.png&w=96&q=75" \
  "ludovic.jpg|/_next/image?url=%2Fimages%2Fludovic.jpg&w=640&q=75" \
  "darty.png|/_next/image?url=%2Fbrand%2Fmarketplaces%2Fdarty.png&w=256&q=75" \
  "cdiscount.jpg|/_next/image?url=%2Fbrand%2Fmarketplaces%2Fcdiscount.jpg&w=256&q=75" \
  "ebay.png|/_next/image?url=%2Fbrand%2Fmarketplaces%2Febay.png&w=256&q=75" \
  "fnac.png|/_next/image?url=%2Fbrand%2Fmarketplaces%2Ffnac.png&w=256&q=75"
do
  NAME=$(echo "$IMG" | cut -d'|' -f1)
  URL=$(echo "$IMG" | cut -d'|' -f2)
  STATUS=$(curl -s -o /dev/null -w '%{http_code}' "http://$SVC_IP:80/$URL" 2>/dev/null || echo "ERR")
  SIZE=$(curl -s -o /dev/null -w '%{size_download}' "http://$SVC_IP:80/$URL" 2>/dev/null || echo "0")
  echo "  $NAME: HTTP $STATUS | $SIZE bytes"
done

echo ""
echo "=== 2. Check cache directory populated ==="
kubectl exec -n $NS $POD -- ls -laR /app/.next/cache/ 2>&1 | head -40

echo ""
echo "=== 3. Second request — check cache HIT header ==="
for IMG in \
  "icon.png|/_next/image?url=%2Fbrand%2Ficon.png&w=96&q=75" \
  "darty.png|/_next/image?url=%2Fbrand%2Fmarketplaces%2Fdarty.png&w=256&q=75" \
  "ludovic.jpg|/_next/image?url=%2Fimages%2Fludovic.jpg&w=640&q=75"
do
  NAME=$(echo "$IMG" | cut -d'|' -f1)
  URL=$(echo "$IMG" | cut -d'|' -f2)
  CACHE=$(curl -sI "http://$SVC_IP:80/$URL" 2>/dev/null | grep -i "x-nextjs-cache" || echo "  (no cache header)")
  echo "  $NAME: $CACHE"
done

echo ""
echo "=== 4. Pod logs — any EACCES? ==="
kubectl logs -n $NS $POD --tail=20 2>&1

echo ""
echo "=== VALIDATION COMPLETE ==="
