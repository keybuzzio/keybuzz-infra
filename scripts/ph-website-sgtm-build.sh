#!/bin/bash
set -e

TAG="ghcr.io/keybuzzio/keybuzz-website:v0.6.5-sgtm-addingwell-dev"

echo "=== PH-T5.4 — WEBSITE sGTM BUILD DEV ==="
echo "Date: $(date)"

cd /opt/keybuzz/keybuzz-website

echo "=== 1. Git status ==="
git status --short

echo ""
echo "=== 2. Stage + commit ==="
git add src/components/Analytics.tsx Dockerfile
git commit -m "PH-T5.4: add sGTM server_container_url for Addingwell

- Analytics.tsx: conditional gtag.js source (sGTM or direct)
- Analytics.tsx: server_container_url in gtag config when SGTM_URL set
- Dockerfile: add NEXT_PUBLIC_SGTM_URL ARG+ENV
- Fallback: if NEXT_PUBLIC_SGTM_URL absent, direct googletagmanager.com
- Meta Pixel: unchanged (browser-side only)"

echo ""
echo "=== 3. Push ==="
git push origin main
git log -1 --format='SHA: %H | %s'

echo ""
echo "=== 4. Build DEV (--no-cache) ==="
docker build --no-cache \
  --build-arg NEXT_PUBLIC_SITE_MODE=preview \
  --build-arg NEXT_PUBLIC_CLIENT_APP_URL=https://client-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_GA_ID=G-R3QQDYEBFG \
  --build-arg NEXT_PUBLIC_META_PIXEL_ID=1234164602194748 \
  --build-arg NEXT_PUBLIC_SGTM_URL=https://t.keybuzz.pro \
  -t "$TAG" .

echo ""
echo "=== 5. Push image ==="
docker push "$TAG"

echo ""
echo "=== 6. Digest ==="
docker inspect --format='{{index .RepoDigests 0}}' "$TAG" 2>/dev/null

echo ""
echo "=== BUILD DONE ==="
