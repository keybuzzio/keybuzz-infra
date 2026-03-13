#!/bin/bash
POD=$(kubectl get pods -n keybuzz-client-dev -l app=keybuzz-client -o jsonpath='{.items[0].metadata.name}')

# Find where B() and V() (the minified updateConversationStatus and updateConversationSavStatus) are called
kubectl exec -n keybuzz-client-dev "$POD" -- node -e "
const fs = require('fs');
const content = fs.readFileSync('/app/.next/static/chunks/app/inbox/page-2705262b81a487e6.js', 'utf8');

// Function B is updateConversationStatus, V is updateConversationSavStatus
// Let's find calls like: await B(something.id, newStatus, currentTenantId)
// Pattern: B(xxx.id, then check if 3 args
let idx = 0;
while ((idx = content.indexOf('await B(', idx)) !== -1) {
  const ctx = content.substring(idx, Math.min(content.length, idx+200));
  // Only show if it looks like a status update call
  if (ctx.includes('.id,')) {
    console.log('=== Call to B (updateConversationStatus) ===');
    console.log(ctx.substring(0, 200));
    console.log('');
  }
  idx += 8;
}

idx = 0;
while ((idx = content.indexOf('await V(', idx)) !== -1) {
  const ctx = content.substring(idx, Math.min(content.length, idx+200));
  if (ctx.includes('.id,')) {
    console.log('=== Call to V (updateConversationSavStatus) ===');
    console.log(ctx.substring(0, 200));
    console.log('');
  }
  idx += 8;
}
"
