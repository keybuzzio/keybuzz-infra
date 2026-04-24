#!/bin/bash
set -e

cd /opt/keybuzz/keybuzz-website

echo "=== 1. CTA buttons rendering in pricing ==="
grep -A5 'href={plan.ctaLink' src/app/pricing/page.tsx

echo ""
echo "=== 2. Stripe URLs anywhere in codebase ==="
grep -rni 'stripe\.com\|buy\.stripe\|checkout\.stripe\|payment_link\|plink_' src/ --include='*.ts' --include='*.tsx' || echo "(no Stripe URLs found)"

echo ""
echo "=== 3. All external https URLs ==="
grep -roh 'https://[^"]*' src/ --include='*.ts' --include='*.tsx' | sort -u | head -30

echo ""
echo "=== 4. Register/signup flow references ==="
grep -rni 'register\|signup\|sign-up' src/ --include='*.ts' --include='*.tsx' | head -15

echo ""
echo "=== 5. CLIENT_APP_URL usage ==="
grep -rni 'CLIENT_APP_URL\|client\.keybuzz\|client-dev\.keybuzz' src/ --include='*.ts' --include='*.tsx'

echo ""
echo "=== 6. Full pricing plans data structure ==="
sed -n '/^const plans/,/^];/p' src/app/pricing/page.tsx

echo ""
echo "=== DONE ==="
