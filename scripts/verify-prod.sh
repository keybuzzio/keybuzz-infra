#!/bin/bash
POD=$(kubectl get pods -n keybuzz-client-prod -l app=keybuzz-client -o jsonpath='{.items[0].metadata.name}')
echo "PROD POD=$POD"

# Find inbox page chunk
CHUNK=$(kubectl exec -n keybuzz-client-prod "$POD" -- find /app/.next/static/chunks/app/inbox -name "page-*.js" -not -path "*conversationId*" 2>/dev/null)
echo "Inbox chunk: $CHUNK"

# Verify fix in compiled code
kubectl exec -n keybuzz-client-prod "$POD" -- node -e "
const fs = require('fs');
const files = fs.readdirSync('/app/.next/static/chunks/');
for (const f of files) {
  if (!f.endsWith('.js')) continue;
  const c = fs.readFileSync('/app/.next/static/chunks/' + f, 'utf8');
  if (c.includes('PATCH') && c.includes('conversationStatus')) {
    console.log('FOUND in: ' + f);
    const idx = c.indexOf('conversationStatus');
    console.log('URL pattern:', c.substring(idx, idx+200));
  }
}
"

echo ""
echo "=== Verify call site passes tenantId ==="
kubectl exec -n keybuzz-client-prod "$POD" -- node -e "
const fs = require('fs');
const chunk = '$CHUNK';
const c = fs.readFileSync(chunk, 'utf8');
let idx = 0;
while ((idx = c.indexOf('await B(', idx)) !== -1) {
  const ctx = c.substring(idx, Math.min(c.length, idx+150));
  if (ctx.includes('.id,')) { console.log('Status call:', ctx.substring(0, 150)); }
  idx += 8;
}
idx = 0;
while ((idx = c.indexOf('await V(', idx)) !== -1) {
  const ctx = c.substring(idx, Math.min(c.length, idx+150));
  if (ctx.includes('.id,')) { console.log('SAV call:', ctx.substring(0, 150)); }
  idx += 8;
}
"
