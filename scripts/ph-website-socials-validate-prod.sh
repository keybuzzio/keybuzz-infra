#!/bin/bash
set -e

echo "=== PH-WEBSITE-SOCIALS VALIDATION PROD ==="
echo "Date: $(date)"

NS="keybuzz-website-prod"
POD=$(kubectl get pods -n $NS -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | awk '{print $1}')
echo "Pod: $POD"

echo ""
echo "=== 1. Logs ==="
kubectl logs -n $NS $POD --tail=5

echo ""
echo "=== 2. EACCES ==="
kubectl logs -n $NS $POD 2>&1 | grep -i "eacces" || echo "  ZERO EACCES"

echo ""
echo "=== 3. Footer links via pod ==="
kubectl exec -n $NS $POD -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/', (res) => {
  let body = '';
  res.on('data', (c) => { body += c; });
  res.on('end', () => {
    ['instagram.com/ludo_keybuzz','youtube.com/@KeyBuzzConsulting','tiktok.com/@ludo_keybuzz','linkedin.com/in/ludovic-keybuzz','facebook.com/profile.php'].forEach(s => {
      console.log((body.includes(s) ? 'OK' : 'MISSING') + ' — ' + s);
    });
    console.log(body.includes('keybuzz_consulting') ? 'FAIL — old insta' : 'OK — old insta removed');
  });
});
" 2>/dev/null

echo ""
echo "=== 4. Contact via pod ==="
kubectl exec -n $NS $POD -- node -e "
const http = require('http');
http.get('http://127.0.0.1:3000/contact', (res) => {
  let body = '';
  res.on('data', (c) => { body += c; });
  res.on('end', () => {
    console.log('HTTP ' + res.statusCode);
    console.log(body.includes('tel:+33783348999') ? 'FAIL — phone present' : 'OK — phone removed');
    console.log(body.includes('linkedin.com/in/ludovic-keybuzz') ? 'OK — new LinkedIn' : 'MISSING — new LinkedIn');
    console.log(body.includes('linkedin.com/company/keybuzz') ? 'FAIL — old LinkedIn' : 'OK — old LinkedIn gone');
  });
});
" 2>/dev/null

echo ""
echo "=== 5. Via www.keybuzz.pro ==="
echo "--- Homepage ---"
curl -s 'https://www.keybuzz.pro/' -o /tmp/prod-homepage.html -w 'HTTP %{http_code} | %{size_download} bytes\n'

echo "--- Footer links ---"
for LINK in \
  "instagram.com/ludo_keybuzz" \
  "youtube.com/@KeyBuzzConsulting" \
  "tiktok.com/@ludo_keybuzz" \
  "linkedin.com/in/ludovic-keybuzz" \
  "facebook.com/profile.php"
do
  if grep -q "$LINK" /tmp/prod-homepage.html 2>/dev/null; then
    echo "  OK — $LINK"
  else
    echo "  MISSING — $LINK"
  fi
done

echo ""
echo "--- Contact ---"
curl -s 'https://www.keybuzz.pro/contact' -o /tmp/prod-contact.html -w 'HTTP %{http_code} | %{size_download} bytes\n'
grep -c 'tel:+33783348999' /tmp/prod-contact.html > /dev/null 2>&1 && echo "  FAIL — phone" || echo "  OK — no phone"
grep -q 'linkedin.com/in/ludovic-keybuzz' /tmp/prod-contact.html && echo "  OK — new LinkedIn" || echo "  MISSING — LinkedIn"

echo ""
echo "=== VALIDATION PROD COMPLETE ==="
