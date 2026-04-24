#!/bin/bash
set -e

TAG_DEV="ghcr.io/keybuzzio/keybuzz-website:v0.6.3-error-boundaries-dev"
TAG_PROD="ghcr.io/keybuzzio/keybuzz-website:v0.6.3-error-boundaries-prod"

echo "=== PH-WEBSITE ERROR FIX — COMMIT + BUILD + DEPLOY ==="
echo "Date: $(date)"

cd /opt/keybuzz/keybuzz-website

echo "=== 1. Git status ==="
git status --short

echo ""
echo "=== 2. Git diff summary ==="
git diff --stat

echo ""
echo "=== 3. Stage + commit ==="
git add \
  src/app/global-error.tsx \
  src/app/error.tsx \
  src/components/CookieConsent.tsx \
  src/components/IntroSplash.tsx \
  src/app/pricing/page.tsx

git commit -m "fix: add error boundaries + protect storage access + UTM try-catch

- Add global-error.tsx: root-level error boundary with reload button
- Add error.tsx: route-level error boundary with retry/reload
- CookieConsent: wrap localStorage in try-catch (private browsing safe)
- IntroSplash: wrap sessionStorage in try-catch (private browsing safe)
- Pricing UTM: wrap useEffect in try-catch (safe fallback)"

echo ""
echo "=== 4. Push ==="
git push origin main
git log -1 --format='SHA: %H'

echo ""
echo "=== 5. Build DEV ==="
docker build --no-cache \
  --build-arg NEXT_PUBLIC_SITE_MODE=preview \
  --build-arg NEXT_PUBLIC_CLIENT_APP_URL=https://client-dev.keybuzz.io \
  -t "$TAG_DEV" .

echo ""
echo "=== 6. Build PROD ==="
docker build --no-cache \
  --build-arg NEXT_PUBLIC_SITE_MODE=production \
  --build-arg NEXT_PUBLIC_CLIENT_APP_URL=https://client.keybuzz.io \
  -t "$TAG_PROD" .

echo ""
echo "=== 7. Push both images ==="
docker push "$TAG_DEV"
docker push "$TAG_PROD"

echo ""
echo "=== 8. Digests ==="
echo "DEV:"
docker inspect --format='{{index .RepoDigests 0}}' "$TAG_DEV" 2>/dev/null
echo "PROD:"
docker inspect --format='{{index .RepoDigests 0}}' "$TAG_PROD" 2>/dev/null

echo ""
echo "=== BUILD DONE ==="
