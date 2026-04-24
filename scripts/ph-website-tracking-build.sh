#!/bin/bash
set -e

TAG="ghcr.io/keybuzzio/keybuzz-website:v0.6.4-tracking-foundation-dev"

echo "=== PH-WEBSITE TRACKING — COMMIT + BUILD + DEPLOY DEV ==="
echo "Date: $(date)"

cd /opt/keybuzz/keybuzz-website

echo "=== 1. Git status ==="
git status --short

echo ""
echo "=== 2. Stage + commit ==="
git add \
  src/lib/tracking.ts \
  src/components/Analytics.tsx \
  src/app/layout.tsx \
  src/app/pricing/page.tsx \
  src/app/contact/page.tsx \
  Dockerfile

git commit -m "feat: add GA4 + Meta Pixel tracking foundation

- Add Analytics component (GA4 gtag.js + Meta Pixel fbevents.js)
- Add tracking lib with typed events (view_pricing, select_plan, click_signup, contact_submit)
- GA4 consent mode v2 default (analytics granted, ads denied)
- GA4 cross-domain linker (keybuzz.pro + client.keybuzz.io)
- Meta Pixel PageView on route change
- Track CTA clicks on pricing page (select_plan + click_signup)
- Track contact form submission (contact_submit)
- Extend UTM forwarding with gclid/fbclid
- Dockerfile: add NEXT_PUBLIC_GA_ID + NEXT_PUBLIC_META_PIXEL_ID build args
- IDs via env vars, zero hardcode"

echo ""
echo "=== 3. Push ==="
git push origin main
git log -1 --format='SHA: %H'

echo ""
echo "=== 4. Build DEV (--no-cache) ==="
docker build --no-cache \
  --build-arg NEXT_PUBLIC_SITE_MODE=preview \
  --build-arg NEXT_PUBLIC_CLIENT_APP_URL=https://client-dev.keybuzz.io \
  --build-arg NEXT_PUBLIC_GA_ID=G-R3QQDYEBFG \
  --build-arg NEXT_PUBLIC_META_PIXEL_ID=1234164602194748 \
  -t "$TAG" .

echo ""
echo "=== 5. Push image ==="
docker push "$TAG"

echo ""
echo "=== 6. Digest ==="
docker inspect --format='{{index .RepoDigests 0}}' "$TAG" 2>/dev/null

echo ""
echo "=== BUILD DONE ==="
