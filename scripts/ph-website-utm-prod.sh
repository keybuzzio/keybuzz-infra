#!/bin/bash
set -e

TAG_PROD="ghcr.io/keybuzzio/keybuzz-website:v0.6.2-utm-forwarding-prod"

echo "=== PH-WEBSITE UTM — PROMOTION PROD ==="
echo "Date: $(date)"

cd /opt/keybuzz/keybuzz-website

echo "=== 1. Verify branch + SHA ==="
git branch --show-current
git log -1 --format='SHA: %H%nMsg: %s'

echo ""
echo "=== 2. Build PROD (--no-cache) ==="
docker build --no-cache \
  --build-arg NEXT_PUBLIC_SITE_MODE=production \
  --build-arg NEXT_PUBLIC_CLIENT_APP_URL=https://client.keybuzz.io \
  -t "$TAG_PROD" .

echo ""
echo "=== 3. Push image PROD ==="
docker push "$TAG_PROD"

echo ""
echo "=== 4. Digest ==="
docker inspect --format='{{index .RepoDigests 0}}' "$TAG_PROD" 2>/dev/null

echo ""
echo "=== BUILD PROD DONE ==="
