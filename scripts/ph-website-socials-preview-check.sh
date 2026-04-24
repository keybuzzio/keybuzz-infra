#!/bin/bash
set -e

echo "=== PREVIEW CHECK via curl -k ==="

curl -sk -u preview:Kb2026Preview! 'https://preview.keybuzz.pro/' -o /tmp/preview-homepage.html -w 'Homepage: HTTP %{http_code} | %{size_download} bytes\n'

echo ""
echo "--- Footer social links found ---"
grep -oE 'href="https://(www\.)?(instagram|youtube|tiktok|linkedin|facebook)[^"]+' /tmp/preview-homepage.html | sort -u || echo "(none found)"

echo ""
echo "--- Contact page ---"
curl -sk -u preview:Kb2026Preview! 'https://preview.keybuzz.pro/contact' -o /tmp/preview-contact.html -w 'Contact: HTTP %{http_code} | %{size_download} bytes\n'

echo ""
echo "Phone on /contact:"
grep -c 'tel:+33783348999' /tmp/preview-contact.html && echo "FAIL — phone present" || echo "OK — no phone"

echo ""
echo "LinkedIn on /contact:"
grep -oE 'href="https://www.linkedin.com/[^"]+' /tmp/preview-contact.html || echo "NOT FOUND"

echo ""
echo "=== DONE ==="
