#!/bin/bash
set -e

TAG="ghcr.io/keybuzzio/keybuzz-website:v0.6.0-fix-image-cache-dev"

echo "=== PH-WEBSITE BUILD DEV ==="
echo "Tag: $TAG"
echo "Date: $(date)"

cd /opt/keybuzz/keybuzz-website

echo ""
echo "=== 1. Verify git state ==="
git log -1 --format='SHA: %H%nMsg: %s'
echo ""

echo "=== 2. Building image (--no-cache) ==="
docker build --no-cache \
  --build-arg NEXT_PUBLIC_SITE_MODE=preview \
  --build-arg NEXT_PUBLIC_CLIENT_APP_URL=https://client-dev.keybuzz.io \
  -t "$TAG" .

echo ""
echo "=== 3. Pushing image ==="
docker push "$TAG"

echo ""
echo "=== 4. Image digest ==="
docker inspect --format='{{index .RepoDigests 0}}' "$TAG" 2>/dev/null || docker images --digests --format '{{.Repository}}:{{.Tag}} {{.Digest}}' | grep "v0.6.0-fix-image-cache-dev"

echo ""
echo "=== BUILD + PUSH COMPLETE ==="
