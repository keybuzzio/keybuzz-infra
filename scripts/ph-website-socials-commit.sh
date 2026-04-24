#!/bin/bash
set -e

cd /opt/keybuzz/keybuzz-website

echo "=== PRE-COMMIT STATUS ==="
git status

echo ""
echo "=== STAGING Footer + Contact only ==="
git add src/components/Footer.tsx src/app/contact/page.tsx

echo ""
echo "=== STAGED FILES ==="
git diff --cached --stat

echo ""
echo "=== COMMITTING ==="
git commit -m "feat: update social links in footer + remove phone from contact

Footer:
- Update Instagram URL to @ludo_keybuzz
- Add YouTube (@KeyBuzzConsulting)
- Add TikTok (@ludo_keybuzz)
- Add LinkedIn (ludovic-keybuzz)
- Add Facebook (real URL replacing placeholder)

Contact:
- Remove phone number block
- Update LinkedIn URL to personal profile"

echo ""
echo "=== PUSHING ==="
git push origin main

echo ""
echo "=== COMMIT SHA ==="
git log -1 --format='%H %s'

echo ""
echo "=== POST-COMMIT STATUS ==="
git status

echo "=== DONE ==="
