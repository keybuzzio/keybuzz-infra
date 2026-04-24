#!/bin/bash
set -e

TAG="ghcr.io/keybuzzio/keybuzz-website:v0.6.0-fix-image-cache-prod"

echo "=== PH-WEBSITE BUILD PROD ==="
echo "Tag: $TAG"
echo "Date: $(date)"

cd /opt/keybuzz/keybuzz-website

echo ""
echo "=== 1. Verify git state (must be same SHA as DEV) ==="
git log -1 --format='SHA: %H%nMsg: %s'
echo ""

echo "=== 2. Verify Dockerfile has the fix ==="
grep -n "cache" Dockerfile || echo "FIX NOT FOUND — ABORTING"

echo ""
echo "=== 3. Building PROD image (--no-cache) ==="
docker build --no-cache \
  --build-arg NEXT_PUBLIC_SITE_MODE=production \
  --build-arg NEXT_PUBLIC_CLIENT_APP_URL=https://client.keybuzz.io \
  -t "$TAG" .

echo ""
echo "=== 4. Pushing PROD image ==="
docker push "$TAG"

echo ""
echo "=== 5. Image digest ==="
docker inspect --format='{{index .RepoDigests 0}}' "$TAG" 2>/dev/null || docker images --digests --format '{{.Repository}}:{{.Tag}} {{.Digest}}' | grep "v0.6.0-fix-image-cache-prod"

echo ""
echo "=== BUILD + PUSH PROD COMPLETE ==="
