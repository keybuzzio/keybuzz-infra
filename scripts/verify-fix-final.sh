#!/bin/bash
POD=$(kubectl get pods -n keybuzz-client-dev -l app=keybuzz-client -o jsonpath='{.items[0].metadata.name}')

# Check the inbox page chunk for status update with tenantId being passed
echo "=== Checking if currentTenantId is passed in status update call ==="
kubectl exec -n keybuzz-client-dev "$POD" -- node -e "
const fs = require('fs');
const content = fs.readFileSync('/app/.next/static/chunks/app/inbox/page-2705262b81a487e6.js', 'utf8');

// Search for status update pattern
const patterns = ['updateConversationStatus', 'updateConversationSavStatus', 'sav-status', 'handleStatusChange', 'handleSavStatus'];
for (const p of patterns) {
  const idx = content.indexOf(p);
  if (idx > -1) {
    console.log('Pattern: ' + p + ' found at index ' + idx);
    const ctx = content.substring(Math.max(0,idx-200), Math.min(content.length, idx+200));
    console.log('Context:', ctx.substring(0, 400));
    console.log('---');
  } else {
    console.log('Pattern: ' + p + ' NOT found');
  }
}
"

# Also check the shared chunk
echo ""
echo "=== Shared chunk 1173 ==="
kubectl exec -n keybuzz-client-dev "$POD" -- node -e "
const fs = require('fs');
const content = fs.readFileSync('/app/.next/static/chunks/1173-bf483c6b57f4e6e3.js', 'utf8');

// Find updateConversationStatus function
const idx1 = content.indexOf('updateConversationStatus');
if (idx1 > -1) {
  console.log('updateConversationStatus found');
  console.log(content.substring(idx1, idx1+300));
}
const idx2 = content.indexOf('updateConversationSavStatus');
if (idx2 > -1) {
  console.log('---');
  console.log('updateConversationSavStatus found');
  console.log(content.substring(idx2, idx2+300));
}
"
