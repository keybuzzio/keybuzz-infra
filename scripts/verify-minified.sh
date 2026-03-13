#!/bin/bash
POD=$(kubectl get pods -n keybuzz-client-dev -l app=keybuzz-client -o jsonpath='{.items[0].metadata.name}')

# Search for PATCH + status in the inbox page chunk
echo "=== Search PATCH + status in inbox page ==="
kubectl exec -n keybuzz-client-dev "$POD" -- node -e "
const fs = require('fs');
const content = fs.readFileSync('/app/.next/static/chunks/app/inbox/page-2705262b81a487e6.js', 'utf8');

// Find all PATCH occurrences
let idx = 0;
let count = 0;
while ((idx = content.indexOf('PATCH', idx)) !== -1) {
  count++;
  const ctx = content.substring(Math.max(0,idx-300), Math.min(content.length, idx+100));
  console.log('=== PATCH #' + count + ' at pos ' + idx + ' ===');
  console.log(ctx);
  console.log('');
  idx += 5;
  if (count > 10) break;
}
console.log('Total PATCH occurrences:', count);
"
