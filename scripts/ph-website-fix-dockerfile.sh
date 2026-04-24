#!/bin/bash
set -e

echo "=== PH-WEBSITE-FIX — Dockerfile cache permissions ==="
echo "Date: $(date)"

cd /opt/keybuzz/keybuzz-website

echo ""
echo "=== 1. BEFORE — Lines around USER nextjs ==="
grep -n "USER\|COPY\|chown\|mkdir\|cache" Dockerfile || true

echo ""
echo "=== 2. Applying fix — insert mkdir+chown before USER nextjs ==="
sed -i '/^USER nextjs$/i \# Fix: grant nextjs write access to image optimization cache\nRUN mkdir -p /app/.next/cache \&\& chown -R nextjs:nodejs /app/.next/cache\n' Dockerfile

echo ""
echo "=== 3. AFTER — Full Stage 3 section ==="
sed -n '/^# Stage 3/,/^CMD/p' Dockerfile

echo ""
echo "=== 4. Full diff vs committed ==="
git diff Dockerfile

echo ""
echo "=== FIX APPLIED ==="
