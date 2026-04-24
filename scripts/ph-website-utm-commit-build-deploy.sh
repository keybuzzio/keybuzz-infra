#!/bin/bash
set -e

TAG="ghcr.io/keybuzzio/keybuzz-website:v0.6.2-utm-forwarding-dev"

echo "=== PH-WEBSITE UTM — COMMIT + BUILD + DEPLOY DEV ==="
echo "Date: $(date)"

# --- COMMIT ---
cd /opt/keybuzz/keybuzz-website
echo "=== 1. Stage pricing only ==="
git add src/app/pricing/page.tsx
git status

echo ""
echo "=== 2. Commit ==="
git commit -m "feat: forward UTM params from pricing page to registration links

- Read utm_source/medium/campaign/term/content from URL query string
- Append UTM params to all plan CTA links (Starter/Pro/Autopilot)
- Enterprise link (/contact) unaffected
- Align pricing ctaLink with CLIENT_APP_URL + cycle param"

echo ""
echo "=== 3. Push ==="
git push origin main
git log -1 --format='SHA: %H'

# --- BUILD ---
echo ""
echo "=== 4. Build DEV (--no-cache) ==="
docker build --no-cache \
  --build-arg NEXT_PUBLIC_SITE_MODE=preview \
  --build-arg NEXT_PUBLIC_CLIENT_APP_URL=https://client-dev.keybuzz.io \
  -t "$TAG" .

echo ""
echo "=== 5. Push image ==="
docker push "$TAG"

echo ""
echo "=== 6. Digest ==="
docker inspect --format='{{index .RepoDigests 0}}' "$TAG" 2>/dev/null

echo ""
echo "=== COMMIT + BUILD DONE ==="
