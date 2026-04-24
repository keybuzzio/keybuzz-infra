#!/bin/bash
set -e

TAG="ghcr.io/keybuzzio/keybuzz-website:v0.6.2-utm-forwarding-dev"

echo "=== PH-WEBSITE UTM — FIX + REBUILD ==="
echo "Date: $(date)"

cd /opt/keybuzz/keybuzz-website

echo "=== 1. Amend commit with TS fix ==="
git add src/app/pricing/page.tsx
git commit --amend --no-edit
git push origin main --force-with-lease

echo ""
echo "=== 2. Verify SHA ==="
git log -1 --format='SHA: %H%nMsg: %s'

echo ""
echo "=== 3. Rebuild (--no-cache) ==="
docker build --no-cache \
  --build-arg NEXT_PUBLIC_SITE_MODE=preview \
  --build-arg NEXT_PUBLIC_CLIENT_APP_URL=https://client-dev.keybuzz.io \
  -t "$TAG" .

echo ""
echo "=== 4. Push image ==="
docker push "$TAG"

echo ""
echo "=== 5. Digest ==="
docker inspect --format='{{index .RepoDigests 0}}' "$TAG" 2>/dev/null

echo ""
echo "=== FIX + REBUILD DONE ==="
