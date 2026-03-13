#!/bin/bash
POD=$(kubectl get pods -n keybuzz-client-dev -l app=keybuzz-client -o jsonpath='{.items[0].metadata.name}')
echo "POD=$POD"

# Find the inbox page chunk (client-side JS)
echo "=== Finding inbox page chunks ==="
CHUNKS=$(kubectl exec -n keybuzz-client-dev "$POD" -- find /app/.next/static/chunks/app/inbox -name "page-*.js" 2>/dev/null)
echo "$CHUNKS"

# Search for the status update function pattern in all chunks
echo ""
echo "=== Checking for tenantId in status update calls ==="
for chunk in $CHUNKS; do
  echo "--- $chunk ---"
  # Look for the pattern where status update is called
  kubectl exec -n keybuzz-client-dev "$POD" -- grep -c "tenantId" "$chunk" 2>/dev/null
done

# Also check the server-side rendered page
echo ""
echo "=== Server page check ==="
SERVER_PAGES=$(kubectl exec -n keybuzz-client-dev "$POD" -- find /app/.next/server/app/inbox -name "page.js" 2>/dev/null)
for sp in $SERVER_PAGES; do
  echo "--- $sp ---"
  kubectl exec -n keybuzz-client-dev "$POD" -- grep -c "tenantId" "$sp" 2>/dev/null
done

# Check all chunks for /status PATCH pattern
echo ""
echo "=== All chunks with conversations/status ==="
kubectl exec -n keybuzz-client-dev "$POD" -- grep -rl "conversations.*status" /app/.next/static/chunks/ 2>/dev/null

echo ""
echo "=== Checking 1024 chunk for status endpoint with tenantId ==="
kubectl exec -n keybuzz-client-dev "$POD" -- node -e "
const fs = require('fs');
const chunks = fs.readdirSync('/app/.next/static/chunks/');
for (const c of chunks) {
  if (!c.endsWith('.js')) continue;
  const content = fs.readFileSync('/app/.next/static/chunks/' + c, 'utf8');
  if (content.includes('/status') && content.includes('PATCH')) {
    console.log('FOUND in: ' + c);
    // Find the status update pattern
    const idx = content.indexOf('/status');
    if (idx > -1) {
      const surrounding = content.substring(Math.max(0, idx-100), idx+100);
      console.log('Context: ...', surrounding.replace(/\n/g, ' '), '...');
    }
  }
}
"
