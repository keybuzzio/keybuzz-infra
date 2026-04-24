#!/bin/bash
set -e

POD=$(kubectl get pods -n keybuzz-website-dev -o name --field-selector=status.phase=Running | head -1)
echo "Pod: $POD"

echo "=== Searching JS bundles for utm_source ==="
kubectl exec -n keybuzz-website-dev "$POD" -- find /app/.next/static -name '*.js' -exec grep -l 'utm_source' {} + 2>/dev/null || echo "Not found in static chunks"

echo ""
echo "=== Searching in standalone server chunks ==="
kubectl exec -n keybuzz-website-dev "$POD" -- find /app/.next -name '*.js' -exec grep -l 'utm_source' {} + 2>/dev/null || echo "Not found in .next"

echo ""
echo "=== Verify pricing source file ==="
kubectl exec -n keybuzz-website-dev "$POD" -- grep -c 'utm_source' /app/server.js 2>/dev/null || echo "Not in server.js"

echo ""
echo "=== Check if pricing chunk has utmSuffix ==="
kubectl exec -n keybuzz-website-dev "$POD" -- sh -c "find /app/.next -name '*.js' -exec grep -l 'utmSuffix' {} + 2>/dev/null" || echo "utmSuffix not found"
