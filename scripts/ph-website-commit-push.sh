#!/bin/bash
set -e

cd /opt/keybuzz/keybuzz-website

echo "=== PRE-COMMIT STATUS ==="
git status

echo ""
echo "=== COMMITTING Dockerfile only ==="
git commit -m "fix: grant nextjs user write access to .next/cache for image optimization

- Add mkdir + chown for /app/.next/cache before USER nextjs
- Include NEXT_PUBLIC_CLIENT_APP_URL build-arg (pending from previous work)
- Fixes EACCES permission denied on image cache writes
- Resolves broken images: header logo, marketplace logos, founder photo"

echo ""
echo "=== POST-COMMIT STATUS ==="
git status

echo ""
echo "=== PUSHING to origin/main ==="
git push origin main

echo ""
echo "=== COMMIT SHA ==="
git log -1 --format='%H %s'

echo ""
echo "=== DONE ==="
