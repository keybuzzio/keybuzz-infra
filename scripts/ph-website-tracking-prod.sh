#!/bin/bash
set -e

TAG="ghcr.io/keybuzzio/keybuzz-website:v0.6.4-tracking-foundation-prod"

echo "=== PH-WEBSITE TRACKING — BUILD PROD ==="
echo "Date: $(date)"

cd /opt/keybuzz/keybuzz-website

echo "=== 1. Verify repo clean ==="
git status --short
git log -1 --format='SHA: %H | %s'

echo ""
echo "=== 2. Build PROD (--no-cache) ==="
docker build --no-cache \
  --build-arg NEXT_PUBLIC_SITE_MODE=production \
  --build-arg NEXT_PUBLIC_CLIENT_APP_URL=https://client.keybuzz.io \
  --build-arg NEXT_PUBLIC_GA_ID=G-R3QQDYEBFG \
  --build-arg NEXT_PUBLIC_META_PIXEL_ID=1234164602194748 \
  -t "$TAG" .

echo ""
echo "=== 3. Push image ==="
docker push "$TAG"

echo ""
echo "=== 4. Digest ==="
docker inspect --format='{{index .RepoDigests 0}}' "$TAG" 2>/dev/null

echo ""
echo "=== BUILD PROD DONE ==="
