#!/bin/bash
set -e

echo "=== PH-WEBSITE-SOCIALS VALIDATION DEV ==="
echo "Date: $(date)"

NS="keybuzz-website-dev"
POD=$(kubectl get pods -n $NS -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | awk '{print $1}')
echo "Pod: $POD"

echo ""
echo "=== 1. Logs ==="
kubectl logs -n $NS $POD --tail=5

echo ""
echo "=== 2. EACCES check ==="
kubectl logs -n $NS $POD 2>&1 | grep -i "eacces" || echo "  ZERO EACCES"

echo ""
echo "=== 3. Homepage HTML — Footer social links ==="
kubectl exec -n $NS $POD -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', (res) => {
  let body = '';
  res.on('data', (chunk) => { body += chunk; });
  res.on('end', () => {
    const socials = [
      'instagram.com/ludo_keybuzz',
      'youtube.com/@KeyBuzzConsulting',
      'tiktok.com/@ludo_keybuzz',
      'linkedin.com/in/ludovic-keybuzz',
      'facebook.com/profile.php'
    ];
    socials.forEach(s => {
      const found = body.includes(s);
      console.log((found ? 'OK' : 'MISSING') + ' — ' + s);
    });
    const oldInsta = body.includes('keybuzz_consulting');
    console.log(oldInsta ? 'FAIL — old Instagram still present' : 'OK — old Instagram removed');
    const phone = body.includes('+33 7 83 34 89 99') || body.includes('tel:+33783348999');
    console.log(phone ? 'FAIL — phone still in homepage' : 'OK — phone not in homepage');
  });
});
" 2>/dev/null

echo ""
echo "=== 4. Contact page — check content ==="
kubectl exec -n $NS $POD -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/contact', (res) => {
  let body = '';
  res.on('data', (chunk) => { body += chunk; });
  res.on('end', () => {
    console.log('HTTP ' + res.statusCode);
    const hasPhone = body.includes('+33 7 83 34 89 99') || body.includes('tel:+33783348999');
    console.log(hasPhone ? 'FAIL — phone still present on /contact' : 'OK — phone removed from /contact');
    const hasOldLinkedin = body.includes('linkedin.com/company/keybuzz');
    console.log(hasOldLinkedin ? 'FAIL — old LinkedIn URL still present' : 'OK — old LinkedIn removed');
    const hasNewLinkedin = body.includes('linkedin.com/in/ludovic-keybuzz');
    console.log(hasNewLinkedin ? 'OK — new LinkedIn present' : 'MISSING — new LinkedIn not found');
  });
});
" 2>/dev/null

echo ""
echo "=== 5. Test via preview.keybuzz.pro ==="
echo "--- Homepage ---"
curl -s -u preview:Kb2026Preview! 'https://preview.keybuzz.pro/' -o /tmp/preview-homepage.html -w 'HTTP %{http_code} | %{size_download} bytes\n'

echo "--- Footer social links in HTML ---"
for LINK in \
  "instagram.com/ludo_keybuzz" \
  "youtube.com/@KeyBuzzConsulting" \
  "tiktok.com/@ludo_keybuzz" \
  "linkedin.com/in/ludovic-keybuzz" \
  "facebook.com/profile.php"
do
  if grep -q "$LINK" /tmp/preview-homepage.html 2>/dev/null; then
    echo "  OK — $LINK"
  else
    echo "  MISSING — $LINK"
  fi
done

echo ""
echo "--- Contact page ---"
curl -s -u preview:Kb2026Preview! 'https://preview.keybuzz.pro/contact' -o /tmp/preview-contact.html -w 'HTTP %{http_code} | %{size_download} bytes\n'

if grep -q "tel:+33783348999" /tmp/preview-contact.html 2>/dev/null; then
  echo "  FAIL — phone still on /contact"
else
  echo "  OK — phone removed from /contact"
fi

if grep -q "linkedin.com/in/ludovic-keybuzz" /tmp/preview-contact.html 2>/dev/null; then
  echo "  OK — new LinkedIn on /contact"
else
  echo "  MISSING — new LinkedIn not on /contact"
fi

echo ""
echo "=== VALIDATION DEV COMPLETE ==="
