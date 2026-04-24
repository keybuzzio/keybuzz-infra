#!/bin/bash
set -e

TAG="ghcr.io/keybuzzio/keybuzz-website:v0.6.1-socials-contact-prod"

echo "=== PH-WEBSITE-SOCIALS BUILD PROD ==="
echo "Tag: $TAG"
echo "Date: $(date)"

cd /opt/keybuzz/keybuzz-website

echo ""
echo "=== 1. Git state ==="
git log -1 --format='SHA: %H%nMsg: %s'

echo ""
echo "=== 2. Build PROD (--no-cache) ==="
docker build --no-cache \
  --build-arg NEXT_PUBLIC_SITE_MODE=production \
  --build-arg NEXT_PUBLIC_CLIENT_APP_URL=https://client.keybuzz.io \
  -t "$TAG" .

echo ""
echo "=== 3. Push ==="
docker push "$TAG"

echo ""
echo "=== 4. Digest ==="
docker inspect --format='{{index .RepoDigests 0}}' "$TAG" 2>/dev/null

echo ""
echo "=== BUILD PROD DONE ==="
